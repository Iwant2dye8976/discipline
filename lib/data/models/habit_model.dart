class Habit {
  final int? id;
  final String name;
  final String? description;
  final String frequencyType;
  final bool reminderEnabled;
  final int? reminderHour;
  final int? reminderMinute;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<int> customDays;

  const Habit({
    this.id,
    required this.name,
    this.description,
    required this.frequencyType,
    required this.reminderEnabled,
    this.reminderHour,
    this.reminderMinute,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.customDays = const [],
  });

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    String? frequencyType,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<int>? customDays,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequencyType: frequencyType ?? this.frequencyType,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customDays: customDays ?? this.customDays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'frequency_type': frequencyType,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_hour': reminderHour,
      'reminder_minute': reminderMinute,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(
    Map<String, dynamic> map, {
    List<int> customDays = const [],
  }) {
    return Habit(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      frequencyType: map['frequency_type'] as String,
      reminderEnabled: (map['reminder_enabled'] as int) == 1,
      reminderHour: map['reminder_hour'] as int?,
      reminderMinute: map['reminder_minute'] as int?,
      isArchived: (map['is_archived'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      customDays: customDays,
    );
  }
}
