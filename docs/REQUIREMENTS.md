# Assignment requirement mapping

Implementation locations below are source references, not a claim of runtime verification.

| Requirement | Implementation |
| --- | --- |
| Fetch API shows | `data/tvmaze_repository.dart`, `features/discover/discover_bloc.dart` |
| Poster/title/genre/rating | `presentation/widgets/show_widgets.dart` |
| Scroll pagination | `presentation/screens/discover_screen.dart` with threshold and load-more fallback |
| Loading / empty / error states | `core/load_status.dart`, feature states, `StatusPanel`, `InlineError` |
| Dynamic name search | `features/search/search_bloc.dart` |
| Search debounce | 400 ms delay inside restartable search event handler |
| Search has no results | `LoadStatus.empty` rendered in `search_screen.dart` |
| Show detail fields | `details_bloc.dart`, `details_screen.dart` |
| Cast API / actor / character | independent cast request and tab |
| Episodes grouped by season | `DetailsState.seasons`, season selector |
| Add/remove watchlist | shared `WatchButton`, `WatchlistToggled` |
| Local persistence / restart | `watchlist_repository.dart`, versioned SharedPreferences JSON |
| flutter_bloc / events / states | four event-driven `Bloc<Event, State>` classes |
| No API calls in UI | all six HTTP paths in `TvMazeRepository` |
| Reusable widgets | `Poster`, `ShowCard`, `ShowTile`, `WatchButton`, status/rating/heading widgets |
| Navigation | Material route for details, three-destination bottom navigation |
| Missing information | null-safe model defaults, NR rating, poster placeholder, empty summaries |
| API failures | 20-second timeout, network/429/server/schema handling and retry controls |
| GitHub repository | local repository initialized; remote creation/push pending |
| README setup | root `README.md`, Linux/Android setup scripts, VS Code launch profiles |
| Application screenshots | real-API integration capture automation supplied; seven real Chromium screenshots captured, refreshed and visually reviewed against the reference |
| Runs without errors | analysis, 36 tests, release web build and live Chromium flow pass; Android/device check pending |
| Viva explanation | `docs/BLOC_GUIDE.md` |

The assignment asks for discovery, search, details, episodes/cast, and watchlist. The visual reference's extra profile, people-search, similar-show, and playback controls are not assignment requirements and have no fabricated functionality in this implementation.
