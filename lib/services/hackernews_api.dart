import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/story.dart';
import '../models/comment.dart';

class HackerNewsApi {
  static const String baseUrl = 'https://hacker-news.firebaseio.com/v0';

  Future<List<int>> getTopStories() async {
    final response = await http.get(Uri.parse('$baseUrl/topstories.json'));
    if (response.statusCode == 200) {
      return List<int>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load top stories');
    }
  }

  Future<List<int>> getNewStories() async {
    final response = await http.get(Uri.parse('$baseUrl/newstories.json'));
    if (response.statusCode == 200) {
      return List<int>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load new stories');
    }
  }

  Future<List<int>> getBestStories() async {
    final response = await http.get(Uri.parse('$baseUrl/beststories.json'));
    if (response.statusCode == 200) {
      return List<int>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load best stories');
    }
  }

  Future<List<int>> getAskStories() async {
    final response = await http.get(Uri.parse('$baseUrl/askstories.json'));
    if (response.statusCode == 200) {
      return List<int>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load ask stories');
    }
  }

  Future<List<int>> getShowStories() async {
    final response = await http.get(Uri.parse('$baseUrl/showstories.json'));
    if (response.statusCode == 200) {
      return List<int>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load show stories');
    }
  }

  Future<Story> getStory(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/item/$id.json'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data == null) {
        throw Exception('Story not found');
      }
      return Story.fromJson(data);
    } else {
      throw Exception('Failed to load story');
    }
  }

  Future<Comment> getComment(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/item/$id.json'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data == null) {
        throw Exception('Comment not found');
      }
      return Comment.fromJson(data);
    } else {
      throw Exception('Failed to load comment');
    }
  }
}
