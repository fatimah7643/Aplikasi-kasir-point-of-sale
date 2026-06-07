import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/user_provider.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/user_card.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Manajemen User',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => context.read<UserProvider>().fetchUsers(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Tambah User'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                onChanged: provider.setSearch,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau username...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              // Role filter chips
              Row(
                children: [
                  _filterChip(context, provider, '', 'Semua'),
                  const SizedBox(width: 8),
                  _filterChip(context, provider, 'admin', 'Admin'),
                  const SizedBox(width: 8),
                  _filterChip(context, provider, 'kasir', 'Kasir'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(
    BuildContext context,
    UserProvider provider,
    String value,
    String label,
  ) {
    final isSelected = provider.roleFilter == value;
    return GestureDetector(
      onTap: () => provider.setRoleFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.status == UserStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.status == UserStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56, color: Colors.red),
                const SizedBox(height: 12),
                Text(provider.errorMessage, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: provider.fetchUsers,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final users = provider.filteredUsers;

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  provider.searchQuery.isNotEmpty
                      ? 'User tidak ditemukan'
                      : 'Belum ada user',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.fetchUsers,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return UserCard(
                user: users[index],
                onToggleActive: (userId, isActive) =>
                    _onToggleActive(context, userId, isActive, users[index].fullName),
                onDelete: (userId) =>
                    _onDelete(context, userId, users[index].fullName),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _onToggleActive(
    BuildContext context,
    String userId,
    bool isActive,
    String fullName,
  ) async {
    final action = isActive ? 'mengaktifkan' : 'menonaktifkan';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isActive ? 'Aktifkan User' : 'Nonaktifkan User'),
        content: Text('Yakin ingin $action "$fullName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isActive ? 'Aktifkan' : 'Nonaktifkan'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final error = await context.read<UserProvider>().toggleUserActive(userId, isActive);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'User "$fullName" berhasil ${isActive ? "diaktifkan" : "dinonaktifkan"}'
              : error,
        ),
        backgroundColor: error == null ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onDelete(
    BuildContext context,
    String userId,
    String fullName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text(
          'Yakin ingin menghapus "$fullName"?\nUser akan dinonaktifkan secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final error = await context.read<UserProvider>().deleteUser(userId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error == null ? 'User "$fullName" berhasil dihapus' : error),
        backgroundColor: error == null ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddUserDialog(),
    );
  }
}