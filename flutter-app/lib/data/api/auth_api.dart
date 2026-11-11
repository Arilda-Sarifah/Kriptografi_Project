import 'package:dio/dio.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<void> verifyDongle({
    required String username,
    required String dongleContent,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'verify_dongle.php',
      data: {'username': username, 'dongle_content': dongleContent},
    );
    _requireSuccess(response.data);
  }

  Future<RegisteredAccount> register({
    required String username,
    required String password,
    required String role,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'register.php',
      data: {'username': username, 'password': password, 'role': role},
    );
    final body = _requireSuccess(response.data);
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Respons registrasi tidak memiliki data akun.');
    }

    final content = data['dongle_content'];
    if (content is! String || content.isEmpty) {
      throw const ApiException('Server tidak mengembalikan dongle baru.');
    }

    return RegisteredAccount(
      username: data['username'] as String? ?? username,
      dongleFileName:
          data['dongle_file_name'] as String? ?? 'edusafe_dongle.key',
      dongleContent: content,
    );
  }

  Future<String> login({
    required String username,
    required String password,
    required String dongleContent,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'login.php',
      data: {
        'username': username,
        'password': password,
        'dongle_content': dongleContent,
      },
    );
    final body = _requireSuccess(response.data);
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Respons login tidak memiliki data token.');
    }

    final token = data['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('Server tidak mengembalikan JWT.');
    }
    return token;
  }

  Map<String, dynamic> _requireSuccess(Map<String, dynamic>? body) {
    if (body == null || body['status'] != 'success') {
      final message = body?['message'];
      throw ApiException(
        message is String
            ? message
            : 'Server mengembalikan respons tidak valid.',
      );
    }
    return body;
  }
}

class RegisteredAccount {
  const RegisteredAccount({
    required this.username,
    required this.dongleFileName,
    required this.dongleContent,
  });

  final String username;
  final String dongleFileName;
  final String dongleContent;
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
