import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/admin_product_provider.dart';
import '../widgets/product_admin_card.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'user_management_screen.dart';
import 'dashboard_screen.dart';
import '../screens/profit_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProductProvider>().loadProducts(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddStockDialog(
    BuildContext context,
    String productId,
    String productName,
    int currentStock,
  ) async {
    final controller = TextEditingController();
    final provider = context.read<AdminProductProvider>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Tambah Stok\n$productName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stok saat ini: $currentStock'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Jumlah tambahan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.add),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final qty = int.tryParse(controller.text);
              if (qty == null || qty <= 0) return;
              Navigator.pop(context);
              final success = await provider.addStock(productId, qty);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Stok berhasil ditambah $qty unit'
                          : 'Gagal menambah stok',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Simpan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String productId,
    String productName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text(
          'Yakin ingin menghapus "$productName"?\nBarang tidak akan tampil ke kasir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text('Hapus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await context
          .read<AdminProductProvider>()
          .deleteProduct(productId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? '$productName berhasil dihapus' : 'Gagal menghapus',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
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
              'ADMIN PANEL',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            ).then((_) => setState(() => _selectedIndex = 0));
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const UserManagementScreen()),
            ).then((_) => setState(() => _selectedIndex = 0));
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfitScreen()),
            ).then((_) => setState(() => _selectedIndex = 0));
          }
        },
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts_rounded),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Rekap Laba',
          ), 
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Cari nama barang...',
                prefixIcon: const Icon(Icons.search, size: 26),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<AdminProductProvider>().setSearch('');
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
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
              ),
              onChanged: (val) {
                setState(() {});
                context.read<AdminProductProvider>().setSearch(val);
              },
            ),
          ),

          // Stats bar
          Consumer<AdminProductProvider>(
            builder: (_, provider, __) {
              final products = provider.filteredProducts;
              final lowStock = products.where((p) => p.stock <= 5).length;
              return Container(
                color: Colors.blue.shade50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      '${products.length} barang',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (lowStock > 0) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$lowStock stok menipis',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          // List produk
          Expanded(
            child: Consumer<AdminProductProvider>(
              builder: (_, provider, __) {
                if (provider.isLoading && provider.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(provider.errorMessage!),
                        ElevatedButton(
                          onPressed: () =>
                              provider.loadProducts(refresh: true),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final products = provider.filteredProducts;

                if (products.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada barang',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadProducts(refresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: products.length,
                    itemBuilder: (_, index) {
                      final product = products[index];
                      return ProductAdminCard(
                        product: product,
                        onAddStock: () => _showAddStockDialog(
                          context,
                          product.id,
                          product.productName,
                          product.stock,
                        ),
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditProductScreen(product: product),
                            ),
                          );
                        },
                        onDelete: () => _confirmDelete(
                          context,
                          product.id,
                          product.productName,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // FAB Tambah Produk
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 26),
        label: const Text(
          'Tambah Barang',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}