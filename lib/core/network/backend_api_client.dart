import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/core/config/app_links.dart';

class BackendApiException implements Exception {
  const BackendApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class BackendApiClient {
  BackendApiClient({
    required SupabaseClient supabase,
    http.Client? httpClient,
  })  : _supabase = supabase,
        _httpClient = httpClient ?? http.Client();

  final SupabaseClient _supabase;
  final http.Client _httpClient;

  Future<dynamic> get(String path) async {
    return _request('GET', path);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    return _request('POST', path, body: body);
  }

  Future<dynamic> delete(String path) async {
    return _request('DELETE', path);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    return _request('PATCH', path, body: body);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final session = _supabase.auth.currentSession;
    final token = session?.accessToken;

    if (token == null || token.isEmpty) {
      throw const BackendApiException('You need to sign in again.');
    }

    final baseUri = Uri.parse(AppLinks.backendApiUrl);
    final uri = baseUri.resolve(path.startsWith('/') ? path.substring(1) : path);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    http.Response response;
    switch (method) {
      case 'GET':
        response = await _httpClient.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _httpClient.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? <String, dynamic>{}),
        );
        break;
      case 'DELETE':
        response = await _httpClient.delete(uri, headers: headers);
        break;
      case 'PATCH':
        response = await _httpClient.patch(
          uri,
          headers: headers,
          body: jsonEncode(body ?? <String, dynamic>{}),
        );
        break;
      default:
        throw BackendApiException('Unsupported method: $method');
    }

    dynamic decoded;
    if (response.body.isNotEmpty) {
      decoded = jsonDecode(response.body);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw BackendApiException(
        message ?? 'Request failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }
}
