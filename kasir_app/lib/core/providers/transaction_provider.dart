import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/cart_item_model.dart';
import '../services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  TransactionResult? _lastTransaction;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TransactionResult? get lastTransaction => _lastTransaction;

  Future<bool> createTransaction({
    required List<CartItem> items,
    required double paymentAmount,
    double discount = 0,
    double tax = 0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/transactions', {
        'items': items
            .map((e) => {
                  'product_id': e.product.id,
                  'quantity': e.quantity,
                })
            .toList(),
        'discount': discount,
        'tax': tax,
        'payment_amount': paymentAmount,
      });

      _lastTransaction = TransactionResult.fromJson(response.data['data']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      final errMsg = e.toString();
      if (errMsg.contains('400')) {
        _errorMessage = 'Pembayaran kurang dari total belanja.';
      } else if (errMsg.contains('404')) {
        _errorMessage = 'Barang tidak ditemukan.';
      } else if (errMsg.contains('stok')) {
        _errorMessage = 'Stok barang tidak mencukupi.';
      } else {
        _errorMessage = 'Gagal memproses transaksi. Coba lagi.';
      }
      notifyListeners();
      return false;
    }
  }
}