import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;

  const ApiClient({required this.baseUrl});

  Uri _u(String path, [Map<String, String>? query]) {
    final uri = Uri.parse(baseUrl);
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: path.startsWith('/') ? path : '/$path',
      queryParameters: query,
    );
  }

  Future<http.Response> get(String path, {Map<String, String>? query}) {
    return http.get(_u(path, query), headers: {'content-type': 'application/json'});
  }

  Future<http.Response> post(String path, {Object? body}) {
    return http.post(
      _u(path),
      headers: {'content-type': 'application/json'},
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> put(String path, {Object? body}) {
    return http.put(
      _u(path),
      headers: {'content-type': 'application/json'},
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> delete(String path, {Map<String, String>? query}) {
    return http.delete(_u(path, query), headers: {'content-type': 'application/json'});
  }
}
