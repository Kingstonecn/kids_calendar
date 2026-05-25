class Schedule {
  int? id;
  String title;
  String description;
  String date; // 'yyyy-MM-dd'
  String? startTime; // 'HH:mm'
  String? endTime; // 'HH:mm'
  String category;
  int colorIndex;
  bool isRepeating;
  String? repeatRule; // JSON: {type, interval, weekdays, endDate}
  bool hasAlarm;
  int? alarmMinutesBefore;
  int? sourceId; // 来源日程ID（复制关联）
  bool isCompleted;
  String? appPackageName; // 关联的App包名, 如 "com.tencent.mm"
  String? appName; // 关联的App名称, 如 "微信"
  String createdAt;
  String updatedAt;

  Schedule({
    this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.startTime,
    this.endTime,
    this.category = '其他',
    this.colorIndex = 0,
    this.isRepeating = false,
    this.repeatRule,
    this.hasAlarm = false,
    this.alarmMinutesBefore,
    this.sourceId,
    this.isCompleted = false,
    this.appPackageName,
    this.appName,
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'category': category,
      'color_index': colorIndex,
      'is_repeating': isRepeating ? 1 : 0,
      'repeat_rule': repeatRule,
      'has_alarm': hasAlarm ? 1 : 0,
      'alarm_minutes_before': alarmMinutesBefore,
      'source_id': sourceId,
      'is_completed': isCompleted ? 1 : 0,
      'app_package_name': appPackageName,
      'app_name': appName,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      date: map['date'] as String,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      category: (map['category'] as String?) ?? '其他',
      colorIndex: (map['color_index'] as int?) ?? 0,
      isRepeating: (map['is_repeating'] as int?) == 1,
      repeatRule: map['repeat_rule'] as String?,
      hasAlarm: (map['has_alarm'] as int?) == 1,
      alarmMinutesBefore: map['alarm_minutes_before'] as int?,
      sourceId: map['source_id'] as int?,
      isCompleted: (map['is_completed'] as int?) == 1,
      appPackageName: map['app_package_name'] as String?,
      appName: map['app_name'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Schedule copyWith({
    int? id,
    String? title,
    String? description,
    String? date,
    String? startTime,
    String? endTime,
    String? category,
    int? colorIndex,
    bool? isRepeating,
    String? repeatRule,
    bool? hasAlarm,
    int? alarmMinutesBefore,
    int? sourceId,
    bool? isCompleted,
    String? appPackageName,
    String? appName,
    String? createdAt,
    String? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      colorIndex: colorIndex ?? this.colorIndex,
      isRepeating: isRepeating ?? this.isRepeating,
      repeatRule: repeatRule ?? this.repeatRule,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      alarmMinutesBefore: alarmMinutesBefore ?? this.alarmMinutesBefore,
      sourceId: sourceId ?? this.sourceId,
      isCompleted: isCompleted ?? this.isCompleted,
      appPackageName: appPackageName ?? this.appPackageName,
      appName: appName ?? this.appName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'category': category,
      'colorIndex': colorIndex,
      'isRepeating': isRepeating,
      'repeatRule': repeatRule,
      'hasAlarm': hasAlarm,
      'alarmMinutesBefore': alarmMinutesBefore,
      'sourceId': sourceId,
      'isCompleted': isCompleted,
      'appPackageName': appPackageName,
      'appName': appName,
    };
  }
}
