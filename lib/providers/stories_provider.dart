import 'package:flutter/foundation.dart';
import '../models/story.dart';
import '../services/hackernews_api.dart';

enum StoryType { top, newest, best, ask, show }

class StoriesProvider with ChangeNotifier {
  final HackerNewsApi _api = HackerNewsApi();

  List<Story> _stories = [];
  List<int> _allStoryIds = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  StoryType _currentType = StoryType.top;
  int _currentPage = 0;
  static const int _pageSize = 30;

  List<Story> get stories => _stories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  StoryType get currentType => _currentType;
  bool get hasMore => _currentPage * _pageSize < _allStoryIds.length;

  Future<void> loadStories(StoryType type) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _currentType = type;
    _stories = [];
    _currentPage = 0;
    notifyListeners();

    try {
      switch (type) {
        case StoryType.top:
          _allStoryIds = await _api.getTopStories();
          break;
        case StoryType.newest:
          _allStoryIds = await _api.getNewStories();
          break;
        case StoryType.best:
          _allStoryIds = await _api.getBestStories();
          break;
        case StoryType.ask:
          _allStoryIds = await _api.getAskStories();
          break;
        case StoryType.show:
          _allStoryIds = await _api.getShowStories();
          break;
      }

      // Load first page
      await _loadNextPage();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadNextPage() async {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _allStoryIds.length);

    if (start >= _allStoryIds.length) return;

    final pageIds = _allStoryIds.sublist(start, end);
    final futures = pageIds.map((id) => _api.getStory(id));
    final newStories = await Future.wait(futures);

    _stories.addAll(newStories);
    _currentPage++;
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      await _loadNextPage();
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadStories(_currentType);
  }
}
