class Task {
  final int? id;
  final String title;
  final String? description;
  final String? dueDate;
  final String? reminder;
  final String category;
  final bool isDone;
  final String? completedAt;

  const Task({
    this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.reminder,
    required this.category,
    this.isDone = false,
    this.completedAt,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? dueDate,
    String? reminder,
    String? category,
    bool? isDone,
    String? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      reminder: reminder ?? this.reminder,
      category: category ?? this.category,
      isDone: isDone ?? this.isDone,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate,
      'reminder': reminder,
      'category': category,
      'is_done': isDone ? 1 : 0,
      'completed_at': completedAt,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: map['due_date'] as String?,
      reminder: map['reminder'] as String?,
      category: map['category'] as String,
      isDone: (map['is_done'] as int) == 1,
      completedAt: map['completed_at'] as String?,
    );
  }
}
