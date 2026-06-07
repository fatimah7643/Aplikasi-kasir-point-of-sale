import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: 'refresh_token', value: token);
  }

  static Future<void> saveUser(String userJson) async {
    await _storage.write(key: 'user_data', value: userJson);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  static Future<String?> getUser() async {
    return await _storage.read(key: 'user_data');
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}