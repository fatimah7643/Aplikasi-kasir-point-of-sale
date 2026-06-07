import 'package:flutter/material.dart';
import '../../../core/models/cart_item_model.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        children: [
          // Info Produk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(item.product.sellingPrice),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                  ),
                ),
                Text(
                  'Subtotal: ${_formatPrice(item.subtotal)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Kontrol Qty
          Column(
            children: [
              // Tombol Hapus
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Tombol +/-
              Row(
                children: [
                  // Tombol Minus
                  GestureDetector(
                    onTap: onDecrease,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: const Icon(
                        Icons.remove,
                        color: Colors.red,
                        size: 22,
                      ),
                    ),
                  ),

                  // Qty
                  Container(
                    width: 44,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Tombol Plus
                  GestureDetector(
                    onTap: onIncrease,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.green,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}