import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../core/load_status.dart';
import '../../data/models.dart';
import '../../data/tvmaze_repository.dart';

sealed class SearchEvent {}

class SearchQueryChanged extends SearchEvent {
  SearchQueryChanged(this.query);
  final String query;
}

class SearchRetried extends SearchEvent {}

class SearchState {
  const SearchState({
    this.status = LoadStatus.initial,
    this.query = '',
    this.shows = const [],
    this.error,
  });
  final LoadStatus status;
  final String query;
  final List<Show> shows;
  final String? error;
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(
    this.repository, {
    this.debounce = const Duration(milliseconds: 400),
  }) : super(const SearchState()) {
    // Restart immediately on every keystroke, including clear. This invalidates
    // old requests before the new debounce timer starts.
    on<SearchEvent>((event, emit) async {
      final query = event is SearchQueryChanged
          ? event.query.trim()
          : state.query;
      if (query.isEmpty) {
        emit(const SearchState());
        return;
      }
      emit(SearchState(status: LoadStatus.loading, query: query));
      if (event is SearchQueryChanged) {
        await Future<void>.delayed(debounce);
      }
      if (emit.isDone) {
        return;
      }
      try {
        final results = await repository.search(query);
        if (emit.isDone) {
          return;
        }
        emit(
          SearchState(
            status: results.isEmpty ? LoadStatus.empty : LoadStatus.success,
            query: query,
            shows: List.unmodifiable(results),
          ),
        );
      } catch (error) {
        if (!emit.isDone) {
          emit(
            SearchState(
              status: LoadStatus.failure,
              query: query,
              error: failureMessage(error),
            ),
          );
        }
      }
    }, transformer: restartable());
  }
  final ShowRepository repository;
  final Duration debounce;
}
