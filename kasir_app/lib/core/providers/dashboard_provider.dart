import 'package:flutter/foundation.dart';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';

enum DashboardStatus { idle, loading, success, error }

class DashboardProvider with ChangeNotifier {
  DashboardSummary? _summary;
  List<WeeklyChartData> _weeklyChart = [];
  List<TopProduct> _topProducts = [];
  DashboardStatus _status = DashboardStatus.idle;
  String _errorMessage = '';

  // ─── Getters ───────────────────────────────────────
  DashboardSummary? get summary => _summary;
  List<WeeklyChartData> get weeklyChart => _weeklyChart;
  List<TopProduct> get topProducts => _topProducts;
  DashboardStatus get status => _status;
  String get errorMessage => _errorMessage;

  // ─── Load semua data sekaligus ─────────────────────
  Future<void> loadDashboard() async {
    _status = DashboardStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      // Paralel — 3 request sekaligus lebih cepat
      final results = await Future.wait([
        ApiService.get('/dashboard/summary'),
        ApiService.get('/dashboard/chart/weekly'),
        ApiService.get('/dashboard/top-products'),
      ]);

      _summary = DashboardSummary.fromJson(
        results[0].data['data'] as Map<String, dynamic>,
      );

      final chartData = results[1].data['data'] as List<dynamic>;
      _weeklyChart = chartData
          .map((e) => WeeklyChartData.fromJson(e as Map<String, dynamic>))
          .toList();

      final topData = results[2].data['data'] as List<dynamic>;
      _topProducts = topData
          .map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
          .toList();

      _status = DashboardStatus.success;
    } catch (e) {
      _status = DashboardStatus.error;
      try {
        final dioError = e as dynamic;
        final message = dioError.response?.data?['message'];
        _errorMessage = message ?? e.toString();
      } catch (_) {
        _errorMessage = e.toString();
      }
    }

    notifyListeners();
  }
}