// MIGRATION: TypeScript `type User` → Dart class with fromJson/toJson.
//            Stored in SharedPreferences (replaces AsyncStorage in authStore).

class AppUser {
  // MIGRATION: TypeScript field `userId: string` → Dart `final String userId`.
  //            All fields non-nullable to match source type definition.
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  // MIGRATION: Password is NOT stored client-side after login; kept in the model
  //            only for the registration payload. Never persisted to SharedPreferences.
  final String password;

  const AppUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  AppUser copyWith({
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
  }) =>
      AppUser(
        userId: userId ?? this.userId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        password: password ?? this.password,
      );

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        userId: json['userId'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        email: json['email'] as String,
        password: json['password'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        // MIGRATION: Password excluded from persistence (same as source authStore
        //            which stored user in AsyncStorage but the password stays hashed
        //            server-side).
        'password': '',
      };

  @override
  String toString() =>
      'AppUser(userId: $userId, firstName: $firstName, lastName: $lastName, email: $email)';
}
