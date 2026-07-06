// MIGRATION: TypeScript `type UserConsentPreferences` → Dart class.
//            All defaults are `false` matching the source opt-in model.
//            Persisted via SharedPreferences (replaces AsyncStorage).

class UserConsentPreferences {
  final bool accelerometerEnabled;
  final bool lightSensorEnabled;
  final bool microphoneEnabled;
  final bool cloudStorageEnabled;
  final bool agreedToPrivacyPolicy;
  final bool analyticsEnabled;
  final bool marketingCommunications;
  final bool notificationsEnabled;

  const UserConsentPreferences({
    this.accelerometerEnabled = false,
    this.lightSensorEnabled = false,
    this.microphoneEnabled = false,
    this.cloudStorageEnabled = false,
    this.agreedToPrivacyPolicy = false,
    this.analyticsEnabled = false,
    this.marketingCommunications = false,
    this.notificationsEnabled = false,
  });

  // MIGRATION: Zustand store default matches these defaults (all false = opt-in).
  static const defaults = UserConsentPreferences();

  UserConsentPreferences copyWith({
    bool? accelerometerEnabled,
    bool? lightSensorEnabled,
    bool? microphoneEnabled,
    bool? cloudStorageEnabled,
    bool? agreedToPrivacyPolicy,
    bool? analyticsEnabled,
    bool? marketingCommunications,
    bool? notificationsEnabled,
  }) =>
      UserConsentPreferences(
        accelerometerEnabled: accelerometerEnabled ?? this.accelerometerEnabled,
        lightSensorEnabled: lightSensorEnabled ?? this.lightSensorEnabled,
        microphoneEnabled: microphoneEnabled ?? this.microphoneEnabled,
        cloudStorageEnabled: cloudStorageEnabled ?? this.cloudStorageEnabled,
        agreedToPrivacyPolicy: agreedToPrivacyPolicy ?? this.agreedToPrivacyPolicy,
        analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
        marketingCommunications: marketingCommunications ?? this.marketingCommunications,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );

  factory UserConsentPreferences.fromJson(Map<String, dynamic> json) =>
      UserConsentPreferences(
        accelerometerEnabled: json['accelerometerEnabled'] as bool? ?? false,
        lightSensorEnabled: json['lightSensorEnabled'] as bool? ?? false,
        microphoneEnabled: json['microphoneEnabled'] as bool? ?? false,
        cloudStorageEnabled: json['cloudStorageEnabled'] as bool? ?? false,
        agreedToPrivacyPolicy: json['agreedToPrivacyPolicy'] as bool? ?? false,
        analyticsEnabled: json['analyticsEnabled'] as bool? ?? false,
        marketingCommunications: json['marketingCommunications'] as bool? ?? false,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'accelerometerEnabled': accelerometerEnabled,
        'lightSensorEnabled': lightSensorEnabled,
        'microphoneEnabled': microphoneEnabled,
        'cloudStorageEnabled': cloudStorageEnabled,
        'agreedToPrivacyPolicy': agreedToPrivacyPolicy,
        'analyticsEnabled': analyticsEnabled,
        'marketingCommunications': marketingCommunications,
        'notificationsEnabled': notificationsEnabled,
      };
}
