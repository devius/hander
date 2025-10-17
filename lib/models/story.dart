class Story {
  final int id;
  final String title;
  final String? url;
  final String? text;
  final int score;
  final String by;
  final int time;
  final List<int>? kids;
  final int? descendants;

  Story({
    required this.id,
    required this.title,
    this.url,
    this.text,
    required this.score,
    required this.by,
    required this.time,
    this.kids,
    this.descendants,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      url: json['url'] as String?,
      text: json['text'] as String?,
      score: json['score'] as int? ?? 0,
      by: json['by'] as String? ?? 'unknown',
      time: json['time'] as int? ?? 0,
      kids: json['kids'] != null ? List<int>.from(json['kids']) : null,
      descendants: json['descendants'] as int?,
    );
  }

  String get domain {
    if (url == null) return '';
    try {
      final uri = Uri.parse(url!);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return '';
    }
  }

  bool get hasUrl => url != null && url!.isNotEmpty;
  bool get hasComments => descendants != null && descendants! > 0;
}
