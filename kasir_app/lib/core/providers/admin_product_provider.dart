import 'package:flutter/material.dart';
import '../models/product_admin_model.dart';
import '../services/api_service.dart';

class AdminProductProvider extends ChangeNotifier {
  List<ProductAdmin> _products = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';
  int _currentPage = 1;
  bool _hasMore = true;

  List<ProductAdmin> get products => _products;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  List<ProductAdmin> get filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where((p) => p.productName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _products = [];
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/products', params: {
        'page': '$_currentPage',
        'limit': '50',
      });

      final List data = response.data['data'];
      final meta = response.data['meta'];

      final newProducts = data.map((e) => ProductAdmin.fromJson(e)).toList();
      _products.addAll(newProducts);
      _currentPage++;
      _hasMore = meta['has_next'] ?? false;
    } catch (e) {
      _errorMessage = 'Gagal memuat data produk.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createProduct({
    required String productName,
    String? productCode,
    required double costPrice,
    required double sellingPrice,
    required int stock,
    required String unit,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService.post('/products', {
        'product_name': productName,
        'product_code': productCode,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'stock': stock,
        'unit': unit,
      });

      await loadProducts(refresh: true);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      final err = e.toString();
      if (err.contains('409')) {
        _errorMessage = 'Kode barang sudah digunakan.';
      } else if (err.contains('400')) {
        _errorMessage = 'Harga jual tidak boleh lebih rendah dari harga modal.';
      } else {
        _errorMessage = 'Gagal menambahkan barang.';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> addStock(String productId, int quantity) async {
    _isSaving = true;
    notifyListeners();

    try {
      await ApiService.patch('/products/$productId/stock', {
        'quantity': quantity,
      });

      // Update lokal
      final index = _products.indexWhere((p) => p.id == productId);
      if (index >= 0) {
        final p = _products[index];
        _products[index] = ProductAdmin(
          id: p.id,
          productCode: p.productCode,
          productName: p.productName,
          costPrice: p.costPrice,
          sellingPrice: p.sellingPrice,
          stock: p.stock + quantity,
          unit: p.unit,
          isActive: p.isActive,
        );
      }

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = 'Gagal menambah stok.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct({
    required String productId,
    required String productName,
    String? productCode,
    required double costPrice,
    required double sellingPrice,
    required String unit,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      await ApiService.put('/products/$productId', {
        'product_name': productName,
        'product_code': productCode,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'unit': unit,
      });

      await loadProducts(refresh: true);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = 'Gagal memperbarui barang.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await ApiService.delete('/products/$productId');
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus barang.';
      notifyListeners();
      return false;
    }
  }
}