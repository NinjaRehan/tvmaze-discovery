import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../core/load_status.dart';
import '../../data/models.dart';
import '../../data/tvmaze_repository.dart';

sealed class DiscoverEvent {}

class DiscoverRequested extends DiscoverEvent {}

class DiscoverRefreshed extends DiscoverEvent {}

class DiscoverMoreRequested extends DiscoverEvent {}

class DiscoverState {
  const DiscoverState({
    this.status = LoadStatus.initial,
    this.shows = const [],
    this.nextPage = 0,
    this.hasMore = true,
    this.loadingMore = false,
    this.error,
    this.moreError,
  });
  final LoadStatus status;
  final List<Show> shows;
  final int nextPage;
  final bool hasMore;
  final bool loadingMore;
  final String? error;
  final String? moreError;

  // Both shelves are derived from API records. TVMaze has no trending endpoint,
  // so rating order is labeled honestly rather than pretending to be trends.
  List<Show> get featuredShows => shows.take(12).toList(growable: false);
  List<Show> get topRatedShows {
    final rated = shows.where((show) => show.rating != null).toList()
      ..sort((a, b) => b.rating!.compareTo(a.rating!));
    return rated.take(12).toList(growable: false);
  }
}

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  DiscoverBloc(this.repository) : super(const DiscoverState()) {
    // All event types share one sequential queue: refresh cannot race pagination.
    on<DiscoverEvent>(_handle, transformer: sequential());
  }
  final ShowRepository repository;

  Future<void> _handle(DiscoverEvent event, Emitter<DiscoverState> emit) async {
    if (event is DiscoverRequested && state.status == LoadStatus.success) {
      return;
    }
    if (event is DiscoverMoreRequested) {
      if (!state.hasMore || state.status != LoadStatus.success) {
        return;
      }
      final previous = state;
      emit(
        DiscoverState(
          status: previous.status,
          shows: previous.shows,
          nextPage: previous.nextPage,
          hasMore: previous.hasMore,
          loadingMore: true,
        ),
      );
      try {
        final page = await repository.shows(previous.nextPage);
        final unique = {for (final show in previous.shows) show.id: show};
        for (final show in page) {
          unique[show.id] = show;
        }
        emit(
          DiscoverState(
            status: LoadStatus.success,
            shows: List.unmodifiable(unique.values),
            nextPage: previous.nextPage + 1,
            hasMore: page.isNotEmpty,
          ),
        );
      } catch (error) {
        emit(
          DiscoverState(
            status: previous.status,
            shows: previous.shows,
            nextPage: previous.nextPage,
            hasMore: previous.hasMore,
            moreError: failureMessage(error),
          ),
        );
      }
      return;
    }
    final previous = state;
    emit(DiscoverState(status: LoadStatus.loading, shows: previous.shows));
    try {
      final shows = await repository.shows(0);
      emit(
        DiscoverState(
          status: shows.isEmpty ? LoadStatus.empty : LoadStatus.success,
          shows: List.unmodifiable(shows),
          nextPage: 1,
          hasMore: shows.isNotEmpty,
        ),
      );
    } catch (error) {
      // Keep existing shows visible if pull-to-refresh fails.
      emit(
        DiscoverState(
          status: previous.shows.isEmpty
              ? LoadStatus.failure
              : LoadStatus.success,
          shows: previous.shows,
          nextPage: previous.nextPage,
          hasMore: previous.hasMore,
          error: failureMessage(error),
        ),
      );
    }
  }
}
