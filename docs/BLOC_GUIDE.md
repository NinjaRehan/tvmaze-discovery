# BLoC implementation and viva guide

## Follow one action through the app

Example: tapping a show heart.

1. `WatchButton` dispatches `WatchlistToggled(show)` to `WatchlistBloc`.
2. The BLoC builds a proposed new list from the current saved state.
3. It emits `saving: true`; buttons temporarily disable to avoid ambiguous repeated actions.
4. `WatchlistStore.write()` serializes the show metadata and saves it using SharedPreferences.
5. After a successful write, the BLoC emits the new list. All interested `BlocBuilder`s rebuild from that same state.
6. If the write fails, the BLoC keeps the previous list and emits a readable error. `BlocListener` displays a snackbar.

The widget does not know how storage works. The repository does not decide what the screen looks like. The BLoC coordinates the operation.

## Discovery

Events: `DiscoverRequested`, `DiscoverRefreshed`, `DiscoverMoreRequested`.

State: `status`, `shows`, `nextPage`, `hasMore`, `loadingMore`, `error`, `moreError`.

The first fetch loads API page 0. A successful page advances `nextPage`; a failed page does not, so retry fetches the same page. Existing shows are retained on a pagination failure. Deduplication uses the numeric TVMaze show ID. An empty page (including the API's terminal 404) sets `hasMore` to false. The UI offers automatic scrolling and an explicit load-more action.

All discovery events use one **sequential** transformer. A refresh cannot finish concurrently with an older pagination event and append an out-of-date page to the refreshed collection. The UI avoids enqueueing load-more events while loading or while an error awaits an explicit retry.

## Search

Events: `SearchQueryChanged`, `SearchRetried`.

State: `status`, normalized `query`, `shows`, `error`.

A **restartable** transformer invalidates the previous event handler on every edit. The handler emits loading, waits 400 ms, and checks `emit.isDone` before requesting data. If another keystroke arrives during the wait, no API call is made for the older query. If a previous HTTP request is already in flight, it may still complete, but its canceled handler cannot publish a result. Clearing the field invalidates old work immediately.

This distinction matters: debouncing reduces request frequency, while invalidating stale results protects correctness. A timer only in the widget would spread business logic across the UI and be harder to test.

## Details

Events: `DetailsRequested`, `CastRequested`, `EpisodesRequested`.

The screen owns a route-scoped `DetailsBloc`. Closing the route disposes it through `BlocProvider`. The initial list/search/saved show supplies a fallback while fresh details load. Three independently tracked statuses allow cast and episodes to succeed even if the details endpoint fails, and allow retrying just the failed section.

Each request type uses **droppable** handling so repeated taps cannot overlap the same endpoint. Different endpoint types can run concurrently. When one request finishes it copies the **latest state**, preserving other sections and their error messages. A regression test checks that a cast error survives a subsequent successful details update.

Episodes are grouped by season number, then sorted by episode number. A season selection is a presentation choice; the fetched episode list belongs to the BLoC.

## Watchlist

Events: `WatchlistStarted`, `WatchlistToggled`.

The app-scoped BLoC serves every route, so the card, details button, and watchlist screen agree on saved state. Loading and writes share one **sequential** queue, preventing rapid modifications from overwriting one another. Every write is awaited before the new list becomes visible.

Storage uses `tvmaze.watchlist.v1`. Saved JSON contains show metadata, not just IDs, so titles and summaries survive offline restarts. IDs prevent duplicate saved shows. Corrupt data is reported without silently erasing it. Mutations are disabled until the initial read has succeeded.

SharedPreferences is appropriate for a small personal watchlist. A large library or complex querying would justify a local database. Poster image files are not stored in SharedPreferences.

## Why the abstractions exist

- `ShowRepository`: fakeable boundary around API operations.
- `TvMazeRepository`: HTTPS, timeout, status handling, JSON parsing, and normalization.
- `WatchlistStore`: fakeable boundary around persistence.
- `WatchlistRepository`: SharedPreferences-backed implementation.
- `BlocBuilder`: rebuilds UI from current state.
- `BlocListener`: one-off effects such as error snackbars.
- `RepositoryProvider` / `BlocProvider`: dependency injection and lifetime management.

States use immutable fields and new state objects rather than mutating the existing one. Published lists are unmodifiable. There is no requirement to use Equatable: these BLoCs emit distinct objects and the screens remain correct. Equality could be added later to reduce equivalent rebuilds.

## Practice before the viva

Explain these without memorizing the text:

1. Trace scrolling from the UI event to the repository and back to the grid.
2. Explain why retrying page 2 must not advance to page 3 after a failure.
3. Type two queries where the first response is slower. Why is the final screen correct?
4. Explain why clearing search needs to invalidate an existing request.
5. Disconnect the device and describe which parts of a saved show remain available.
6. Explain what would happen if persistence failed after adding a show.
7. Identify the three lifetimes: app-scoped repositories, app-scoped watchlist/search/discovery, route-scoped details.
8. Show the exact file where each endpoint is called. Explain why no HTTP call is in a UI widget.
9. Explain why `setState` for a selected tab does not replace BLoC business state.
10. Modify the debounce interval or add a quick-info field, then update the relevant test.

Read and adapt the implementation, run the tests, and demonstrate changes yourself. This guide is a walkthrough, not evidence that the application has been run or evaluated.
