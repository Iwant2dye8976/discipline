class HabitCompletion {
  final int? id;
  final int habitId;
  final String completionDate;
  final DateTime completedAt;

  const HabitCompletion({
    this.id,
    required this.habitId,
    required this.completionDate,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'completion_date': completionDate,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  factory HabitCompletion.fromMap(Map<String, dynamic> map) {
    return HabitCompletion(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      completionDate: map['completion_date'] as String,
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }
}
