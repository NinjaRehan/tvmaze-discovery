import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tvmaze_discovery/app.dart';
import 'package:tvmaze_discovery/core/load_status.dart';
import 'package:tvmaze_discovery/data/watchlist_repository.dart';
import 'package:tvmaze_discovery/features/details/details_bloc.dart';
import 'package:tvmaze_discovery/features/discover/discover_bloc.dart';
import 'package:tvmaze_discovery/features/watchlist/watchlist_bloc.dart';
import 'package:tvmaze_discovery/presentation/screens/details_screen.dart';
import 'package:tvmaze_discovery/presentation/screens/discover_screen.dart';
import 'package:tvmaze_discovery/presentation/screens/watchlist_screen.dart';
import 'package:tvmaze_discovery/presentation/widgets/show_widgets.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('live API flow, persistence, and seven application screenshots', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    // Exercise real storage under a unique key, preserving the user's watchlist.
    final storageKey = 'tvmaze.audit.${DateTime.now().microsecondsSinceEpoch}';
    final store = WatchlistRepository(preferences, key: storageKey);
    addTearDown(() => preferences.remove(storageKey));
    await tester.pumpWidget(TvMazeApp(watchlistStore: store));

    Future<void> until(bool Function() condition) async {
      final deadline = DateTime.now().add(const Duration(seconds: 90));
      while (!condition()) {
        if (DateTime.now().isAfter(deadline)) {
          fail(
            'Timed out waiting for live API content. Check your internet connection and the TVMaze service.',
          );
        }
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 90),
      );
      expect(tester.takeException(), isNull);
    }

    var converted = false;
    Future<void> capture(String name) async {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          !converted) {
        await binding.convertFlutterSurfaceToImage();
        converted = true;
        await tester.pump();
      }
      await binding.takeScreenshot(name);
    }

    await until(() => find.byType(ShowCard).evaluate().isNotEmpty);
    final discover = tester
        .element(find.byType(DiscoverScreen))
        .read<DiscoverBloc>();
    final initialCount = discover.state.shows.length;
    final scroll = tester
        .widget<CustomScrollView>(find.byType(CustomScrollView).first)
        .controller!;
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await until(() => discover.state.nextPage >= 2);
    expect(discover.state.shows.length, greaterThan(initialCount));
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    await capture('01-discover');

    await tester.tap(find.text('Watchlist').last);
    await tester.pumpAndSettle();
    expect(find.text('Your watchlist is empty'), findsOneWidget);
    await capture('07-empty-watchlist');
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'breaking');
    await until(() => find.byType(ShowTile).evaluate().isNotEmpty);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await capture('02-search');
    await tester.tap(find.byType(ShowTile).first);
    await until(
      () =>
          find.byType(DetailsScreen).evaluate().isNotEmpty &&
          tester
                  .element(find.byType(DetailsScreen))
                  .read<DetailsBloc>()
                  .state
                  .status ==
              LoadStatus.success,
    );
    await capture('03-details');
    final selectedId = tester
        .element(find.byType(DetailsScreen))
        .read<DetailsBloc>()
        .state
        .show
        .id;
    final watchlist = tester
        .element(find.byType(DetailsScreen))
        .read<WatchlistBloc>();
    await tester.tap(find.text('Add to Watchlist'));
    await until(
      () => watchlist.state.contains(selectedId) && !watchlist.state.saving,
    );
    await preferences.reload();
    expect(
      (await WatchlistRepository(
        preferences,
        key: storageKey,
      ).read()).single.id,
      selectedId,
    );

    await tester.tap(find.text('Episodes'));
    await until(() {
      final status = tester
          .element(find.byType(DetailsScreen))
          .read<DetailsBloc>()
          .state
          .episodesStatus;
      return status == LoadStatus.success || status == LoadStatus.empty;
    });
    await capture('04-episodes');
    await tester.tap(find.text('Cast'));
    await until(() {
      final status = tester
          .element(find.byType(DetailsScreen))
          .read<DetailsBloc>()
          .state
          .castStatus;
      return status == LoadStatus.success || status == LoadStatus.empty;
    });
    await capture('05-cast');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Dispose the app, then restore from the persisted JSON with fresh BLoCs.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await preferences.reload();
    await tester.pumpWidget(
      TvMazeApp(
        watchlistStore: WatchlistRepository(preferences, key: storageKey),
      ),
    );
    await until(() => find.byType(ShowCard).evaluate().isNotEmpty);
    await tester.tap(find.text('Watchlist').last);
    await tester.pumpAndSettle();
    final restored = tester
        .element(find.byType(WatchlistScreen))
        .read<WatchlistBloc>();
    expect(restored.state.contains(selectedId), isTrue);
    await capture('06-watchlist');
    final savedName = restored.state.shows.single.name;
    await tester.tap(find.byTooltip('Remove $savedName from watchlist'));
    await until(
      () => restored.state.status == LoadStatus.empty && !restored.state.saving,
    );
    await preferences.reload();
    expect(await store.read(), isEmpty);
  });
}
