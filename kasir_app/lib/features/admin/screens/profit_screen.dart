import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/profit_provider.dart';
import '../../../core/models/profit_model.dart';

class ProfitScreen extends StatefulWidget {
  const ProfitScreen({super.key});

  @override
  State<ProfitScreen> createState() => _ProfitScreenState();
}

class _ProfitScreenState extends State<ProfitScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfitProvider>().loadProfit('today');
    });
  }

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

  Widget _periodButton(String period, String label) {
    return Consumer<ProfitProvider>(
      builder: (_, provider, __) {
        final isSelected = provider.selectedPeriod == period;
        return GestureDetector(
          onTap: () => provider.loadProfit(period),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade700 : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatPrice(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(ProfitSummary summary) {
    return Column(
      children: [
        // Laba Bersih - highlight utama
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Column(
            children: [
              const Text(
                'LABA BERSIH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatPrice(summary.netProfit),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Margin: ${summary.marginPercent.toStringAsFixed(1)}%  •  ${summary.totalTransactions} transaksi',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Grid summary
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Total Omzet',
                amount: summary.totalRevenue,
                color: Colors.blue.shade700,
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                title: 'Total Modal',
                amount: summary.totalCost,
                color: Colors.red.shade600,
                icon: Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Laba Kotor',
                amount: summary.totalProfit,
                color: Colors.orange.shade700,
                icon: Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                title: 'Total Diskon',
                amount: summary.totalDiscount,
                color: Colors.purple.shade600,
                icon: Icons.discount,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerProductSection(List<ProfitPerProduct> products) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Center(
          child: Text(
            'Belum ada data penjualan',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'Laba Per Produk (Top 10)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          ...products.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            final isLast = index == products.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Rank
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: index < 3
                              ? Colors.amber.shade700
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color:
                                index < 3 ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Info produk
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.productName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Terjual: ${product.totalQty} • Margin: ${product.marginPercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Laba
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatPrice(product.totalProfit),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'omzet ${_formatPrice(product.totalRevenue)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(height: 1, thickness: 1, indent: 52),
              ],
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          'REKAP LABA',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _periodButton('today', 'Hari Ini'),
                const SizedBox(width: 8),
                _periodButton('week', 'Minggu Ini'),
                const SizedBox(width: 8),
                _periodButton('month', 'Bulan Ini'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Consumer<ProfitProvider>(
              builder: (_, provider, __) {
                if (provider.isLoading) {
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
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              provider.loadProfit(provider.selectedPeriod),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.summary == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final summary = provider.summary!;

                return RefreshIndicator(
                  onRefresh: () => provider.loadProfit(provider.selectedPeriod),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummarySection(summary),
                      const SizedBox(height: 16),
                      _buildPerProductSection(summary.perProduct),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}