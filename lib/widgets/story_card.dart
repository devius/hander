import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/story.dart';

class StoryCard extends StatelessWidget {
  final Story story;
  final VoidCallback onTap;

  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = DateTime.fromMillisecondsSinceEpoch(story.time * 1000);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                story.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),

              // Domain chip with favicon
              if (story.hasUrl)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Favicon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        'https://www.google.com/s2/favicons?domain=${story.domain}&sz=32',
                        width: 16,
                        height: 16,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.language,
                            size: 16,
                            color: theme.colorScheme.onPrimaryContainer,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            width: 16,
                            height: 16,
                            child: Center(
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Domain pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        story.domain,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // Metadata row
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildMetaChip(
                    context,
                    Icons.arrow_upward_rounded,
                    '${story.score}',
                    theme.colorScheme.primary,
                  ),
                  _buildMetaChip(
                    context,
                    Icons.person_outline_rounded,
                    story.by,
                    theme.colorScheme.onSurfaceVariant,
                  ),
                  _buildMetaChip(
                    context,
                    Icons.access_time_rounded,
                    timeago.format(timestamp),
                    theme.colorScheme.onSurfaceVariant,
                  ),
                  if (story.hasComments)
                    _buildMetaChip(
                      context,
                      Icons.chat_bubble_outline_rounded,
                      '${story.descendants}',
                      theme.colorScheme.secondary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
