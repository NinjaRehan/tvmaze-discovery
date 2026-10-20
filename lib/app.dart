import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'core/app_theme.dart';
import 'data/tvmaze_repository.dart';
import 'data/watchlist_repository.dart';
import 'features/discover/discover_bloc.dart';
import 'features/search/search_bloc.dart';
import 'features/watchlist/watchlist_bloc.dart';
import 'presentation/screens/home_screen.dart';

class TvMazeApp extends StatelessWidget {
  const TvMazeApp({
    super.key,
    required this.watchlistStore,
    this.showRepository,
  });
  final WatchlistStore watchlistStore;
  final ShowRepository? showRepository;
  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<http.Client>(
        create: (_) => http.Client(),
        dispose: (client) => client.close(),
      ),
      RepositoryProvider<ShowRepository>(
        create: (context) =>
            showRepository ?? TvMazeRepository(context.read<http.Client>()),
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              DiscoverBloc(context.read<ShowRepository>())
                ..add(DiscoverRequested()),
        ),
        BlocProvider(
          create: (context) => SearchBloc(context.read<ShowRepository>()),
        ),
        BlocProvider(
          create: (_) => WatchlistBloc(watchlistStore)..add(WatchlistStarted()),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        title: 'TVMaze · Discover. Explore. Save.',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeScreen(),
      ),
    ),
  );
}
