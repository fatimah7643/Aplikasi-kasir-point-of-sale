import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/product_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import 'success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _paymentController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  double _paymentAmount = 0;

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

  double get _discount =>
      double.tryParse(_discountController.text.replaceAll('.', '')) ?? 0;

  double _grandTotal(double subtotal) {
    final total = subtotal - _discount;
    return total < 0 ? 0 : total;
  }

  double _change(double subtotal) {
    final change = _paymentAmount - _grandTotal(subtotal);
    return change < 0 ? 0 : change;
  }

  // Tombol nominal cepat
  Widget _quickPayButton(double subtotal, double amount) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentAmount = amount;
          _paymentController.text = amount.toStringAsFixed(0);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _paymentAmount == amount
                ? Colors.blue.shade700
                : Colors.grey.shade400,
            width: _paymentAmount == amount ? 2 : 1,
          ),
        ),
        child: Text(
          _formatPrice(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _paymentAmount == amount
                ? Colors.blue.shade700
                : Colors.black87,
          ),
        ),
      ),
    );
  }

  Future<void> _processCheckout() async {
    final product = context.read<ProductProvider>();
    final transaction = context.read<TransactionProvider>();
    final grandTotal = _grandTotal(product.subtotal);

    if (_paymentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah pembayaran!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_paymentAmount < grandTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pembayaran kurang! Minimal ${_formatPrice(grandTotal)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await transaction.createTransaction(
      items: product.cart,
      paymentAmount: _paymentAmount,
      discount: _discount,
    );

    if (!mounted) return;

    if (success) {
      product.clearCart();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            transaction: transaction.lastTransaction!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(transaction.errorMessage ?? 'Transaksi gagal.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _paymentController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          'CHECKOUT',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (_, product, __) {
          final subtotal = product.subtotal;
          final grandTotal = _grandTotal(subtotal);
          final change = _change(subtotal);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ===== RINGKASAN BELANJA =====
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ringkasan Belanja',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(thickness: 1),
                            ...product.cart.map(
                              (item) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.product.productName} x${item.quantity}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                    Text(
                                      _formatPrice(item.subtotal),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  _formatPrice(subtotal),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ===== DISKON =====
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Diskon (Rp)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _discountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(fontSize: 18),
                              decoration: InputDecoration(
                                hintText: '0',
                                prefixText: 'Rp ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 12,
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ===== TOTAL AKHIR =====
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL BAYAR',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _formatPrice(grandTotal),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ===== INPUT PEMBAYARAN =====
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Uang Bayar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _paymentController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: '0',
                                prefixText: 'Rp ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade700,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 12,
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _paymentAmount =
                                      double.tryParse(val) ?? 0;
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // Tombol nominal cepat
                            const Text(
                              'Nominal Cepat:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _quickPayButton(subtotal, grandTotal),
                                _quickPayButton(subtotal, 50000),
                                _quickPayButton(subtotal, 100000),
                                _quickPayButton(subtotal, 200000),
                                _quickPayButton(subtotal, 500000),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ===== KEMBALIAN =====
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: change > 0
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: change > 0 ? Colors.green : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'KEMBALIAN',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatPrice(change),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: change > 0
                                    ? Colors.green.shade700
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ===== TOMBOL PROSES =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: Consumer<TransactionProvider>(
                  builder: (_, trx, __) {
                    return SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: trx.isLoading ? null : _processCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                        ),
                        child: trx.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 28),
                                  SizedBox(width: 8),
                                  Text(
                                    'PROSES TRANSAKSI',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}