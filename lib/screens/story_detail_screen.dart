import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../models/story.dart';
import '../models/comment.dart';
import '../services/hackernews_api.dart';

class StoryDetailScreen extends StatefulWidget {
  final Story story;

  const StoryDetailScreen({super.key, required this.story});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final HackerNewsApi _api = HackerNewsApi();
  final ScrollController _commentsScrollController = ScrollController();
  List<Comment> _comments = [];
  List<int> _allCommentIds = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  late WebViewController? _webViewController;
  double _dragExtent = 0.0;
  int _currentPage = 0;
  static const int _pageSize = 20;
  double _leftPanelWidth = 400.0; // Initial width of left panel
  bool _isDraggingDivider = false;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _commentsScrollController.addListener(_onScroll);
    _loadComments();
    _initializeWebView();
  }

  @override
  void dispose() {
    _commentsScrollController.removeListener(_onScroll);
    _commentsScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_commentsScrollController.position.pixels >=
        _commentsScrollController.position.maxScrollExtent - 500) {
      _loadMoreComments();
    }

    // Show/hide scroll to top button
    final showButton = _commentsScrollController.position.pixels > 500;
    if (showButton != _showScrollToTop) {
      setState(() {
        _showScrollToTop = showButton;
      });
    }
  }

  bool get _hasMoreComments => _currentPage * _pageSize < _allCommentIds.length;

  void _scrollToTop() {
    _commentsScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta ?? 0;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragExtent > 100) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragExtent = 0;
      });
    }
  }

  void _initializeWebView() {
    if (widget.story.hasUrl) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Update loading bar if needed
            },
            onPageStarted: (String url) {},
            onPageFinished: (String url) {},
            onWebResourceError: (WebResourceError error) {},
            onNavigationRequest: (NavigationRequest request) {
              // Allow all navigation within the WebView
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.story.url!));
    } else {
      _webViewController = null;
    }
  }

  Future<void> _loadComments() async {
    if (widget.story.kids == null || widget.story.kids!.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      _allCommentIds = widget.story.kids!;
      _currentPage = 0;
      _comments = [];

      // Load first page
      await _loadNextPage();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _allCommentIds.length);

    if (start >= _allCommentIds.length) return;

    final pageIds = _allCommentIds.sublist(start, end);
    final futures = pageIds.map((id) => _api.getComment(id));
    final newComments = await Future.wait(futures);

    _comments.addAll(newComments);
    _currentPage++;
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || !_hasMoreComments) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await _loadNextPage();
      setState(() {
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _loadRepliesRecursively(Comment comment) async {
    if (!comment.hasReplies || comment.replies != null) return;

    comment.isLoadingReplies = true;
    setState(() {});

    try {
      final futures = comment.kids!.map((id) => _api.getComment(id));
      final replies = await Future.wait(futures);
      comment.replies = replies;

      // Don't load nested replies automatically - let user expand them manually
    } catch (e) {
      // Handle error silently
    } finally {
      comment.isLoadingReplies = false;
    }
  }

  Widget _buildCommentTree(Comment comment, ThemeData theme, {int depth = 0}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: depth == 0 ? 18 : 14,
                backgroundColor: depth == 0
                    ? Colors.deepOrange
                    : Colors.deepOrange.withValues(alpha: 0.7),
                child: Text(
                  comment.by.isNotEmpty ? comment.by[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: depth == 0 ? 14 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Comment content
              Expanded(
                child: _buildCommentContent(comment, theme, depth == 0),
              ),
            ],
          ),
          // Render nested replies with indentation
          if (comment.replies != null && comment.replies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 4),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.deepOrange.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  children: comment.replies!
                      .map((reply) => _buildCommentTree(reply, theme, depth: depth + 1))
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentContent(Comment comment, ThemeData theme, bool isRoot) {
    if (comment.deleted || comment.text == null) {
      return const SizedBox.shrink();
    }

    final timestamp = DateTime.fromMillisecondsSinceEpoch(comment.time * 1000);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment header
          Row(
            children: [
              Text(
                comment.by,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeago.format(timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Comment text
          Html(
            data: comment.text!,
            style: {
              "body": Style(
                margin: Margins.all(0),
                padding: HtmlPaddings.all(0),
                fontSize: FontSize(isRoot ? 14 : 13),
              ),
              "p": Style(margin: Margins.all(0), padding: HtmlPaddings.all(0)),
              "a": Style(
                color: Colors.deepOrange,
                textDecoration: TextDecoration.underline,
              ),
            },
            onLinkTap: (url, attributes, element) async {
              if (url != null) {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
          ),

          // Load replies button at the bottom (only show if replies not loaded)
          if (comment.hasReplies && comment.replies == null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: comment.isLoadingReplies
                  ? null
                  : () async {
                      await _loadRepliesRecursively(comment);
                      setState(() {});
                    },
              child: comment.isLoadingReplies
                  ? Shimmer.fromColors(
                      baseColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      highlightColor: theme.colorScheme.surface,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 100,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_comment_outlined,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Load ${comment.kids!.length} ${comment.kids!.length == 1 ? 'reply' : 'replies'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      widget.story.time * 1000,
    );

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: GestureDetector(
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              // AppBar
              Container(
                height: 56,
                decoration: BoxDecoration(color: theme.colorScheme.surface),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.story.hasUrl
                              ? widget.story.domain
                              : 'Discussion',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Split view content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        // Left side - Article info and comments
                        SizedBox(
                          width: _leftPanelWidth.clamp(200.0, constraints.maxWidth - 200.0),
                          child: Stack(
                            children: [
                              CustomScrollView(
                                controller: _commentsScrollController,
                                slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    widget.story.title,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          height: 1.3,
                                        ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Metadata
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 8,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.arrow_upward_rounded,
                                            size: 18,
                                            color: Colors.deepOrange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.story.score} points',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.deepOrange,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.person_outline_rounded,
                                            size: 18,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'by ${widget.story.by}',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 18,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            timeago.format(timestamp),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // URL button
                                  if (widget.story.hasUrl)
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: () =>
                                            _launchUrl(widget.story.url!),
                                        icon: const Icon(
                                          Icons.open_in_new_rounded,
                                        ),
                                        label: const Text('Open in Browser'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.deepOrange,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Story text
                                  if (widget.story.text != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Html(
                                        data: widget.story.text!,
                                        style: {
                                          "body": Style(
                                            margin: Margins.all(0),
                                            padding: HtmlPaddings.all(0),
                                          ),
                                        },
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 24),

                                  // Comments header
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Comments (${widget.story.descendants ?? 0})',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),

                          // Comments list
                          if (_isLoading)
                            const SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            )
                          else if (_error != null)
                            SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    'Failed to load comments',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            )
                          else if (_comments.isEmpty)
                            SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    'No comments yet',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  // Show loading indicator at the bottom if loading more
                                  if (index == _comments.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final comment = _comments[index];
                                  return _buildCommentTree(comment, theme);
                                },
                                childCount:
                                    _comments.length + (_isLoadingMore ? 1 : 0),
                              ),
                            ),
                        ],
                      ),
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: AnimatedSlide(
                                  duration: const Duration(milliseconds: 300),
                                  offset: _showScrollToTop ? Offset.zero : const Offset(0, 2),
                                  curve: Curves.easeOut,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: _showScrollToTop ? 1.0 : 0.0,
                                    child: FloatingActionButton(
                                      onPressed: _scrollToTop,
                                      backgroundColor: Colors.deepOrange,
                                      child: const Icon(Icons.arrow_upward_rounded),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Draggable divider
                        if (widget.story.hasUrl && _webViewController != null)
                          MouseRegion(
                            cursor: SystemMouseCursors.resizeColumn,
                            child: GestureDetector(
                              onHorizontalDragStart: (_) {
                                setState(() {
                                  _isDraggingDivider = true;
                                });
                              },
                              onHorizontalDragUpdate: (details) {
                                setState(() {
                                  _leftPanelWidth = (_leftPanelWidth + details.delta.dx)
                                      .clamp(200.0, constraints.maxWidth - 200.0);
                                });
                              },
                              onHorizontalDragEnd: (_) {
                                setState(() {
                                  _isDraggingDivider = false;
                                });
                              },
                              child: Container(
                                width: 8,
                                decoration: BoxDecoration(
                                  color: _isDraggingDivider
                                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  border: Border(
                                    left: BorderSide(
                                      color: theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Right side - WebView Preview
                        if (widget.story.hasUrl && _webViewController != null)
                          Expanded(
                            child: WebViewWidget(controller: _webViewController!),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
