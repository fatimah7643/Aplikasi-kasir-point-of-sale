import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static void init() {
    // Interceptor: otomatis sisipkan token di setiap request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  static Future<Response> post(String path, Map<String, dynamic> data) async {
    return await _dio.post(path, data: data);
  }

  static Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return await _dio.get(path, queryParameters: params);
  }

  static Future<Response> put(String path, Map<String, dynamic> data) async {
    return await _dio.put(path, data: data);
  }

  static Future<Response> patch(String path, Map<String, dynamic> data) async {
    return await _dio.patch(path, data: data);
  }

  static Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}