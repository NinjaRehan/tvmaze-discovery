import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tvmaze_discovery/core/load_status.dart';
import 'package:tvmaze_discovery/features/discover/discover_bloc.dart';
import 'fakes.dart';

void main() {
  late FakeShowRepository repository;
  setUp(() => repository = FakeShowRepository());
  blocTest<DiscoverBloc, DiscoverState>(
    'loads first page',
    build: () => DiscoverBloc(repository),
    act: (bloc) => bloc.add(DiscoverRequested()),
    expect: () => [
      isA<DiscoverState>().having(
        (s) => s.status,
        'status',
        LoadStatus.loading,
      ),
      isA<DiscoverState>()
          .having((s) => s.shows.length, 'shows', 1)
          .having((s) => s.nextPage, 'page', 1),
    ],
    verify: (_) => expect(repository.pages, [0]),
  );
  blocTest<DiscoverBloc, DiscoverState>(
    'pagination deduplicates IDs and stops on empty page',
    build: () {
      repository.onPage = (page) async =>
          page == 1 ? [sampleShow, otherShow] : [];
      return DiscoverBloc(repository);
    },
    seed: () => const DiscoverState(
      status: LoadStatus.success,
      shows: [sampleShow],
      nextPage: 1,
    ),
    act: (bloc) => bloc
      ..add(DiscoverMoreRequested())
      ..add(DiscoverMoreRequested())
      ..add(DiscoverMoreRequested()),
    expect: () => [
      isA<DiscoverState>().having((s) => s.loadingMore, 'loading more', true),
      isA<DiscoverState>().having((s) => s.shows.length, 'unique shows', 2),
      isA<DiscoverState>().having((s) => s.loadingMore, 'loading more', true),
      isA<DiscoverState>().having((s) => s.hasMore, 'has more', false),
    ],
    verify: (_) => expect(repository.pages, [1, 2]),
  );
  blocTest<DiscoverBloc, DiscoverState>(
    'failed page keeps data and retry uses same page',
    build: () {
      var calls = 0;
      repository.onPage = (_) async {
        if (calls++ == 0) {
          throw const AppFailure('Offline');
        }
        return [otherShow];
      };
      return DiscoverBloc(repository);
    },
    seed: () => const DiscoverState(
      status: LoadStatus.success,
      shows: [sampleShow],
      nextPage: 1,
    ),
    act: (bloc) => bloc
      ..add(DiscoverMoreRequested())
      ..add(DiscoverMoreRequested()),
    expect: () => [
      isA<DiscoverState>(),
      isA<DiscoverState>()
          .having((s) => s.moreError, 'error', 'Offline')
          .having((s) => s.shows.single.id, 'preserved show', 1),
      isA<DiscoverState>(),
      isA<DiscoverState>().having((s) => s.shows.length, 'shows', 2),
    ],
    verify: (_) => expect(repository.pages, [1, 1]),
  );
  blocTest<DiscoverBloc, DiscoverState>(
    'failed refresh retains previously loaded collection',
    build: () {
      repository.onPage = (_) async => throw const AppFailure('Offline');
      return DiscoverBloc(repository);
    },
    seed: () => const DiscoverState(
      status: LoadStatus.success,
      shows: [sampleShow],
      nextPage: 4,
    ),
    act: (bloc) => bloc.add(DiscoverRefreshed()),
    expect: () => [
      isA<DiscoverState>(),
      isA<DiscoverState>()
          .having((s) => s.status, 'status', LoadStatus.success)
          .having((s) => s.nextPage, 'preserved page', 4)
          .having((s) => s.error, 'error', 'Offline'),
    ],
  );
  blocTest<DiscoverBloc, DiscoverState>(
    'first load failure is explicit',
    build: () {
      repository.onPage = (_) async => throw const AppFailure('Offline');
      return DiscoverBloc(repository);
    },
    act: (bloc) => bloc.add(DiscoverRequested()),
    expect: () => [
      isA<DiscoverState>(),
      isA<DiscoverState>().having(
        (s) => s.status,
        'status',
        LoadStatus.failure,
      ),
    ],
  );
}
