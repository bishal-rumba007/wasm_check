import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches package metadata from the pub.dev REST API.
class PubApiClient {
  PubApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://pub.dev/api';
  static const _timeout = Duration(seconds: 10);

  /// Returns the pubspec map for [name] at [version], or null if:
  /// - the package/version doesn't exist (404)
  /// - the request times out
  /// - any network or parse error occurs
  ///
  /// Callers should treat null as [Unknown] compatibility.
  Future<Map<String, dynamic>?> fetchPubspec(
    String name,
    String version,
  ) async {
    final uri = Uri.parse('$_baseUrl/packages/$name/versions/$version');

    try {
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) return null;

      final body = json.decode(response.body);
      if (body is! Map<String, dynamic>) return null;

      final pubspec = body['pubspec'];
      return pubspec is Map<String, dynamic> ? pubspec : null;
    } catch (_) {
      // Timeout, socket error, JSON parse error — all treated as Unknown.
      return null;
    }
  }

  /// Releases the underlying HTTP client. Always call this when done.
  void close() => _client.close();
}
