import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

enum UserStatus { idle, loading, success, error }

class UserProvider with ChangeNotifier {
  List<UserModel> _users = [];
  UserStatus _status = UserStatus.idle;
  String _errorMessage = '';
  String _searchQuery = '';
  String _roleFilter = '';

  // ─── Getters ───────────────────────────────────────
  List<UserModel> get users => _users;
  UserStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get roleFilter => _roleFilter;

  List<UserModel> get filteredUsers {
    return _users.where((u) {
      final matchesSearch = _searchQuery.isEmpty ||
          u.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.username.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _roleFilter.isEmpty || u.role == _roleFilter;
      return matchesSearch && matchesRole;
    }).toList();
  }

  // ─── Actions ───────────────────────────────────────
  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setRoleFilter(String role) {
    _roleFilter = role;
    notifyListeners();
  }

  Future<void> fetchUsers() async {
    _status = UserStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await ApiService.get('/users', params: {'limit': 100});
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      _users = data
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _status = UserStatus.success;
    } catch (e) {
      _status = UserStatus.error;
      _errorMessage = _parseError(e);
    }

    notifyListeners();
  }

  Future<String?> createUser({
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final response = await ApiService.post('/users', {
        'username': username,
        'password': password,
        'full_name': fullName,
        'role': role,
      });
      final newUser = UserModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
      _users.insert(0, newUser);
      notifyListeners();
      return null; // null = sukses
    } catch (e) {
      return _parseError(e);
    }
  }

  Future<String?> toggleUserActive(String userId, bool isActive) async {
    try {
      await ApiService.put('/users/$userId', {'is_active': isActive});
      final idx = _users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        _users[idx] = _users[idx].copyWith(isActive: isActive);
        notifyListeners();
      }
      return null;
    } catch (e) {
      return _parseError(e);
    }
  }

  Future<String?> deleteUser(String userId) async {
    try {
      await ApiService.delete('/users/$userId');
      _users.removeWhere((u) => u.id == userId);
      notifyListeners();
      return null;
    } catch (e) {
      return _parseError(e);
    }
  }

  // ─── Helper: ambil pesan error dari DioException ───
  String _parseError(Object e) {
    // Dio error → ambil pesan dari response backend
    try {
      final dioError = e as dynamic;
      final message = dioError.response?.data?['message'];
      if (message != null) return message as String;
    } catch (_) {}
    return e.toString().replaceFirst('Exception: ', '');
  }
}