import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stories_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<StoriesProvider>();

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Y',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hacker News',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reader',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.trending_up_rounded,
                  title: 'Top Stories',
                  subtitle: 'Most popular posts',
                  type: StoryType.top,
                  isSelected: provider.currentType == StoryType.top,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.fiber_new_rounded,
                  title: 'New Stories',
                  subtitle: 'Latest submissions',
                  type: StoryType.newest,
                  isSelected: provider.currentType == StoryType.newest,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.star_rounded,
                  title: 'Best Stories',
                  subtitle: 'Highest rated',
                  type: StoryType.best,
                  isSelected: provider.currentType == StoryType.best,
                ),
                const Divider(height: 24),
                _buildDrawerItem(
                  context,
                  icon: Icons.question_answer_rounded,
                  title: 'Ask HN',
                  subtitle: 'Questions & answers',
                  type: StoryType.ask,
                  isSelected: provider.currentType == StoryType.ask,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.lightbulb_rounded,
                  title: 'Show HN',
                  subtitle: 'Show off your projects',
                  type: StoryType.show,
                  isSelected: provider.currentType == StoryType.show,
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Built with Flutter',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required StoryType type,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? Colors.deepOrange.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.deepOrange
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.deepOrange : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: isSelected
            ? const Icon(
                Icons.check_circle_rounded,
                color: Colors.deepOrange,
                size: 20,
              )
            : null,
        onTap: () {
          context.read<StoriesProvider>().loadStories(type);
          Navigator.pop(context);
        },
      ),
    );
  }
}
