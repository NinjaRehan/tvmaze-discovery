import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_theme.dart';
import '../../core/load_status.dart';
import '../../features/discover/discover_bloc.dart';
import '../widgets/common.dart';
import '../widgets/show_widgets.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, required this.onSearch});
  final VoidCallback onSearch;
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final bloc = context.read<DiscoverBloc>();
    if (_scroll.position.extentAfter < 550 &&
        !bloc.state.loadingMore &&
        bloc.state.moreError == null) {
      bloc.add(DiscoverMoreRequested());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<DiscoverBloc, DiscoverState>(
    builder: (context, state) {
      final bloc = context.read<DiscoverBloc>();
      if (state.shows.isEmpty &&
          (state.status == LoadStatus.loading ||
              state.status == LoadStatus.initial)) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.status == LoadStatus.failure ||
          state.status == LoadStatus.empty) {
        return StatusPanel(
          title: state.status == LoadStatus.empty
              ? 'No shows yet'
              : 'Connection interrupted',
          message: state.error ?? 'TVMaze has no shows to display right now.',
          action: () => bloc.add(DiscoverRequested()),
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          bloc.add(DiscoverRefreshed());
          await bloc.stream.firstWhere(
            (value) => value.status != LoadStatus.loading,
          );
        },
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          key: const PageStorageKey('discover-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 22, bottom: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hello,',
                                  style: TextStyle(
                                    color: AppTheme.muted,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'TV Explorer! 👋',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'About TVMaze',
                            onPressed: () => showAboutDialog(
                              context: context,
                              applicationName: 'TVMaze Discovery',
                              applicationVersion: '1.0.0',
                              applicationIcon: const Icon(
                                Icons.live_tv_rounded,
                                color: AppTheme.purple,
                                size: 36,
                              ),
                              children: const [
                                Text(
                                  'Discover. Explore. Save.\nShow information provided by TVMaze.\nCS4039 · Assignment 02',
                                ),
                              ],
                            ),
                            icon: const Icon(Icons.settings_outlined, size: 20),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Search shows',
                      child: InkWell(
                        onTap: widget.onSearch,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF303148)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: AppTheme.muted,
                                size: 19,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Search shows...',
                                style: TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ShowShelf(
                      title: 'Featured Shows',
                      shows: state.featuredShows,
                    ),
                    const SizedBox(height: 20),
                    ShowShelf(title: 'Top Rated', shows: state.topRatedShows),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Explore the collection',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Text(
                          '${state.shows.length} shows',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'A world of stories, one show at a time.',
                      style: TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    if (state.error != null)
                      InlineError(
                        message: state.error!,
                        retry: () => bloc.add(DiscoverRefreshed()),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.crossAxisExtent >= 850
                      ? 5
                      : constraints.crossAxisExtent >= 600
                      ? 4
                      : constraints.crossAxisExtent >= 430
                      ? 3
                      : 2;
                  final width =
                      (constraints.crossAxisExtent - (columns - 1) * 14) /
                      columns;
                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ShowCard(show: state.shows[index]),
                      childCount: state.shows.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 22,
                      mainAxisExtent: width * 1.45 + 58,
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: state.loadingMore || state.status == LoadStatus.loading
                    ? const Center(child: CircularProgressIndicator())
                    : state.moreError != null
                    ? InlineError(
                        message: state.moreError!,
                        retry: () => bloc.add(DiscoverMoreRequested()),
                      )
                    : state.hasMore
                    ? Center(
                        child: TextButton.icon(
                          onPressed: () => bloc.add(DiscoverMoreRequested()),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Load more shows'),
                        ),
                      )
                    : const Center(
                        child: Text(
                          'You’ve reached the end of the collection.',
                          style: TextStyle(color: AppTheme.muted),
                        ),
                      ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Center(
                  child: Text(
                    'Show information provided by TVMaze',
                    style: TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
