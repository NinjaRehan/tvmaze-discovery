import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_theme.dart';
import '../../core/load_status.dart';
import '../../features/search/search_bloc.dart';
import '../widgets/common.dart';
import '../widgets/show_widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          eyebrow: 'Find something great',
          title: 'Search shows',
        ),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onChanged: (query) {
            setState(() {});
            context.read<SearchBloc>().add(SearchQueryChanged(query));
          },
          decoration: InputDecoration(
            hintText: 'Search by show name…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _controller.clear();
                      setState(() {});
                      context.read<SearchBloc>().add(SearchQueryChanged(''));
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              switch (state.status) {
                case LoadStatus.initial:
                  return const SingleChildScrollView(
                    child: StatusPanel(
                      title: 'Every great story starts here',
                      message:
                          'Search for a show you love, or discover something new.',
                      icon: Icons.manage_search_rounded,
                    ),
                  );
                case LoadStatus.loading:
                  return const Center(child: CircularProgressIndicator());
                case LoadStatus.empty:
                  return SingleChildScrollView(
                    child: StatusPanel(
                      title: 'No matches found',
                      message:
                          'We couldn’t find “${state.query}”. Try a different title or check your spelling.',
                      icon: Icons.search_off_rounded,
                    ),
                  );
                case LoadStatus.failure:
                  return SingleChildScrollView(
                    child: StatusPanel(
                      title: 'Search unavailable',
                      message: state.error!,
                      action: () =>
                          context.read<SearchBloc>().add(SearchRetried()),
                    ),
                  );
                case LoadStatus.success:
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.shows.length} results for “${state.query}”',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          key: ValueKey(state.query),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: state.shows.length,
                          separatorBuilder: (_, index) =>
                              const Divider(height: 1),
                          itemBuilder: (_, index) =>
                              ShowTile(show: state.shows[index]),
                        ),
                      ),
                    ],
                  );
              }
            },
          ),
        ),
      ],
    ),
  );
}
