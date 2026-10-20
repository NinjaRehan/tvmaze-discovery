import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_theme.dart';
import '../../core/load_status.dart';
import '../../features/watchlist/watchlist_bloc.dart';
import '../widgets/common.dart';
import '../widgets/empty_watchlist_art.dart';
import '../widgets/show_widgets.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key, required this.onExplore});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          eyebrow: 'Saved for a good night',
          title: 'My Watchlist',
          trailing: Icon(
            Icons.favorite_rounded,
            color: AppTheme.purple,
            size: 28,
          ),
        ),
        Expanded(
          child: BlocBuilder<WatchlistBloc, WatchlistState>(
            builder: (context, state) {
              if (state.status == LoadStatus.initial ||
                  state.status == LoadStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == LoadStatus.failure) {
                return SingleChildScrollView(
                  child: StatusPanel(
                    title: 'Watchlist unavailable',
                    message: state.error!,
                    action: () =>
                        context.read<WatchlistBloc>().add(WatchlistStarted()),
                  ),
                );
              }
              if (state.shows.isEmpty) {
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: StatusPanel(
                        title: 'Your watchlist is empty',
                        message:
                            'Discover amazing shows and save them here to watch later.',
                        illustration: const EmptyWatchlistArt(),
                        action: onExplore,
                        actionLabel: 'Explore Shows',
                      ),
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${state.shows.length} saved ${state.shows.length == 1 ? 'show' : 'shows'} · Available after restart',
                    style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (state.saving) const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: ListView.separated(
                      key: const PageStorageKey('watchlist-scroll'),
                      itemCount: state.shows.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (_, index) => ShowTile(
                        show: state.shows[index],
                        showWatchButton: true,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
