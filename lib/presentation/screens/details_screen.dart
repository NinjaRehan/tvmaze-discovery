import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../core/load_status.dart';
import '../../data/models.dart';
import '../../data/tvmaze_repository.dart';
import '../../features/details/details_bloc.dart';
import '../../features/watchlist/watchlist_bloc.dart';
import '../widgets/common.dart';
import '../widgets/watch_button.dart';

void openDetails(BuildContext context, Show show) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => DetailsBloc(context.read<ShowRepository>(), show)
          ..add(DetailsRequested())
          ..add(CastRequested())
          ..add(EpisodesRequested()),
        child: const DetailsScreen(),
      ),
    ),
  );
}

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocListener<WatchlistBloc, WatchlistState>(
        listenWhen: (old, next) =>
            next.error != null && old.error != next.error,
        listener: (context, state) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!))),
        child: BlocBuilder<DetailsBloc, DetailsState>(
          builder: (context, state) => DefaultTabController(
            length: 3,
            child: Scaffold(
              body: SafeArea(
                child: ContentWidth(
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverToBoxAdapter(child: _Header(state: state)),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _TabHeader(),
                      ),
                    ],
                    body: TabBarView(
                      children: [
                        _Overview(state: state),
                        _Episodes(state: state),
                        _Cast(state: state),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.state});
  final DetailsState state;
  @override
  Widget build(BuildContext context) {
    final show = state.show;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 270,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Poster(url: show.originalImageUrl ?? show.imageUrl, radius: 0),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x440C0D16),
                      Color(0x220C0D16),
                      AppTheme.background,
                    ],
                    stops: [0, .35, 1],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 12,
                child: IconButton.filledTonal(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              Positioned(top: 10, right: 12, child: WatchButton(show: show)),
              Positioned(
                left: 22,
                right: 22,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TVMAZE / SHOW DETAILS',
                      style: TextStyle(
                        color: Color(0xFFCCB6FF),
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      show.name,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Text(
                          show.years,
                          style: const TextStyle(color: AppTheme.muted),
                        ),
                        RatingBadge(rating: show.rating),
                        if (show.runtime != null)
                          Text(
                            '${show.runtime} min',
                            style: const TextStyle(color: AppTheme.muted),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (show.genres.isNotEmpty)
                Wrap(
                  spacing: 7,
                  runSpacing: 2,
                  children: show.genres
                      .map(
                        (genre) => Chip(
                          label: Text(
                            genre,
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              if (show.summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  show.summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFCDCBDA),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              WatchButton(show: show, expanded: true),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabHeader extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;
  @override
  bool shouldRebuild(covariant _TabHeader oldDelegate) => false;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(
    // Persistent headers must paint the full extent they advertise, even
    // when their child's natural height (48 for this TabBar) is smaller.
    height: maxExtent,
    child: const ColoredBox(
      color: AppTheme.background,
      child: TabBar(
        indicatorColor: AppTheme.purple,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.muted,
        dividerColor: Color(0xFF28293B),
        tabs: [
          Tab(text: 'Overview'),
          Tab(text: 'Episodes'),
          Tab(text: 'Cast'),
        ],
      ),
    ),
  );
}

class _Overview extends StatelessWidget {
  const _Overview({required this.state});
  final DetailsState state;
  @override
  Widget build(BuildContext context) {
    final show = state.show;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        if (state.status == LoadStatus.loading)
          const LinearProgressIndicator(minHeight: 2),
        if (state.status == LoadStatus.failure)
          InlineError(
            message: state.error!,
            retry: () => context.read<DetailsBloc>().add(DetailsRequested()),
          ),
        Text('Quick info', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.radio_button_checked_rounded,
                title: 'Status',
                value: show.status,
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.live_tv_rounded,
                title: 'Network',
                value: show.network,
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.language_rounded,
                title: 'Language',
                value: show.language,
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.category_outlined,
                title: 'Genres',
                value: show.genres.isEmpty ? 'Unknown' : show.genres.join(', '),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('The story', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SelectableText(
          show.summary.isEmpty
              ? 'No summary is available for this show yet.'
              : show.summary,
          style: const TextStyle(
            color: Color(0xFFCDCBDA),
            height: 1.7,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 28),
        const SizedBox(height: 18),
        TextButton.icon(
          onPressed: () => _openSource(context, show.url),
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: const Text('Show information by TVMaze'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _openSource(BuildContext context, String? url) async {
    final uri = Uri.tryParse(url ?? 'https://www.tvmaze.com');
    try {
      if (uri == null ||
          uri.scheme != 'https' ||
          !(uri.host == 'www.tvmaze.com' || uri.host == 'tvmaze.com')) {
        throw const FormatException('Invalid source link');
      }
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw const FormatException('Cannot open source');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open TVMaze in your browser.'),
          ),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Row(
      children: [
        Icon(icon, color: AppTheme.muted, size: 18),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _Cast extends StatelessWidget {
  const _Cast({required this.state});
  final DetailsState state;
  @override
  Widget build(BuildContext context) {
    if (state.castStatus == LoadStatus.loading ||
        state.castStatus == LoadStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.castStatus == LoadStatus.failure) {
      return ListView(
        children: [
          StatusPanel(
            title: 'Cast unavailable',
            message: state.castError!,
            action: () => context.read<DetailsBloc>().add(CastRequested()),
          ),
        ],
      );
    }
    if (state.cast.isEmpty) {
      return ListView(
        children: const [
          StatusPanel(
            title: 'No cast listed',
            message: 'Cast information hasn’t been added for this show yet.',
            icon: Icons.people_outline_rounded,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      itemCount: state.cast.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final member = state.cast[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Poster(
                url: member.imageUrl,
                width: 58,
                height: 70,
                radius: 12,
                label: member.name,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'as ${member.character}',
                      style: const TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Episodes extends StatefulWidget {
  const _Episodes({required this.state});
  final DetailsState state;
  @override
  State<_Episodes> createState() => _EpisodesState();
}

class _EpisodesState extends State<_Episodes> {
  int? _season;
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state.episodesStatus == LoadStatus.loading ||
        state.episodesStatus == LoadStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.episodesStatus == LoadStatus.failure) {
      return ListView(
        children: [
          StatusPanel(
            title: 'Episodes unavailable',
            message: state.episodesError!,
            action: () => context.read<DetailsBloc>().add(EpisodesRequested()),
          ),
        ],
      );
    }
    final seasons = state.seasons;
    if (seasons.isEmpty) {
      return ListView(
        children: const [
          StatusPanel(
            title: 'No episodes listed',
            message: 'Episode information hasn’t been added for this show yet.',
            icon: Icons.video_library_outlined,
          ),
        ],
      );
    }
    final selected = seasons.containsKey(_season)
        ? _season!
        : seasons.keys.first;
    final episodes = seasons[selected]!;
    return ListView.builder(
      padding: const EdgeInsets.all(22),
      itemCount: episodes.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DropdownButtonFormField<int>(
              key: ValueKey(selected),
              initialValue: selected,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Season'),
              items: seasons.keys
                  .map(
                    (season) => DropdownMenuItem(
                      value: season,
                      child: Text(
                        '${season == 0 ? 'Specials' : 'Season $season'} (${seasons[season]!.length} episodes)',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _season = value),
            ),
          );
        }
        final episode = episodes[index - 1];
        return Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              leading: Stack(
                children: [
                  Poster(
                    url: episode.imageUrl,
                    width: 82,
                    height: 56,
                    radius: 8,
                  ),
                  Positioned(
                    right: 3,
                    bottom: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${episode.number ?? 'S'}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                episode.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                [
                  if (episode.airdate?.isNotEmpty ?? false) episode.airdate!,
                  if (episode.runtime != null) '${episode.runtime} min',
                ].join(' · '),
                style: const TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
              trailing: const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppTheme.muted,
              ),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      0,
                      24,
                      28 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          episode.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          episode.summary.isEmpty
                              ? 'No episode summary is available.'
                              : episode.summary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}
