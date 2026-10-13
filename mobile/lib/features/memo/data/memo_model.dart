class Memo {
  final String id;
  final String title;
  final String content;
  final String tag;
  final bool completed;
  final bool starred;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Memo({
    required this.id,
    required this.title,
    this.content = '',
    this.tag = '',
    this.completed = false,
    this.starred = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      starred: json['starred'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Memo copyWith({
    String? title,
    String? content,
    String? tag,
    bool? completed,
    bool? starred,
  }) {
    return Memo(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      tag: tag ?? this.tag,
      completed: completed ?? this.completed,
      starred: starred ?? this.starred,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
