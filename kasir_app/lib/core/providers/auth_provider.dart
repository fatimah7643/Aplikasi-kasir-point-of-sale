import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _user != null;
  String get role => _user?['role'] ?? '';

  // Cek sesi saat app dibuka
  Future<bool> checkSession() async {
    final token = await StorageService.getToken();
    final userJson = await StorageService.getUser();

    if (token != null && userJson != null) {
      _user = jsonDecode(userJson);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/auth/login', {
        'username': username.trim(),
        'password': password,
      });

      final data = response.data['data'];

      await StorageService.saveToken(data['access_token']);
      await StorageService.saveRefreshToken(data['refresh_token']);
      await StorageService.saveUser(jsonEncode(data['user']));

      _user = data['user'];
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _isLoading = false;
      if (e.toString().contains('401')) {
        _errorMessage = 'Username atau password salah.';
      } else if (e.toString().contains('403')) {
        _errorMessage = 'Akun Anda telah dinonaktifkan.';
      } else {
        _errorMessage = 'Gagal terhubung ke server. Cek koneksi internet.';
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.clearAll();
    _user = null;
    notifyListeners();
  }
}