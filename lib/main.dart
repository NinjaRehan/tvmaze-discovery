import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/app_theme.dart';
import 'data/watchlist_repository.dart';
import 'presentation/widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _start();
}

Future<void> _start() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    runApp(TvMazeApp(watchlistStore: WatchlistRepository(preferences)));
  } catch (_) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: Scaffold(
          body: SafeArea(
            child: StatusPanel(
              title: 'Local storage unavailable',
              message:
                  'The app could not open its local storage. Please retry. In a browser, allow site storage.',
              action: _start,
            ),
          ),
        ),
      ),
    );
  }
}
