import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tvmaze_discovery/app.dart';
import 'package:tvmaze_discovery/data/models.dart';
import 'fakes.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(800, 600)]) {
    testWidgets('details header lays out and pins at $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = FakeShowRepository()
        ..onDetails = (_) async => Show(
          id: sampleShow.id,
          name: sampleShow.name,
          summary: List.filled(
            40,
            'A long synopsis makes the overview scrollable.',
          ).join(' '),
        );
      await tester.pumpWidget(
        TvMazeApp(
          watchlistStore: MemoryWatchlistStore(),
          showRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Show').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(TabBar)).height, 52);
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(TabBar)).height, 52);
      await tester.tap(find.text('Episodes'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('No episodes listed'), findsOneWidget);
    });
  }
  testWidgets('discover → details → save → watchlist → remove', (tester) async {
    final store = MemoryWatchlistStore();
    await tester.pumpWidget(
      TvMazeApp(watchlistStore: store, showRepository: FakeShowRepository()),
    );
    await tester.pumpAndSettle();
    expect(find.text('TV Explorer! 👋'), findsOneWidget);
    await tester.tap(find.text('Test Show').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to Watchlist'));
    await tester.pumpAndSettle();
    expect(store.saved.single.id, 1);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite_border_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('My Watchlist'), findsOneWidget);
    expect(find.text('1 saved show · Available after restart'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove Test Show from watchlist').last);
    await tester.pumpAndSettle();
    expect(find.text('Your watchlist is empty'), findsOneWidget);
    expect(store.saved, isEmpty);
  });
  testWidgets('search screen renders an empty query prompt', (tester) async {
    await tester.pumpWidget(
      TvMazeApp(
        watchlistStore: MemoryWatchlistStore(),
        showRepository: FakeShowRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Every great story starts here'), findsOneWidget);
  });
}
