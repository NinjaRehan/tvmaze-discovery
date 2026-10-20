# Assignment and reference-UI audit

## Evidence

The normal-terminal audit logs in `docs/audit/` record analysis, automated tests, the release web build, and the live browser flow. During this review the unit/widget suite passed **36 tests**, including phone/desktop details-header regressions, scroll-triggered pagination, search/no-results/clear, cast/season rendering, discovery error recovery, stale-search protection, and persistence rollback/restoration.

`flutter analyze --no-pub` passes after the latest edits. The release web build succeeds. The live browser flow passed and all seven real screenshots were captured/reviewed. That review found an initial poster-frame timing issue and black text on purple actions. Both were corrected; the refreshed seven screenshots were captured at 19:12–19:13 on 2026-10-20 and inspected, confirming the poster and white action text render correctly. Passing a web build is not evidence of an Android APK build.

## Functional requirements

| Assignment requirement | Implementation and verification |
| --- | --- |
| Fetch/display TV shows | `TvMazeRepository.shows` calls the live paginated endpoint; discovery BLoC and repository tests |
| Posters, titles, genres, ratings | reusable `ShowCard` and `ShowTile`; missing poster fallback and NR rating |
| Infinite scroll pagination | scroll threshold dispatches `DiscoverMoreRequested`; UI test checks a scroll fetches page 1; live audit verifies increased collection size |
| Fetching indicators | separate initial, refresh, pagination, search, details, cast, episodes, and save indicators |
| Dynamic show-name search | actual `/search/shows` response unwrapped in repository; UI and BLoC tests |
| Debounce | 400 ms in restartable BLoC; rapid typing test; old responses invalidated on edit/clear |
| No search results | distinct empty state, readable prompt, UI regression test |
| Details poster/title/summary/rating/genres | selected-show API fetch, summary preview plus full synopsis, metadata chips and rating badge |
| Cast | independent API call/status, actor photo/name and character name; populated/empty/error states |
| Episodes grouped by season | sorted season map and selector, episode ordering/dates/runtime/summary; grouping and selector tests |
| Add/remove watchlist | shared app-scoped BLoC across cards, details, and watchlist; transactional persistence |
| Persistence across restarts | SharedPreferences stores show metadata; repository/BLoC reconstruction tests; live audit disposes/recreates widget tree and BLoCs using actual local storage |
| flutter_bloc | four event-driven BLoCs with explicit feature events and immutable states |
| Loading/success/empty/error | shared load-status enum, feature-specific state, explicit retries and readable failures |
| API/business logic separated from widgets | all requests in `data/tvmaze_repository.dart`, all storage in `data/watchlist_repository.dart`, decisions in feature BLoCs |
| Reusable UI/organized structure | dedicated models/repositories/core/features/presentation widgets and screens |
| Navigation | Home/Search/Watchlist destinations, show-details route, shelf collection routes, details tabs and episode bottom sheet |
| Missing information/API failures | null-safe defaults, missing image fallback, HTML decoding, timeout/429/server/malformed-data mapping, failed-save rollback |
| No hardcoded TV show data | production content comes from API; synthetic records only in tests; shelf selections use loaded records/ratings |
| Clean UI | dark/purple reference styling, compact poster shelves, consistent cards/rows/chips, phone and wider layouts |
| README/setup | root README, SDK/Android scripts, VS Code launch settings and CI workflow |
| Application screenshots | `scripts/screenshots.sh chrome` or Android device capture; real API and isolated real storage; gallery inserted only after files exist |
| Viva readiness | `docs/BLOC_GUIDE.md` explains events/states, transformers, lifetimes, storage and failure paths |

An OS-level Android force-stop/relaunch and an actual Android APK build still require the Android SDK/device. The browser audit verifies fresh application state and real stored JSON restoration, not an Android process restart.

## Comparison with the supplied UI reference

Reference: `/home/rehan/Downloads/TVMaze App UI Showcase.png`.

| Reference screen | Changes / matching elements |
| --- | --- |
| Home | compact greeting, search bar, horizontal poster shelves, purple actions, collection pagination below shelves; the earlier large hero banner was removed |
| Search | dark search field, clear action, poster/title/year/genre/rating result rows, purple accents |
| Details | large poster fading into dark surface, title/year/rating, genre chips, summary preview, wide purple watchlist action, pinned detail tabs and quick-info card |
| Seasons/episodes | season selector, compact episode image/number/title/date rows and summary bottom sheet |
| Cast | compact actor images, actor names, character names and separators |
| Watchlist | saved-show rows, metadata, heart remove actions, persistent saved state |
| Empty watchlist | code-drawn purple open-box/heart illustration, explanatory message and Explore Shows action |

The result follows the reference's visual language and required screen structure. It is not a pixel-for-pixel reproduction. API content and posters vary. TVMaze's provided endpoints do not return a trending feed, so the home shelves are labeled **Featured Shows** and **Top Rated**, based on actual loaded data. Profile, people-search, similar-show and playback controls in the showcase are outside the written assignment; no nonfunctional placeholder controls are included for them.

## Android configuration review

The resolved Android implementations of SharedPreferences and URL Launcher use modern AGP/Java tooling; the SharedPreferences implementation also uses Kotlin 2.3. The original scaffold's older Kotlin settings were replaced with Kotlin 2.3.0, AGP 8.13.2, Gradle 8.13 and JVM 17. Versions were checked against the installed plugin sources and [Android's compatibility documentation](https://developer.android.com/build/releases/agp-8-13-0-release-notes). This is source/configuration review; it does not substitute for a successful APK build.

## Remaining submission gates

- [x] Finish the real-API browser flow and capture all seven screenshots.
- [x] Inspect the seven runtime images against the reference; resolve identified layout/content issues.
- [x] Refresh screenshots to confirm the final first-frame poster and white action-text polish.
- [ ] Build/debug the Android app on a device or emulator and verify force-stop/relaunch persistence.
- [ ] Create/push the GitHub repository and confirm the CI workflow result.
- [ ] Ensure the student can explain and modify the BLoC implementation independently.
