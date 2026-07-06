// MIGRATION: TypeScript `type GeneralSleepData` → Dart class.
//            All fields are `String` to match source type definition and support
//            the EncryptionService which encrypts/decrypts string values.

class GeneralSleepData {
  final String userId;
  final String currentSleepDuration;
  final String snoring;
  final String tirednessFrequency;
  final String daytimeSleepiness;

  const GeneralSleepData({
    required this.userId,
    required this.currentSleepDuration,
    required this.snoring,
    required this.tirednessFrequency,
    required this.daytimeSleepiness,
  });

  GeneralSleepData copyWith({
    String? userId,
    String? currentSleepDuration,
    String? snoring,
    String? tirednessFrequency,
    String? daytimeSleepiness,
  }) =>
      GeneralSleepData(
        userId: userId ?? this.userId,
        currentSleepDuration: currentSleepDuration ?? this.currentSleepDuration,
        snoring: snoring ?? this.snoring,
        tirednessFrequency: tirednessFrequency ?? this.tirednessFrequency,
        daytimeSleepiness: daytimeSleepiness ?? this.daytimeSleepiness,
      );

  factory GeneralSleepData.fromJson(Map<String, dynamic> json) =>
      GeneralSleepData(
        userId: json['userId'] as String,
        currentSleepDuration: json['currentSleepDuration'] as String? ?? '',
        snoring: json['snoring'] as String? ?? '',
        tirednessFrequency: json['tirednessFrequency'] as String? ?? '',
        daytimeSleepiness: json['daytimeSleepiness'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'currentSleepDuration': currentSleepDuration,
        'snoring': snoring,
        'tirednessFrequency': tirednessFrequency,
        'daytimeSleepiness': daytimeSleepiness,
      };
}
