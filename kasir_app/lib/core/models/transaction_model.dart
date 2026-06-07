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
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
}

class TransactionResult {
  final String transactionNumber;
  final String createdAt;
  final String cashierName;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final double paymentAmount;
  final double changeAmount;
  final List<TransactionItem> items;

  TransactionResult({
    required this.transactionNumber,
    required this.createdAt,
    required this.cashierName,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.paymentAmount,
    required this.changeAmount,
    required this.items,
  });

  factory TransactionResult.fromJson(Map<String, dynamic> json) {
    return TransactionResult(
      transactionNumber: json['transaction_number'] ?? '',
      createdAt: json['created_at'] ?? '',
      cashierName: json['cashier_name'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      grandTotal: (json['grand_total'] ?? 0).toDouble(),
      paymentAmount: (json['payment_amount'] ?? 0).toDouble(),
      changeAmount: (json['change_amount'] ?? 0).toDouble(),
      items: (json['items'] as List? ?? [])
          .map((e) => TransactionItem.fromJson(e))
          .toList(),
    );
  }
}