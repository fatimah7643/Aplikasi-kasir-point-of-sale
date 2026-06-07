import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _searchResults = [];
  List<CartItem> _cart = [];
  bool _isSearching = false;
  String _searchQuery = '';

  List<Product> get searchResults => _searchResults;
  List<CartItem> get cart => _cart;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;

  double get subtotal =>
      _cart.fold(0, (sum, item) => sum + item.subtotal);

  int get totalItems =>
      _cart.fold(0, (sum, item) => sum + item.quantity);

  // Pencarian produk
  Future<void> searchProducts(String query) async {
    _searchQuery = query;

    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/products',
        params: {'search': query.trim(), 'limit': '20'},
      );

      final List data = response.data['data'];
      _searchResults = data.map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  // Tambah ke keranjang
  void addToCart(Product product) {
    final index = _cart.indexWhere((e) => e.product.id == product.id);

    if (index >= 0) {
      if (_cart[index].quantity < product.stock) {
        _cart[index].quantity++;
      }
    } else {
      if (product.stock > 0) {
        _cart.add(CartItem(product: product));
      }
    }
    notifyListeners();
  }

  // Tambah qty
  void increaseQty(String productId) {
    final index = _cart.indexWhere((e) => e.product.id == productId);
    if (index >= 0) {
      final maxStock = _cart[index].product.stock;
      if (_cart[index].quantity < maxStock) {
        _cart[index].quantity++;
        notifyListeners();
      }
    }
  }

  // Kurangi qty
  void decreaseQty(String productId) {
    final index = _cart.indexWhere((e) => e.product.id == productId);
    if (index >= 0) {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Hapus dari keranjang
  void removeFromCart(String productId) {
    _cart.removeWhere((e) => e.product.id == productId);
    notifyListeners();
  }

  // Reset keranjang
  void clearCart() {
    _cart = [];
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }
}