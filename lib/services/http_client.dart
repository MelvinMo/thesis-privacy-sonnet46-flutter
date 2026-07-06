// MIGRATION: services/HttpClient.ts (CloudStorageService wrapper) → Dart.
//            fetch/axios → http ^1.
//            Env vars EXPO_PUBLIC_API_ENCRYPTED_URL / EXPO_PUBLIC_API_UNENCRYPTED_URL
//            → compile-time const strings (Dart has no .env at runtime without
//              flutter_dotenv; use String.fromEnvironment as the equivalent).
//
//            Demo mode: encryptedInTransit=false uses the HTTP (local) URL.

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants/transparency_config.dart';

class AppHttpClient {
  // MIGRATION: String.fromEnvironment replaces EXPO_PUBLIC_API_* env vars.
  //            Pass at build time: flutter run --dart-define=API_ENCRYPTED_URL=...
  // MIGRATION_FLAG: Defaults are placeholders — update to real URLs before release.
  static const _encryptedUrl = String.fromEnvironment(
    'API_ENCRYPTED_URL',
    defaultValue: 'https://your-backend.example.com',
  );
  // MIGRATION_FLAG: hardcoded for local dev; pass --dart-define=API_UNENCRYPTED_URL=... for other envs.
  static const _unencryptedUrl = 'http://YOUR_LAN_IP:7000';

  final String baseUrl;
  String? _authToken;

  AppHttpClient()
      : baseUrl = TransparencyConfig.useEncryptedTransit
            ? _encryptedUrl
            : _unencryptedUrl;

  void setAuthToken(String? token) => _authToken = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // ---------------------------------------------------------------------------
  // POST
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // ---------------------------------------------------------------------------
  // GET
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  // ---------------------------------------------------------------------------
  // PUT
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.delete(uri, headers: _headers);
    return _handleResponse(response);
  }

  // ---------------------------------------------------------------------------
  // Response handler
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body =
        response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
    final msg = (body as Map<String, dynamic>)['message'] as String? ??
        'HTTP ${response.statusCode}';
    throw Exception(msg);
  }
}
