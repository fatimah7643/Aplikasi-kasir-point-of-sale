class ProductAdmin {
  final String id;
  final String? productCode;
  final String productName;
  final double costPrice;
  final double sellingPrice;
  final int stock;
  final String unit;
  final bool isActive;

  ProductAdmin({
    required this.id,
    this.productCode,
    required this.productName,
    required this.costPrice,
    required this.sellingPrice,
    required this.stock,
    required this.unit,
    required this.isActive,
  });

  factory ProductAdmin.fromJson(Map<String, dynamic> json) {
    return ProductAdmin(
      id: json['id'],
      productCode: json['product_code'],
      productName: json['product_name'],
      costPrice: double.parse(json['cost_price'].toString()),
      sellingPrice: double.parse(json['selling_price'].toString()),
      stock: json['stock'],
      unit: json['unit'] ?? 'pcs',
      isActive: json['is_active'] ?? true,
    );
  }

  double get profit => sellingPrice - costPrice;
  double get marginPercent =>
      costPrice > 0 ? (profit / costPrice) * 100 : 0;
}