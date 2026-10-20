import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/load_status.dart';
import 'models.dart';

abstract class WatchlistStore {
  Future<List<Show>> read();
  Future<void> write(List<Show> shows);
}

class WatchlistRepository implements WatchlistStore {
  WatchlistRepository(this.preferences, {this.key = storageKey});
  final SharedPreferences preferences;
  final String key;
  static const storageKey = 'tvmaze.watchlist.v1';

  @override
  Future<List<Show>> read() async {
    try {
      final raw = preferences.getString(key);
      if (raw == null) {
        return [];
      }
      final items = jsonDecode(raw) as List;
      final unique = <int, Show>{};
      for (final item in items) {
        final show = Show.fromJson(item as Map<String, dynamic>);
        unique[show.id] = show;
      }
      return unique.values.toList();
    } catch (_) {
      // Do not overwrite corrupt or temporarily inaccessible saved data.
      throw const AppFailure(
        'Your saved watchlist could not be read. Retry or restore your local app data.',
      );
    }
  }

  @override
  Future<void> write(List<Show> shows) async {
    try {
      final saved = await preferences.setString(
        key,
        jsonEncode(shows.map((show) => show.toJson()).toList()),
      );
      if (!saved) {
        throw const AppFailure('Unable to save your watchlist. Please retry.');
      }
    } catch (_) {
      throw const AppFailure('Unable to save your watchlist. Please retry.');
    }
  }
}
