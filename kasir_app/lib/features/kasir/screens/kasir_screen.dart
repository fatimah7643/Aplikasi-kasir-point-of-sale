import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/product_provider.dart';
import '../widgets/product_search_result.dart';
import '../widgets/cart_item_widget.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = true;

  String _formatPrice(double price) {
    final str = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KASIR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Consumer<AuthProvider>(
              builder: (_, auth, __) => Text(
                auth.user?['full_name'] ?? '',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          // Toggle Search/Cart
          Consumer<ProductProvider>(
            builder: (_, product, __) => Stack(
              children: [
                IconButton(
                  icon: Icon(
                    _showSearch ? Icons.shopping_cart : Icons.search,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() => _showSearch = !_showSearch);
                  },
                ),
                if (product.totalItems > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${product.totalItems}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Keluar'),
                  content: const Text('Yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                context.read<ProductProvider>().clearCart();
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== PANEL ATAS: Search atau Cart =====
          Expanded(
            child: _showSearch ? _buildSearchPanel() : _buildCartPanel(),
          ),

          // ===== PANEL BAWAH: Total & Checkout =====
          _buildBottomPanel(),
        ],
      ),
    );
  }

  // ===== SEARCH PANEL =====
  Widget _buildSearchPanel() {
    return Column(
      children: [
        // Kolom Pencarian Jumbo
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            autofocus: false,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Cari nama barang...',
              hintStyle: const TextStyle(fontSize: 16),
              prefixIcon: const Icon(Icons.search, size: 28),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<ProductProvider>().searchProducts('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.blue.shade700,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 12,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {});
              context.read<ProductProvider>().searchProducts(value);
            },
          ),
        ),

        // Hasil Pencarian
        Expanded(
          child: Consumer<ProductProvider>(
            builder: (_, product, __) {
              if (product.isSearching) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_searchController.text.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ketik nama barang\nuntuk mencari',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (product.searchResults.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Barang tidak ditemukan',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: product.searchResults.length,
                itemBuilder: (_, index) {
                  final item = product.searchResults[index];
                  return ProductSearchResult(
                    product: item,
                    onAdd: () {
                      product.addToCart(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${item.productName} ditambahkan',
                          ),
                          duration: const Duration(seconds: 1),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ===== CART PANEL =====
  Widget _buildCartPanel() {
    return Consumer<ProductProvider>(
      builder: (_, product, __) {
        if (product.cart.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Keranjang kosong',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showSearch = true),
                  icon: const Icon(Icons.search),
                  label: const Text('Cari Barang'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header keranjang
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${product.cart.length} jenis barang',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Kosongkan Keranjang'),
                          content: const Text(
                            'Yakin ingin menghapus semua barang?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                product.clearCart();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Hapus Semua'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Kosongkan',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

            // List item keranjang
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: product.cart.length,
                itemBuilder: (_, index) {
                  final item = product.cart[index];
                  return CartItemWidget(
                    item: item,
                    onIncrease: () =>
                        product.increaseQty(item.product.id),
                    onDecrease: () =>
                        product.decreaseQty(item.product.id),
                    onRemove: () =>
                        product.removeFromCart(item.product.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ===== BOTTOM PANEL: Total & Checkout =====
  Widget _buildBottomPanel() {
    return Consumer<ProductProvider>(
      builder: (_, product, __) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.black, width: 2),
            ),
          ),
          child: Column(
            children: [
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatPrice(product.subtotal),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tombol Checkout
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: product.cart.isEmpty
                      ? null
                      : () {
                          Navigator.pushNamed(context, '/checkout');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 26),
                      SizedBox(width: 8),
                      Text(
                        'LANJUT CHECKOUT',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}