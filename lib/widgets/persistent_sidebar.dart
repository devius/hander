import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stories_provider.dart';

class PersistentSidebar extends StatefulWidget {
  const PersistentSidebar({super.key});

  @override
  State<PersistentSidebar> createState() => _PersistentSidebarState();
}

class _PersistentSidebarState extends State<PersistentSidebar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<StoriesProvider>();

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepOrange,
                  Colors.deepOrange.shade700,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Y',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSidebarItem(
                  context,
                  icon: Icons.trending_up_rounded,
                  title: 'Top Stories',
                  subtitle: 'Most popular',
                  type: StoryType.top,
                  isSelected: provider.currentType == StoryType.top,
                ),
                _buildSidebarItem(
                  context,
                  icon: Icons.fiber_new_rounded,
                  title: 'New Stories',
                  subtitle: 'Latest posts',
                  type: StoryType.newest,
                  isSelected: provider.currentType == StoryType.newest,
                ),
                _buildSidebarItem(
                  context,
                  icon: Icons.star_rounded,
                  title: 'Best Stories',
                  subtitle: 'Highest rated',
                  type: StoryType.best,
                  isSelected: provider.currentType == StoryType.best,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context,
                  icon: Icons.question_answer_rounded,
                  title: 'Ask HN',
                  subtitle: 'Q&A',
                  type: StoryType.ask,
                  isSelected: provider.currentType == StoryType.ask,
                ),
                _buildSidebarItem(
                  context,
                  icon: Icons.lightbulb_rounded,
                  title: 'Show HN',
                  subtitle: 'Projects',
                  type: StoryType.show,
                  isSelected: provider.currentType == StoryType.show,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required StoryType type,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? Colors.deepOrange.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: InkWell(
        onTap: () {
          context.read<StoriesProvider>().loadStories(type);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.deepOrange : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                _getShortLabel(type),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: isSelected ? Colors.deepOrange : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getShortLabel(StoryType type) {
    switch (type) {
      case StoryType.top:
        return 'Top';
      case StoryType.newest:
        return 'New';
      case StoryType.best:
        return 'Best';
      case StoryType.ask:
        return 'Ask';
      case StoryType.show:
        return 'Show';
    }
  }
}
