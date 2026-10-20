import 'package:flutter_test/flutter_test.dart';
import 'package:tvmaze_discovery/core/load_status.dart';
import 'package:tvmaze_discovery/data/models.dart';
import 'package:tvmaze_discovery/features/details/details_bloc.dart';
import 'fakes.dart';

void main() {
  test('episodes grouped and sorted by season and number', () {
    final state = DetailsState(
      show: sampleShow,
      episodes: const [
        Episode(id: 3, name: 'Third', season: 2, number: 1),
        Episode(id: 2, name: 'Second', season: 1, number: 2),
        Episode(id: 1, name: 'First', season: 1, number: 1),
      ],
    );
    expect(state.seasons.keys, [1, 2]);
    expect(state.seasons[1]!.map((e) => e.id), [1, 2]);
  });
  test(
    'cast failure remains visible when independent details fetch succeeds',
    () async {
      final repository = FakeShowRepository()
        ..onCast = (_) async => throw const AppFailure('Cast offline');
      final bloc = DetailsBloc(repository, sampleShow);
      addTearDown(bloc.close);
      bloc.add(CastRequested());
      await bloc.stream.firstWhere((s) => s.castStatus == LoadStatus.failure);
      bloc.add(DetailsRequested());
      await bloc.stream.firstWhere((s) => s.status == LoadStatus.success);
      expect(bloc.state.castStatus, LoadStatus.failure);
      expect(bloc.state.castError, 'Cast offline');
      expect(bloc.state.show.name, sampleShow.name);
    },
  );
  test('empty cast and episodes have independent empty states', () async {
    final bloc = DetailsBloc(FakeShowRepository(), sampleShow);
    addTearDown(bloc.close);
    final ready = bloc.stream.firstWhere(
      (s) =>
          s.castStatus == LoadStatus.empty &&
          s.episodesStatus == LoadStatus.empty,
    );
    bloc
      ..add(CastRequested())
      ..add(EpisodesRequested());
    await ready.timeout(const Duration(seconds: 2));
    expect(bloc.state.status, LoadStatus.initial);
  });
}
