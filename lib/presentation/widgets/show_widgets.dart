import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/watchlist/watchlist_bloc.dart';
import '../../core/app_theme.dart';
import '../../data/models.dart';
import '../screens/details_screen.dart';
import 'common.dart';
import 'watch_button.dart';

class ShowCard extends StatelessWidget {
  const ShowCard({super.key, required this.show});
  final Show show;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Material(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => openDetails(context, show),
                child: Poster(url: show.imageUrl, label: '${show.name} poster'),
              ),
            ),
            Positioned(top: 5, right: 5, child: WatchButton(show: show)),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.background.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: RatingBadge(rating: show.rating),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 9),
      InkWell(
        onTap: () => openDetails(context, show),
        child: Text(
          show.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      const SizedBox(height: 3),
      Text(
        show.genres.isEmpty
            ? 'Genres unavailable'
            : show.genres.take(2).join(' · '),
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

class ShowTile extends StatelessWidget {
  const ShowTile({super.key, required this.show, this.showWatchButton = false});
  final Show show;
  final bool showWatchButton;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => openDetails(context, show),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Poster(
                url: show.imageUrl,
                width: 66,
                height: 94,
                radius: 10,
                label: '${show.name} poster',
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      show.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      show.years,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      show.genres.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 5),
                    RatingBadge(rating: show.rating),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (showWatchButton)
                WatchButton(show: show)
              else
                const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    ),
  );
}

class ShowShelf extends StatelessWidget {
  const ShowShelf({super.key, required this.title, required this.shows});
  final String title;
  final List<Show> shows;

  @override
  Widget build(BuildContext context) {
    if (shows.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = ((constraints.maxWidth - 28) / 3)
            .clamp(95.0, 150.0)
            .toDouble();
        final cardHeight = cardWidth * 1.45 + 54;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          BlocListener<WatchlistBloc, WatchlistState>(
                            listenWhen: (old, next) =>
                                next.error != null && old.error != next.error,
                            listener: (context, state) {
                              if (ModalRoute.of(context)?.isCurrent ?? true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(state.error!)),
                                );
                              }
                            },
                            child: Scaffold(
                              appBar: AppBar(title: Text(title)),
                              body: ContentWidth(
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  itemCount: shows.length,
                                  separatorBuilder: (_, index) =>
                                      const Divider(height: 1),
                                  itemBuilder: (_, index) =>
                                      ShowTile(show: shows[index]),
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('See all', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: cardHeight,
              child: ListView.separated(
                key: PageStorageKey('shelf-$title'),
                scrollDirection: Axis.horizontal,
                itemCount: shows.length,
                separatorBuilder: (_, index) => const SizedBox(width: 14),
                itemBuilder: (_, index) => SizedBox(
                  width: cardWidth,
                  child: ShowCard(show: shows[index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
