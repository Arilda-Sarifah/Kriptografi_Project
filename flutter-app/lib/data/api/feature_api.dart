import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/security/token_storage.dart';

class FeatureApi {
  FeatureApi(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<Options> _authorizedOptions({ResponseType? responseType}) async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) {
      throw StateError('Sesi tidak ditemukan. Silakan login kembali.');
    }
    return Options(
      responseType: responseType,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Map<String, dynamic> _body(dynamic value) {
    if (value is! Map<String, dynamic> || value['status'] != 'success') {
      final message = value is Map ? value['message'] : null;
      throw Exception(
        message is String ? message : 'Respons server tidak valid.',
      );
    }
    return value;
  }

  Map<String, dynamic> _data(dynamic response) {
    final data = _body(response)['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Respons server tidak memiliki data yang diharapkan.');
    }
    return data;
  }

  List<Map<String, dynamic>> _list(dynamic value, String key) {
    final items = _data(value)[key];
    if (items is! List) throw Exception('Daftar $key tidak valid.');
    return items.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async => _list(
    (await _dio.get('get_user.php', options: await _authorizedOptions())).data,
    'users',
  );

  Future<void> sendMessage({
    required int receiverId,
    required String message,
  }) async {
    _body(
      (await _dio.post(
        'send_message.php',
        data: {'receiver_id': receiverId, 'message': message},
        options: await _authorizedOptions(),
      )).data,
    );
  }

  Future<List<Map<String, dynamic>>> fetchMessages() async => _list(
    (await _dio.get(
      'get_messages.php',
      options: await _authorizedOptions(),
    )).data,
    'messages',
  );

  Future<String> decryptMessage(int messageId) async {
    final data = _data(
      (await _dio.post(
        'decrypt_message.php',
        data: {'message_id': messageId},
        options: await _authorizedOptions(),
      )).data,
    );
    final message = data['message'];
    if (message is! String) throw Exception('Isi pesan tidak valid.');
    return message;
  }

  Future<List<Map<String, dynamic>>> fetchFiles() async => _list(
    (await _dio.get('get_files.php', options: await _authorizedOptions())).data,
    'files',
  );

  Future<void> uploadFile({
    required String name,
    required Uint8List bytes,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: name),
    });
    _body(
      (await _dio.post(
        'upload_file.php',
        data: form,
        options: await _authorizedOptions(),
      )).data,
    );
  }

  Future<Uint8List> downloadFile(int fileId) async {
    final response = await _dio.get<List<int>>(
      'download_file.php',
      queryParameters: {'id': fileId},
      options: await _authorizedOptions(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Server mengembalikan berkas kosong.');
    }
    return Uint8List.fromList(bytes);
  }

  Future<List<Map<String, dynamic>>> fetchCertificates() async => _list(
    (await _dio.get(
      'get_certificates.php',
      options: await _authorizedOptions(),
    )).data,
    'certificates',
  );

  Future<int> generateCertificate({
    required String studentName,
    required String courseName,
    required String hiddenMessage,
    required String imageName,
    required Uint8List imageBytes,
  }) async {
    final form = FormData.fromMap({
      'student_name': studentName,
      'course_name': courseName,
      'hidden_message': hiddenMessage,
      'certificate_image': MultipartFile.fromBytes(
        imageBytes,
        filename: imageName,
      ),
    });
    final data = _data(
      (await _dio.post(
        'generate_certificate.php',
        data: form,
        options: await _authorizedOptions(),
      )).data,
    );
    final id = int.tryParse(data['certificate_id'].toString());
    if (id == null)
      throw Exception('Server tidak mengembalikan ID sertifikat.');
    return id;
  }

  Future<Uint8List> downloadCertificateImage(int certificateId) async {
    final response = await _dio.get<List<int>>(
      'download_certificate_image.php',
      queryParameters: {'id': certificateId},
      options: await _authorizedOptions(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Server mengembalikan gambar kosong.');
    }
    return Uint8List.fromList(bytes);
  }

  Future<String> extractCertificateMessage(int certificateId) async {
    final data = _data(
      (await _dio.post(
        'extract_certificate_message.php',
        data: {'certificate_id': certificateId},
        options: await _authorizedOptions(),
      )).data,
    );
    final message = data['message'];
    if (message is! String)
      throw Exception('Pesan hasil ekstraksi tidak valid.');
    return message;
  }

  Future<Map<String, dynamic>> fetchBlockchain() async => _data(
    (await _dio.get(
      'blockchain_status.php',
      options: await _authorizedOptions(),
    )).data,
  );
}
