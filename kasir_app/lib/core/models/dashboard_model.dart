class DashboardSummary {
  final double totalRevenue;
  final int totalTransactions;
  final double avgTransaction;
  final double totalDiscount;
  final double revenueChangePercent;
  final double transactionChangePercent;

  DashboardSummary({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.avgTransaction,
    required this.totalDiscount,
    required this.revenueChangePercent,
    required this.transactionChangePercent,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final today = json['today'] as Map<String, dynamic>;
    final comparison = json['comparison'] as Map<String, dynamic>;
    return DashboardSummary(
      totalRevenue: (today['total_revenue'] as num).toDouble(),
      totalTransactions: today['total_transactions'] as int,
      avgTransaction: (today['avg_transaction'] as num).toDouble(),
      totalDiscount: (today['total_discount'] as num).toDouble(),
      revenueChangePercent: (comparison['revenue_change_percent'] as num).toDouble(),
      transactionChangePercent: (comparison['transaction_change_percent'] as num).toDouble(),
    );
  }
}

class WeeklyChartData {
  final String date;
  final String label;
  final double totalRevenue;
  final int totalTransactions;

  WeeklyChartData({
    required this.date,
    required this.label,
    required this.totalRevenue,
    required this.totalTransactions,
  });

  factory WeeklyChartData.fromJson(Map<String, dynamic> json) {
    return WeeklyChartData(
      date: json['date'] as String,
      label: json['label'] as String,
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      totalTransactions: json['total_transactions'] as int,
    );
  }
}

class TopProduct {
  final String productName;
  final String unit;
  final int totalQty;
  final double totalRevenue;

  TopProduct({
    required this.productName,
    required this.unit,
    required this.totalQty,
    required this.totalRevenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productName: json['product_name'] as String,
      unit: json['unit'] as String? ?? 'pcs',
      totalQty: json['total_qty'] as int,
      totalRevenue: (json['total_revenue'] as num).toDouble(),
    );
  }
}