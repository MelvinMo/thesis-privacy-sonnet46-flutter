// MIGRATION: TypeScript `type JournalData` + `type SleepNote` → Dart.
//            SleepNote string literal union → Dart enum with toJson()/fromJson().

// MIGRATION: TypeScript string union `"Pain" | "Stress" | ...` → Dart enum.
//            Enum .name matches the JSON/DB string values exactly.
enum SleepNote {
  pain,
  stress,
  anxiety,
  medication,
  caffeine,
  alcohol,
  warmBath,
  heavyMeal,
}

extension SleepNoteJson on SleepNote {
  String toJson() {
    const m = {
      SleepNote.pain: 'Pain',
      SleepNote.stress: 'Stress',
      SleepNote.anxiety: 'Anxiety',
      SleepNote.medication: 'Medication',
      SleepNote.caffeine: 'Caffeine',
      SleepNote.alcohol: 'Alcohol',
      SleepNote.warmBath: 'Warm Bath',
      SleepNote.heavyMeal: 'Heavy Meal',
    };
    return m[this]!;
  }

  static SleepNote fromJson(String v) {
    const m = {
      'Pain': SleepNote.pain,
      'Stress': SleepNote.stress,
      'Anxiety': SleepNote.anxiety,
      'Medication': SleepNote.medication,
      'Caffeine': SleepNote.caffeine,
      'Alcohol': SleepNote.alcohol,
      'Warm Bath': SleepNote.warmBath,
      'Heavy Meal': SleepNote.heavyMeal,
    };
    return m[v] ?? SleepNote.stress;
  }
}

// ---------------------------------------------------------------------------

class JournalData {
  final String date;       // ISO date string (YYYY-MM-DD)
  final String userId;
  final String journalId;
  final String bedtime;
  final String alarmTime;
  final String sleepDuration;
  final String diaryEntry;
  // MIGRATION: `sleepNotes: SleepNote[]` kept as List<SleepNote>.
  //            SQLite stores as JSON string (same as source: `sleepNotes TEXT`).
  final List<SleepNote> sleepNotes;

  const JournalData({
    required this.date,
    required this.userId,
    required this.journalId,
    required this.bedtime,
    required this.alarmTime,
    required this.sleepDuration,
    required this.diaryEntry,
    this.sleepNotes = const [],
  });

  JournalData copyWith({
    String? date,
    String? userId,
    String? journalId,
    String? bedtime,
    String? alarmTime,
    String? sleepDuration,
    String? diaryEntry,
    List<SleepNote>? sleepNotes,
  }) =>
      JournalData(
        date: date ?? this.date,
        userId: userId ?? this.userId,
        journalId: journalId ?? this.journalId,
        bedtime: bedtime ?? this.bedtime,
        alarmTime: alarmTime ?? this.alarmTime,
        sleepDuration: sleepDuration ?? this.sleepDuration,
        diaryEntry: diaryEntry ?? this.diaryEntry,
        sleepNotes: sleepNotes ?? this.sleepNotes,
      );

  factory JournalData.fromJson(Map<String, dynamic> json) {
    // MIGRATION: sleepNotes stored as JSON string in SQLite; parse both forms.
    List<SleepNote> notes = [];
    final raw = json['sleepNotes'];
    if (raw is List) {
      notes = raw.map((e) => SleepNoteJson.fromJson(e as String)).toList();
    } else if (raw is String && raw.isNotEmpty) {
      // Stored as JSON string in SQLite (same as source `sleepNotes TEXT`)
      final decoded = raw.replaceAll('[', '').replaceAll(']', '')
          .replaceAll('"', '').split(',');
      notes = decoded
          .where((s) => s.trim().isNotEmpty)
          .map((s) => SleepNoteJson.fromJson(s.trim()))
          .toList();
    }
    return JournalData(
      date: json['date'] as String,
      userId: json['userId'] as String,
      journalId: json['journalId'] as String,
      bedtime: json['bedtime'] as String? ?? '',
      alarmTime: json['alarmTime'] as String? ?? '',
      sleepDuration: json['sleepDuration'] as String? ?? '',
      diaryEntry: json['diaryEntry'] as String? ?? '',
      sleepNotes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'userId': userId,
        'journalId': journalId,
        'bedtime': bedtime,
        'alarmTime': alarmTime,
        'sleepDuration': sleepDuration,
        'diaryEntry': diaryEntry,
        'sleepNotes': sleepNotes.map((n) => n.toJson()).toList(),
      };

  // Serialised sleepNotes for SQLite (JSON string, same as source).
  String get sleepNotesJson =>
      '[${sleepNotes.map((n) => '"${n.toJson()}"').join(',')}]';
}
