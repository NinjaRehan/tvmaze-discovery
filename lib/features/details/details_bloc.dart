import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../core/load_status.dart';
import '../../data/models.dart';
import '../../data/tvmaze_repository.dart';

sealed class DetailsEvent {}

class DetailsRequested extends DetailsEvent {}

class CastRequested extends DetailsEvent {}

class EpisodesRequested extends DetailsEvent {}

class DetailsState {
  const DetailsState({
    required this.show,
    this.status = LoadStatus.initial,
    this.castStatus = LoadStatus.initial,
    this.episodesStatus = LoadStatus.initial,
    this.cast = const [],
    this.episodes = const [],
    this.error,
    this.castError,
    this.episodesError,
  });
  final Show show;
  final LoadStatus status;
  final LoadStatus castStatus;
  final LoadStatus episodesStatus;
  final List<CastMember> cast;
  final List<Episode> episodes;
  final String? error;
  final String? castError;
  final String? episodesError;

  DetailsState copyWith({
    Show? show,
    LoadStatus? status,
    LoadStatus? castStatus,
    LoadStatus? episodesStatus,
    List<CastMember>? cast,
    List<Episode>? episodes,
    String? error,
    String? castError,
    String? episodesError,
  }) => DetailsState(
    show: show ?? this.show,
    status: status ?? this.status,
    castStatus: castStatus ?? this.castStatus,
    episodesStatus: episodesStatus ?? this.episodesStatus,
    cast: cast ?? this.cast,
    episodes: episodes ?? this.episodes,
    error: status == null ? this.error : error,
    castError: castStatus == null ? this.castError : castError,
    episodesError: episodesStatus == null ? this.episodesError : episodesError,
  );

  Map<int, List<Episode>> get seasons {
    final result = <int, List<Episode>>{};
    for (final episode in episodes) {
      result.putIfAbsent(episode.season, () => []).add(episode);
    }
    final sorted = result.keys.toList()..sort();
    for (final group in result.values) {
      group.sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
    }
    return {for (final season in sorted) season: result[season]!};
  }
}

class DetailsBloc extends Bloc<DetailsEvent, DetailsState> {
  DetailsBloc(this.repository, Show initial)
    : super(DetailsState(show: initial)) {
    on<DetailsRequested>((event, emit) async {
      emit(state.copyWith(status: LoadStatus.loading));
      try {
        final show = await repository.details(state.show.id);
        emit(state.copyWith(show: show, status: LoadStatus.success));
      } catch (error) {
        emit(
          state.copyWith(
            status: LoadStatus.failure,
            error: failureMessage(error),
          ),
        );
      }
    }, transformer: droppable());
    on<CastRequested>((event, emit) async {
      emit(state.copyWith(castStatus: LoadStatus.loading));
      try {
        final cast = await repository.cast(state.show.id);
        emit(
          state.copyWith(
            castStatus: cast.isEmpty ? LoadStatus.empty : LoadStatus.success,
            cast: List.unmodifiable(cast),
          ),
        );
      } catch (error) {
        emit(
          state.copyWith(
            castStatus: LoadStatus.failure,
            castError: failureMessage(error),
          ),
        );
      }
    }, transformer: droppable());
    on<EpisodesRequested>((event, emit) async {
      emit(state.copyWith(episodesStatus: LoadStatus.loading));
      try {
        final episodes = await repository.episodes(state.show.id);
        emit(
          state.copyWith(
            episodesStatus: episodes.isEmpty
                ? LoadStatus.empty
                : LoadStatus.success,
            episodes: List.unmodifiable(episodes),
          ),
        );
      } catch (error) {
        emit(
          state.copyWith(
            episodesStatus: LoadStatus.failure,
            episodesError: failureMessage(error),
          ),
        );
      }
    }, transformer: droppable());
  }
  final ShowRepository repository;
}
