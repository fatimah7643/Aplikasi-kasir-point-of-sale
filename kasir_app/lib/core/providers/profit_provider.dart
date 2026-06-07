import 'package:flutter/material.dart';
import '../models/profit_model.dart';
import '../services/api_service.dart';

class ProfitProvider extends ChangeNotifier {
  ProfitSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedPeriod = 'today';

  ProfitSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedPeriod => _selectedPeriod;

  Future<void> loadProfit(String period) async {
    _selectedPeriod = period;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/dashboard/profit/summary',
        params: {'period': period},
      );
      _summary = ProfitSummary.fromJson(response.data['data']);
    } catch (e) {
      _errorMessage = 'Gagal memuat rekap laba.';
    }

    _isLoading = false;
    notifyListeners();
  }
}