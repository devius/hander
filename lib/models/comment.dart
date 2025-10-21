class Comment {
  final int id;
  final String? text;
  final String by;
  final int time;
  final List<int>? kids;
  final int parent;
  final bool deleted;
  List<Comment>? replies; // For storing loaded nested comments
  bool isLoadingReplies = false; // Track loading state

  Comment({
    required this.id,
    this.text,
    required this.by,
    required this.time,
    this.kids,
    required this.parent,
    this.deleted = false,
    this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      text: json['text'] as String?,
      by: json['by'] as String? ?? 'deleted',
      time: json['time'] as int? ?? 0,
      kids: json['kids'] != null ? List<int>.from(json['kids']) : null,
      parent: json['parent'] as int,
      deleted: json['deleted'] as bool? ?? false,
    );
  }

  bool get hasReplies => kids != null && kids!.isNotEmpty;
}
