import 'package:core/platform/budkon_api_client.dart';
import 'package:dio/dio.dart';
import '../models/projekt_model.dart';

class ProjektApi {
  final Dio _dio = budkonDio(
    receiveTimeout: const Duration(seconds: 180),
    connectTimeout: const Duration(seconds: 30),
  );

  Future<ParsedProjekt> parseProject(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'plik': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final resp = await _dio.post(
      '/kosztorysy/parse-projekt/',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(seconds: 180),
      ),
    );
    return ParsedProjekt.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ParsedProjekt> parseProjectBytes(
    List<int> bytes,
    String fileName,
  ) async {
    final formData = FormData.fromMap({
      'plik': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final resp = await _dio.post(
      '/kosztorysy/parse-projekt/',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(seconds: 180),
      ),
    );
    return ParsedProjekt.fromJson(resp.data as Map<String, dynamic>);
  }
}
