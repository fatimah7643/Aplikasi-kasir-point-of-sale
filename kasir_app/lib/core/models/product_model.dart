class Product {
  final String id;
  final String? productCode;
  final String productName;
  final double sellingPrice;
  final int stock;
  final String unit;

  Product({
    required this.id,
    this.productCode,
    required this.productName,
    required this.sellingPrice,
    required this.stock,
    required this.unit,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      productCode: json['product_code'],
      productName: json['product_name'],
      sellingPrice: double.parse(json['selling_price'].toString()),
      stock: json['stock'],
      unit: json['unit'] ?? 'pcs',
    );
  }
}