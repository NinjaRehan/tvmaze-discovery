import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tvmaze_discovery/core/load_status.dart';
import 'package:tvmaze_discovery/data/models.dart';
import 'package:tvmaze_discovery/data/watchlist_repository.dart';
import 'package:tvmaze_discovery/features/watchlist/watchlist_bloc.dart';
import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'SharedPreferences survives new repository and BLoC instances',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final first = WatchlistBloc(WatchlistRepository(prefs));
      first.add(WatchlistStarted());
      await first.stream.firstWhere((s) => s.ready);
      first.add(WatchlistToggled(sampleShow));
      await first.stream.firstWhere((s) => !s.saving && s.contains(1));
      await first.close();
      final second = WatchlistBloc(WatchlistRepository(prefs));
      second.add(WatchlistStarted());
      final restored = await second.stream.firstWhere((s) => s.ready);
      expect(restored.shows.single.name, sampleShow.name);
      second.add(WatchlistToggled(sampleShow));
      await second.stream.firstWhere((s) => s.status == LoadStatus.empty);
      expect(await WatchlistRepository(prefs).read(), isEmpty);
      await second.close();
    },
  );
  test(
    'saved summaries round-trip without interpreting literal markup',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repo = WatchlistRepository(await SharedPreferences.getInstance());
      const show = Show(id: 10, name: 'Title', summary: 'A < B & C > D');
      await repo.write([show]);
      expect((await repo.read()).single.summary, show.summary);
    },
  );
  test('corrupt local data is preserved and reported', () async {
    SharedPreferences.setMockInitialValues({
      WatchlistRepository.storageKey: 'invalid',
    });
    final prefs = await SharedPreferences.getInstance();
    await expectLater(
      WatchlistRepository(prefs).read(),
      throwsA(isA<AppFailure>()),
    );
    expect(prefs.getString(WatchlistRepository.storageKey), 'invalid');
  });
  blocTest<WatchlistBloc, WatchlistState>(
    'failed save rolls back to original data',
    build: () => WatchlistBloc(MemoryWatchlistStore()..failWrite = true),
    seed: () => const WatchlistState(status: LoadStatus.empty),
    act: (bloc) => bloc.add(WatchlistToggled(sampleShow)),
    expect: () => [
      isA<WatchlistState>().having((s) => s.saving, 'saving', true),
      isA<WatchlistState>()
          .having((s) => s.shows, 'unchanged shows', isEmpty)
          .having((s) => s.error, 'error', isNotNull),
    ],
  );
  blocTest<WatchlistBloc, WatchlistState>(
    'load and rapid toggles are serialized',
    build: () => WatchlistBloc(MemoryWatchlistStore()),
    act: (bloc) => bloc
      ..add(WatchlistStarted())
      ..add(WatchlistToggled(sampleShow))
      ..add(WatchlistToggled(otherShow))
      ..add(WatchlistToggled(sampleShow)),
    verify: (bloc) => expect(bloc.state.shows.map((s) => s.id), [2]),
  );
  blocTest<WatchlistBloc, WatchlistState>(
    'failed read prevents overwriting unread data',
    build: () => WatchlistBloc(MemoryWatchlistStore()..failRead = true),
    act: (bloc) => bloc
      ..add(WatchlistStarted())
      ..add(WatchlistToggled(sampleShow)),
    verify: (bloc) {
      expect(bloc.state.status, LoadStatus.failure);
      expect(bloc.state.shows, isEmpty);
    },
  );
}
