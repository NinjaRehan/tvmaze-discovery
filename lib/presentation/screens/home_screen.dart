import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_theme.dart';
import '../../features/watchlist/watchlist_bloc.dart';
import '../widgets/common.dart';
import 'discover_screen.dart';
import 'search_screen.dart';
import 'watchlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<WatchlistBloc, WatchlistState>(
    listenWhen: (old, next) => next.error != null && old.error != next.error,
    listener: (context, state) {
      if (ModalRoute.of(context)?.isCurrent ?? true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    },
    child: Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: IndexedStack(
            index: _index,
            children: [
              DiscoverScreen(onSearch: () => setState(() => _index = 1)),
              const SearchScreen(),
              WatchlistScreen(onExplore: () => setState(() => _index = 0)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppTheme.purple
                : AppTheme.muted,
          ),
        ),
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppTheme.muted),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.purple),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded, color: AppTheme.muted),
            selectedIcon: Icon(Icons.search_rounded, color: AppTheme.purple),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded, color: AppTheme.muted),
            selectedIcon: Icon(Icons.favorite_rounded, color: AppTheme.purple),
            label: 'Watchlist',
          ),
        ],
      ),
    ),
  );
}
