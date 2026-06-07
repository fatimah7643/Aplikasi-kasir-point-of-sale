class ProfitSummary {
  final String period;
  final int totalTransactions;
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final double totalDiscount;
  final double netProfit;
  final double marginPercent;
  final List<ProfitPerProduct> perProduct;

  ProfitSummary({
    required this.period,
    required this.totalTransactions,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.totalDiscount,
    required this.netProfit,
    required this.marginPercent,
    required this.perProduct,
  });

  factory ProfitSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];
    return ProfitSummary(
      period: json['period'],
      totalTransactions: summary['total_transactions'],
      totalRevenue: double.parse(summary['total_revenue'].toString()),
      totalCost: double.parse(summary['total_cost'].toString()),
      totalProfit: double.parse(summary['total_profit'].toString()),
      totalDiscount: double.parse(summary['total_discount'].toString()),
      netProfit: double.parse(summary['net_profit'].toString()),
      marginPercent: double.parse(summary['margin_percent'].toString()),
      perProduct: (json['per_product'] as List)
          .map((e) => ProfitPerProduct.fromJson(e))
          .toList(),
    );
  }
}

class ProfitPerProduct {
  final String productName;
  final double costPrice;
  final int totalQty;
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final double marginPercent;

  ProfitPerProduct({
    required this.productName,
    required this.costPrice,
    required this.totalQty,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.marginPercent,
  });

  factory ProfitPerProduct.fromJson(Map<String, dynamic> json) {
    return ProfitPerProduct(
      productName: json['product_name'],
      costPrice: double.parse(json['cost_price'].toString()),
      totalQty: int.parse(json['total_qty'].toString()),
      totalRevenue: double.parse(json['total_revenue'].toString()),
      totalCost: double.parse(json['total_cost'].toString()),
      totalProfit: double.parse(json['total_profit'].toString()),
      marginPercent: double.parse(json['margin_percent'].toString()),
    );
  }
}