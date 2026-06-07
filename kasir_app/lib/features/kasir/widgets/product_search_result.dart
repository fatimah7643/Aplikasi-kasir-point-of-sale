import 'package:flutter/material.dart';
import '../../../core/models/product_model.dart';

class ProductSearchResult extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const ProductSearchResult({
    super.key,
    required this.product,
    required this.onAdd,
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
    final isOutOfStock = product.stock == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isOutOfStock ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOutOfStock ? Colors.grey : Colors.black,
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Text(
          product.productName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isOutOfStock ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatPrice(product.sellingPrice),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isOutOfStock ? Colors.grey : Colors.blue.shade700,
              ),
            ),
            Text(
              'Stok: ${product.stock} ${product.unit}',
              style: TextStyle(
                fontSize: 13,
                color: product.stock <= 5 ? Colors.orange : Colors.grey,
              ),
            ),
          ],
        ),
        trailing: isOutOfStock
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Text(
                  'Habis',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 20),
                      SizedBox(width: 4),
                      Text(
                        'Tambah',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}