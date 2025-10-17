import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  }

  bool get _hasMoreComments => _currentPage * _pageSize < _allCommentIds.length;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      widget.story.time * 1000,
    );

    return WillPopScope(
      onWillPop: () async => true,
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
                child: Row(
                  children: [
                    // Left side - Article info and comments
                    Expanded(
                      flex: 1,
                      child: CustomScrollView(
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
                                            .withOpacity(0.3),
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
                                  return _CommentCard(
                                    comment: comment,
                                    depth: 0,
                                  );
                                },
                                childCount:
                                    _comments.length + (_isLoadingMore ? 1 : 0),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Right side - WebView Preview (larger)
                    if (widget.story.hasUrl && _webViewController != null)
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: theme.colorScheme.outlineVariant
                                    .withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                          ),
                          child: WebViewWidget(controller: _webViewController!),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final Comment comment;
  final int depth;

  const _CommentCard({required this.comment, required this.depth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = DateTime.fromMillisecondsSinceEpoch(comment.time * 1000);

    if (comment.deleted || comment.text == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(
        left: 16.0 + (depth * 12.0),
        right: 16.0,
        bottom: 12.0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment header
          Row(
            children: [
              Icon(Icons.person_rounded, size: 16, color: Colors.deepOrange),
              const SizedBox(width: 4),
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
                fontSize: FontSize(14),
              ),
              "p": Style(margin: Margins.all(0), padding: HtmlPaddings.all(0)),
            },
          ),
        ],
      ),
    );
  }
}
