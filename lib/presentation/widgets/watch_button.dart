import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_theme.dart';
import '../../data/models.dart';
import '../../features/watchlist/watchlist_bloc.dart';

class WatchButton extends StatelessWidget {
  const WatchButton({super.key, required this.show, this.expanded = false});
  final Show show;
  final bool expanded;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WatchlistBloc, WatchlistState>(
        builder: (context, state) {
          final saved = state.contains(show.id);
          final enabled = state.ready && !state.saving;
          void toggle() =>
              context.read<WatchlistBloc>().add(WatchlistToggled(show));
          if (expanded) {
            return SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: enabled ? toggle : null,
                icon: Icon(saved ? Icons.favorite_rounded : Icons.add_rounded),
                label: Text(
                  !state.ready
                      ? 'Watchlist unavailable'
                      : saved
                      ? 'Remove from Watchlist'
                      : 'Add to Watchlist',
                ),
              ),
            );
          }
          return IconButton.filledTonal(
            tooltip: saved
                ? 'Remove ${show.name} from watchlist'
                : 'Save ${show.name} to watchlist',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.background.withValues(alpha: .85),
              foregroundColor: saved ? const Color(0xFFFF718E) : Colors.white,
            ),
            onPressed: enabled ? toggle : null,
            icon: Icon(
              saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
            ),
          );
        },
      );
}
