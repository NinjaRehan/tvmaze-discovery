import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../core/load_status.dart';
import '../../data/models.dart';
import '../../data/watchlist_repository.dart';

sealed class WatchlistEvent {}

class WatchlistStarted extends WatchlistEvent {}

class WatchlistToggled extends WatchlistEvent {
  WatchlistToggled(this.show);
  final Show show;
}

class WatchlistState {
  const WatchlistState({
    this.status = LoadStatus.initial,
    this.shows = const [],
    this.saving = false,
    this.error,
  });
  final LoadStatus status;
  final List<Show> shows;
  final bool saving;
  final String? error;
  bool contains(int id) => shows.any((show) => show.id == id);
  bool get ready => status == LoadStatus.success || status == LoadStatus.empty;
}

class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  WatchlistBloc(this.store) : super(const WatchlistState()) {
    // Loading and mutations are serialized together; rapid taps cannot lose data.
    on<WatchlistEvent>((event, emit) async {
      if (event is WatchlistStarted) {
        emit(const WatchlistState(status: LoadStatus.loading));
        try {
          final shows = await store.read();
          emit(
            WatchlistState(
              status: shows.isEmpty ? LoadStatus.empty : LoadStatus.success,
              shows: List.unmodifiable(shows),
            ),
          );
        } catch (error) {
          emit(
            WatchlistState(
              status: LoadStatus.failure,
              error: failureMessage(error),
            ),
          );
        }
      } else if (event is WatchlistToggled && state.ready) {
        final previous = state;
        final shows = [...state.shows];
        if (state.contains(event.show.id)) {
          shows.removeWhere((show) => show.id == event.show.id);
        } else {
          shows.insert(0, event.show);
        }
        emit(
          WatchlistState(
            status: previous.status,
            shows: previous.shows,
            saving: true,
          ),
        );
        try {
          // Commit UI only after persistence succeeds.
          await store.write(shows);
          emit(
            WatchlistState(
              status: shows.isEmpty ? LoadStatus.empty : LoadStatus.success,
              shows: List.unmodifiable(shows),
            ),
          );
        } catch (error) {
          emit(
            WatchlistState(
              status: previous.status,
              shows: previous.shows,
              error: failureMessage(error),
            ),
          );
        }
      }
    }, transformer: sequential());
  }
  final WatchlistStore store;
}
