import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tvmaze_discovery/app.dart';
import 'package:tvmaze_discovery/core/load_status.dart';
import 'package:tvmaze_discovery/data/models.dart';
import 'package:tvmaze_discovery/features/discover/discover_bloc.dart';
import 'package:tvmaze_discovery/presentation/screens/discover_screen.dart';
import 'fakes.dart';

void main() {
  testWidgets('scrolling the collection requests the next API page', (
    tester,
  ) async {
    final repository = FakeShowRepository()
      ..onPage = (page) async {
        if (page == 0) {
          return List.generate(
            30,
            (index) => Show(id: index + 1, name: 'Fixture $index', rating: 8),
          );
        }
        if (page == 1) return [const Show(id: 999, name: 'Next page fixture')];
        return [];
      };
    await tester.pumpWidget(
      TvMazeApp(
        watchlistStore: MemoryWatchlistStore(),
        showRepository: repository,
      ),
    );
    await tester.pumpAndSettle();
    final bloc = tester
        .element(find.byType(DiscoverScreen))
        .read<DiscoverBloc>();
    final scroll = tester
        .widget<CustomScrollView>(find.byType(CustomScrollView).first)
        .controller!;
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(repository.pages, contains(1));
    expect(bloc.state.shows.any((show) => show.id == 999), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'search renders API results, an empty response, and clear state',
    (tester) async {
      final repository = FakeShowRepository()
        ..onSearch = (query) async => query == 'missing' ? [] : [sampleShow];
      await tester.pumpWidget(
        TvMazeApp(
          watchlistStore: MemoryWatchlistStore(),
          showRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'example');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.text('Test Show'), findsOneWidget);
      expect(repository.searches, ['example']);
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.text('No matches found'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Every great story starts here'), findsOneWidget);
    },
  );

  testWidgets('cast and episodes are populated from their repositories', (
    tester,
  ) async {
    final repository = FakeShowRepository();
    repository.onCast = (_) async => [
      const CastMember(name: 'Fixture actor', character: 'Fixture role'),
    ];
    repository.onEpisodes = (_) async => [
      const Episode(id: 1, name: 'Fixture pilot', season: 1, number: 1),
      const Episode(
        id: 2,
        name: 'Second season premiere',
        season: 2,
        number: 1,
      ),
    ];
    await tester.pumpWidget(
      TvMazeApp(
        watchlistStore: MemoryWatchlistStore(),
        showRepository: repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Show').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cast'));
    await tester.pumpAndSettle();
    expect(find.text('Fixture actor'), findsOneWidget);
    expect(find.text('as Fixture role'), findsOneWidget);
    await tester.tap(find.text('Episodes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Season 2 (1 episodes)').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Second season premiere'));
    await tester.pumpAndSettle();
    expect(find.text('Second season premiere'), findsOneWidget);
    expect(find.text('Fixture pilot'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discovery API failure renders retry and recovers', (
    tester,
  ) async {
    final repository = FakeShowRepository()
      ..onPage = (_) async => throw const AppFailure('Offline fixture');
    await tester.pumpWidget(
      TvMazeApp(
        watchlistStore: MemoryWatchlistStore(),
        showRepository: repository,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Connection interrupted'), findsOneWidget);
    expect(find.text('Offline fixture'), findsOneWidget);
    repository.onPage = (_) async => [sampleShow];
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('TV Explorer! 👋'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
