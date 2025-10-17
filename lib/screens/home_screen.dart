import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/stories_provider.dart';
import '../widgets/story_card.dart';
import '../widgets/story_card_shimmer.dart';
import '../widgets/persistent_sidebar.dart';
import 'story_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoriesProvider>().loadStories(StoryType.top);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      context.read<StoriesProvider>().loadMore();
    }
  }

  String _getCategoryTitle(StoryType type) {
    switch (type) {
      case StoryType.top:
        return 'Top Stories';
      case StoryType.newest:
        return 'New Stories';
      case StoryType.best:
        return 'Best Stories';
      case StoryType.ask:
        return 'Ask HN';
      case StoryType.show:
        return 'Show HN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Persistent Sidebar
          const PersistentSidebar(),

          // Main Content
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [_buildAppBar(context), _buildStoryList(context)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<StoriesProvider>();

    return SliverAppBar(
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      title: Text(
        _getCategoryTitle(provider.currentType),
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => provider.refresh(),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStoryList(BuildContext context) {
    final provider = context.watch<StoriesProvider>();

    if (provider.isLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const StoryCardShimmer(),
          childCount: 10,
        ),
      );
    }

    if (provider.error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load stories',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => provider.refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.stories.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No stories found')),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Show loading indicator at the bottom if loading more
          if (index == provider.stories.length) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final story = provider.stories[index];
          return StoryCard(
            story: story,
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => StoryDetailScreen(story: story),
                ),
              );
            },
          );
        },
        childCount: provider.stories.length + (provider.isLoadingMore ? 1 : 0),
      ),
    );
  }
}
