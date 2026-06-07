class TransactionResult {
  final String id;
  final String transactionNumber;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final double paymentAmount;
  final double changeAmount;
  final String cashierName;
  final List<TransactionItem> items;
  final String createdAt;

  TransactionResult({
    required this.id,
    required this.transactionNumber,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.grandTotal,
    required this.paymentAmount,
    required this.changeAmount,
    required this.cashierName,
    required this.items,
    required this.createdAt,
  });

  factory TransactionResult.fromJson(Map<String, dynamic> json) {
    return TransactionResult(
      id: json['id'],
      transactionNumber: json['transaction_number'],
      subtotal: double.parse(json['subtotal'].toString()),
      discount: double.parse(json['discount'].toString()),
      tax: double.parse(json['tax'].toString()),
      grandTotal: double.parse(json['grand_total'].toString()),
      paymentAmount: double.parse(json['payment_amount'].toString()),
      changeAmount: double.parse(json['change_amount'].toString()),
      cashierName: json['cashier']?['full_name'] ?? '',
      items: (json['items'] as List)
          .map((e) => TransactionItem.fromJson(e))
          .toList(),
      createdAt: json['created_at'] ?? '',
    );
  }
}

class TransactionItem {
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;

  TransactionItem({
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      productName: json['product_name'],
      quantity: json['quantity'],
      price: double.parse(json['current_selling_price'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }
}