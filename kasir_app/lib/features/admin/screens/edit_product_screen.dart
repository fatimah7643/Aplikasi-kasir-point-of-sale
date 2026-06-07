import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/models/product_admin_model.dart';
import '../../../core/providers/admin_product_provider.dart';

class EditProductScreen extends StatefulWidget {
  final ProductAdmin product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _costController;
  late final TextEditingController _sellController;
  late String _unit;

  final List<String> _units = [
    'pcs', 'kg', 'gr', 'liter', 'ml', 'botol',
    'karung', 'bungkus', 'sachet', 'buah', 'lusin'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.productName);
    _codeController = TextEditingController(
        text: widget.product.productCode ?? '');
    _costController = TextEditingController(
        text: widget.product.costPrice.toStringAsFixed(0));
    _sellController = TextEditingController(
        text: widget.product.sellingPrice.toStringAsFixed(0));
    _unit = _units.contains(widget.product.unit)
        ? widget.product.unit
        : 'pcs';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _costController.dispose();
    _sellController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;

    final cost = double.tryParse(_costController.text) ?? 0;
    final sell = double.tryParse(_sellController.text) ?? 0;

    final provider = context.read<AdminProductProvider>();
    final success = await provider.updateProduct(
      productId: widget.product.id,
      productName: _nameController.text.trim(),
      productCode: _codeController.text.trim().isEmpty
          ? null
          : _codeController.text.trim(),
      costPrice: cost,
      sellingPrice: sell,
      unit: _unit,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barang berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          'EDIT BARANG',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 16),
                decoration: _inputDecoration('Nama Barang'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _codeController,
                style: const TextStyle(fontSize: 16),
                decoration: _inputDecoration('Kode Barang (Opsional)'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      style: const TextStyle(fontSize: 16),
                      decoration: _inputDecoration('Harga Modal (Rp)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _sellController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      style: const TextStyle(fontSize: 16),
                      decoration: _inputDecoration('Harga Jual (Rp)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _unit,
                decoration: _inputDecoration('Satuan'),
                items: _units
                    .map((u) =>
                        DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _unit = val);
                },
              ),
              const SizedBox(height: 24),
              Consumer<AdminProductProvider>(
                builder: (_, provider, __) => SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: provider.isSaving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(
                      provider.isSaving ? 'Menyimpan...' : 'SIMPAN PERUBAHAN',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side:
                            const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}