import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tvmaze_discovery/core/load_status.dart';
import 'package:tvmaze_discovery/data/models.dart';
import 'package:tvmaze_discovery/features/search/search_bloc.dart';
import 'fakes.dart';

void main() {
  late FakeShowRepository repository;
  setUp(() => repository = FakeShowRepository());
  blocTest<SearchBloc, SearchState>(
    'rapid typing performs one debounced request',
    build: () =>
        SearchBloc(repository, debounce: const Duration(milliseconds: 30)),
    act: (bloc) => bloc
      ..add(SearchQueryChanged('d'))
      ..add(SearchQueryChanged('da'))
      ..add(SearchQueryChanged('dark')),
    wait: const Duration(milliseconds: 100),
    verify: (bloc) {
      expect(repository.searches, ['dark']);
      expect(bloc.state.status, LoadStatus.success);
    },
  );
  test('late response cannot replace newer search results', () async {
    final old = Completer<List<Show>>();
    repository.onSearch = (query) =>
        query == 'old' ? old.future : Future.value([otherShow]);
    final bloc = SearchBloc(repository, debounce: Duration.zero);
    addTearDown(bloc.close);
    bloc.add(SearchQueryChanged('old'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final ready = bloc.stream.firstWhere(
      (s) => s.status == LoadStatus.success && s.query == 'new',
    );
    bloc.add(SearchQueryChanged('new'));
    await ready.timeout(const Duration(seconds: 2));
    old.complete([sampleShow]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.query, 'new');
    expect(bloc.state.shows.single.id, 2);
  });
  test('clear immediately invalidates an in-flight request', () async {
    final pending = Completer<List<Show>>();
    repository.onSearch = (_) => pending.future;
    final bloc = SearchBloc(repository, debounce: Duration.zero);
    addTearDown(bloc.close);
    bloc.add(SearchQueryChanged('old'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final cleared = bloc.stream.firstWhere(
      (s) => s.status == LoadStatus.initial,
    );
    bloc.add(SearchQueryChanged('  '));
    await cleared.timeout(const Duration(seconds: 2));
    pending.complete([sampleShow]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.shows, isEmpty);
    expect(bloc.state.query, isEmpty);
  });
  blocTest<SearchBloc, SearchState>(
    'no results has its own state',
    build: () {
      repository.onSearch = (_) async => [];
      return SearchBloc(repository, debounce: Duration.zero);
    },
    act: (bloc) => bloc.add(SearchQueryChanged('missing')),
    wait: const Duration(milliseconds: 30),
    expect: () => [
      isA<SearchState>().having((s) => s.status, 'status', LoadStatus.loading),
      isA<SearchState>().having((s) => s.status, 'status', LoadStatus.empty),
    ],
  );
  blocTest<SearchBloc, SearchState>(
    'request failures have retryable state',
    build: () {
      repository.onSearch = (_) async => throw const AppFailure('Offline');
      return SearchBloc(repository, debounce: Duration.zero);
    },
    act: (bloc) => bloc.add(SearchQueryChanged('test')),
    wait: const Duration(milliseconds: 30),
    expect: () => [
      isA<SearchState>(),
      isA<SearchState>().having((s) => s.error, 'error', 'Offline'),
    ],
  );
}
