import 'package:tvmaze_discovery/data/models.dart';
import 'package:tvmaze_discovery/data/tvmaze_repository.dart';
import 'package:tvmaze_discovery/data/watchlist_repository.dart';

// Synthetic fixtures exist only in tests. The application always uses TVMaze.
const sampleShow = Show(
  id: 1,
  name: 'Test Show',
  genres: ['Drama'],
  rating: 8.2,
);
const otherShow = Show(id: 2, name: 'Another Show');

class FakeShowRepository implements ShowRepository {
  final pages = <int>[];
  final searches = <String>[];
  Future<List<Show>> Function(int)? onPage;
  Future<List<Show>> Function(String)? onSearch;
  Future<Show> Function(int)? onDetails;
  Future<List<CastMember>> Function(int)? onCast;
  Future<List<Episode>> Function(int)? onEpisodes;
  @override
  Future<List<Show>> shows(int page) async {
    pages.add(page);
    return onPage == null ? [sampleShow] : onPage!(page);
  }

  @override
  Future<List<Show>> search(String query) async {
    searches.add(query);
    return onSearch == null ? [sampleShow] : onSearch!(query);
  }

  @override
  Future<Show> details(int id) async =>
      onDetails == null ? sampleShow : onDetails!(id);
  @override
  Future<List<CastMember>> cast(int id) async =>
      onCast == null ? [] : onCast!(id);
  @override
  Future<List<Episode>> episodes(int id) async =>
      onEpisodes == null ? [] : onEpisodes!(id);
}

class MemoryWatchlistStore implements WatchlistStore {
  List<Show> saved = [];
  bool failWrite = false;
  bool failRead = false;
  @override
  Future<List<Show>> read() async {
    if (failRead) {
      throw Exception('Read failed');
    }
    return [...saved];
  }

  @override
  Future<void> write(List<Show> shows) async {
    if (failWrite) {
      throw Exception('Disk full');
    }
    saved = [...shows];
  }
}
