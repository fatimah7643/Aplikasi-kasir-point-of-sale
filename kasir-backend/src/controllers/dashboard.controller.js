const { query } = require('../config/database');
const { successResponse, errorResponse } = require('../utils/response');

/**
 * GET /api/dashboard/summary
 * Summary hari ini: omzet, jumlah transaksi, rata-rata transaksi
 */
const getDashboardSummary = async (req, res) => {
  try {
    // Summary hari ini
    const todayResult = await query(`
      SELECT
        COUNT(*)::int                         AS total_transactions,
        COALESCE(SUM(grand_total), 0)::float  AS total_revenue,
        COALESCE(AVG(grand_total), 0)::float  AS avg_transaction,
        COALESCE(SUM(discount), 0)::float     AS total_discount
      FROM transactions
      WHERE DATE(created_at AT TIME ZONE 'Asia/Makassar') = CURRENT_DATE AT TIME ZONE 'Asia/Makassar'
        AND status = 'completed'
    `);

    // Summary kemarin (untuk perbandingan % naik/turun)
    const yesterdayResult = await query(`
      SELECT
        COUNT(*)::int                         AS total_transactions,
        COALESCE(SUM(grand_total), 0)::float  AS total_revenue
      FROM transactions
      WHERE DATE(created_at AT TIME ZONE 'Asia/Makassar') =
            (CURRENT_DATE AT TIME ZONE 'Asia/Makassar') - INTERVAL '1 day'
        AND status = 'completed'
    `);

    const today = todayResult.rows[0];
    const yesterday = yesterdayResult.rows[0];

    // Hitung persentase perubahan omzet
    const revenueChange = yesterday.total_revenue > 0
      ? ((today.total_revenue - yesterday.total_revenue) / yesterday.total_revenue * 100)
      : (today.total_revenue > 0 ? 100 : 0);

    const transactionChange = yesterday.total_transactions > 0
      ? ((today.total_transactions - yesterday.total_transactions) / yesterday.total_transactions * 100)
      : (today.total_transactions > 0 ? 100 : 0);

    return successResponse(res, {
      message: 'Dashboard summary berhasil diambil.',
      data: {
        today: {
          total_revenue: parseFloat(today.total_revenue),
          total_transactions: today.total_transactions,
          avg_transaction: parseFloat(today.avg_transaction),
          total_discount: parseFloat(today.total_discount),
        },
        comparison: {
          revenue_change_percent: parseFloat(revenueChange.toFixed(1)),
          transaction_change_percent: parseFloat(transactionChange.toFixed(1)),
        }
      }
    });

  } catch (err) {
    console.error('❌ getDashboardSummary Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal mengambil dashboard summary.' });
  }
};

/**
 * GET /api/dashboard/chart/weekly
 * Data grafik omzet 7 hari terakhir
 */
const getWeeklyChart = async (req, res) => {
  try {
    const result = await query(`
      SELECT
        TO_CHAR(
          generate_series::date, 'YYYY-MM-DD'
        ) AS date,
        TO_CHAR(
          generate_series::date, 'DD Mon'
        ) AS label,
        COALESCE(SUM(t.grand_total), 0)::float   AS total_revenue,
        COUNT(t.id)::int                          AS total_transactions
      FROM generate_series(
        (CURRENT_DATE AT TIME ZONE 'Asia/Makassar') - INTERVAL '6 days',
        (CURRENT_DATE AT TIME ZONE 'Asia/Makassar'),
        '1 day'::interval
      ) AS generate_series
      LEFT JOIN transactions t
        ON DATE(t.created_at AT TIME ZONE 'Asia/Makassar') = generate_series::date
        AND t.status = 'completed'
      GROUP BY generate_series::date
      ORDER BY generate_series::date ASC
    `);

    return successResponse(res, {
      message: 'Data grafik 7 hari berhasil diambil.',
      data: result.rows
    });

  } catch (err) {
    console.error('❌ getWeeklyChart Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal mengambil data grafik.' });
  }
};

/**
 * GET /api/dashboard/top-products
 * Produk terlaris hari ini (top 5)
 */
const getTopProducts = async (req, res) => {
  try {
    const result = await query(`
      SELECT
        p.product_name,
        p.unit,
        SUM(td.quantity)::int       AS total_qty,
        SUM(td.subtotal)::float     AS total_revenue
      FROM transaction_details td
      JOIN transactions t ON td.transaction_id = t.id
      JOIN products p ON td.product_id = p.id
      WHERE DATE(t.created_at AT TIME ZONE 'Asia/Makassar') = CURRENT_DATE AT TIME ZONE 'Asia/Makassar'
        AND t.status = 'completed'
      GROUP BY p.id, p.product_name, p.unit
      ORDER BY total_qty DESC
      LIMIT 5
    `);

    return successResponse(res, {
      message: 'Produk terlaris berhasil diambil.',
      data: result.rows
    });

  } catch (err) {
    console.error('❌ getTopProducts Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal mengambil produk terlaris.' });
  }
};

/**
 * GET /api/dashboard/profit
 * Rekap laba berdasarkan periode (today/week/month)
 */
const getProfitSummary = async (req, res) => {
  try {
    const period = req.query.period || 'today';

    let dateFilter;
    switch (period) {
      case 'week':
        dateFilter = `DATE(t.created_at) >= CURRENT_DATE - INTERVAL '7 days'`;
        break;
      case 'month':
        dateFilter = `DATE_TRUNC('month', t.created_at) = DATE_TRUNC('month', CURRENT_DATE)`;
        break;
      default: // today
        dateFilter = `DATE(t.created_at) = CURRENT_DATE`;
    }

    // Total laba periode
    const summaryResult = await query(`
      SELECT
        COUNT(DISTINCT t.id) AS total_transactions,
        COALESCE(SUM(td.quantity * td.current_selling_price), 0) AS total_revenue,
        COALESCE(SUM(td.quantity * p.cost_price), 0) AS total_cost,
        COALESCE(SUM(td.quantity * (td.current_selling_price - p.cost_price)), 0) AS total_profit,
        COALESCE(SUM(t.discount), 0) AS total_discount
      FROM transactions t
      JOIN transaction_details td ON t.id = td.transaction_id
      JOIN products p ON td.product_id = p.id
      WHERE ${dateFilter} AND t.status = 'completed'
    `);

    // Laba per produk periode ini
    const perProductResult = await query(`
      SELECT
        p.product_name,
        p.cost_price,
        SUM(td.quantity) AS total_qty,
        SUM(td.quantity * td.current_selling_price) AS total_revenue,
        SUM(td.quantity * p.cost_price) AS total_cost,
        SUM(td.quantity * (td.current_selling_price - p.cost_price)) AS total_profit,
        CASE
          WHEN SUM(td.quantity * p.cost_price) > 0
          THEN ROUND(
            SUM(td.quantity * (td.current_selling_price - p.cost_price)) /
            SUM(td.quantity * p.cost_price) * 100, 1
          )
          ELSE 0
        END AS margin_percent
      FROM transaction_details td
      JOIN transactions t ON td.transaction_id = t.id
      JOIN products p ON td.product_id = p.id
      WHERE ${dateFilter} AND t.status = 'completed'
      GROUP BY p.id, p.product_name, p.cost_price
      ORDER BY total_profit DESC
      LIMIT 10
    `);

    const summary = summaryResult.rows[0];
    const netProfit = parseFloat(summary.total_profit) - parseFloat(summary.total_discount);

    return successResponse(res, {
      message: `Rekap laba ${period} berhasil diambil.`,
      data: {
        period,
        summary: {
          total_transactions: parseInt(summary.total_transactions),
          total_revenue: parseFloat(summary.total_revenue),
          total_cost: parseFloat(summary.total_cost),
          total_profit: parseFloat(summary.total_profit),
          total_discount: parseFloat(summary.total_discount),
          net_profit: netProfit < 0 ? 0 : netProfit,
          margin_percent: parseFloat(summary.total_revenue) > 0
            ? ((parseFloat(summary.total_profit) / parseFloat(summary.total_revenue)) * 100).toFixed(1)
            : 0
        },
        per_product: perProductResult.rows
      }
    });

  } catch (err) {
    console.error('❌ getProfitSummary Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal mengambil rekap laba.' });
  }
};

/**
 * GET /api/dashboard/profit/daily
 * Laba harian 30 hari terakhir
 */
const getDailyProfit = async (req, res) => {
  try {
    const result = await query(`
      SELECT
        DATE(t.created_at) AS date,
        COALESCE(SUM(td.quantity * td.current_selling_price), 0) AS revenue,
        COALESCE(SUM(td.quantity * p.cost_price), 0) AS cost,
        COALESCE(SUM(td.quantity * (td.current_selling_price - p.cost_price)), 0) AS profit
      FROM transactions t
      JOIN transaction_details td ON t.id = td.transaction_id
      JOIN products p ON td.product_id = p.id
      WHERE DATE(t.created_at) >= CURRENT_DATE - INTERVAL '30 days'
        AND t.status = 'completed'
      GROUP BY DATE(t.created_at)
      ORDER BY date ASC
    `);

    return successResponse(res, {
      message: 'Laba harian 30 hari berhasil diambil.',
      data: result.rows
    });

  } catch (err) {
    console.error('❌ getDailyProfit Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal mengambil laba harian.' });
  }
};

/**
 * GET /api/dashboard/export/transactions
 * Export transaksi ke CSV dengan filter tanggal
 */
const exportTransactionsCSV = async (req, res) => {
  try {
    const { date_from, date_to } = req.query;

    const conditions = ["t.status = 'completed'"];
    const params = [];
    let paramCount = 1;

    if (date_from) {
      conditions.push(`DATE(t.created_at) >= $${paramCount++}`);
      params.push(date_from);
    }

    if (date_to) {
      conditions.push(`DATE(t.created_at) <= $${paramCount++}`);
      params.push(date_to);
    }

    const whereClause = `WHERE ${conditions.join(' AND ')}`;

    const result = await query(`
      SELECT
        t.transaction_number                          AS "No. Transaksi",
        TO_CHAR(t.created_at AT TIME ZONE 'Asia/Makassar', 'DD/MM/YYYY HH24:MI') AS "Tanggal",
        u.full_name                                   AS "Kasir",
        p.product_name                                AS "Nama Barang",
        p.product_code                                AS "Kode Barang",
        td.quantity                                   AS "Qty",
        p.unit                                        AS "Satuan",
        td.current_selling_price                      AS "Harga Jual",
        p.cost_price                                  AS "Harga Modal",
        td.subtotal                                   AS "Subtotal Jual",
        (td.quantity * p.cost_price)                  AS "Subtotal Modal",
        (td.subtotal - (td.quantity * p.cost_price))  AS "Laba Item",
        t.discount                                    AS "Diskon",
        t.grand_total                                 AS "Total Bayar",
        t.payment_amount                              AS "Uang Bayar",
        t.change_amount                               AS "Kembalian"
      FROM transactions t
      JOIN transaction_details td ON t.id = td.transaction_id
      JOIN products p ON td.product_id = p.id
      JOIN users u ON t.cashier_id = u.id
      ${whereClause}
      ORDER BY t.created_at DESC, p.product_name ASC
    `, params);

    if (result.rows.length === 0) {
      return errorResponse(res, {
        statusCode: 404,
        message: 'Tidak ada data transaksi pada periode yang dipilih.'
      });
    }

    // Generate CSV
    const headers = Object.keys(result.rows[0]);
    const csvRows = [
      // Header baris info
      `"LAPORAN TRANSAKSI KASIR APP"`,
      `"Periode: ${date_from || 'Semua'} s/d ${date_to || 'Semua'}"`,
      `"Diekspor: ${new Date().toLocaleDateString('id-ID')}"`,
      `""`,
      // Header kolom
      headers.map(h => `"${h}"`).join(','),
      // Data rows
      ...result.rows.map(row =>
        headers.map(h => {
          const val = row[h];
          if (val === null || val === undefined) return '""';
          // Angka tidak perlu quotes
          if (typeof val === 'number' || (!isNaN(val) && val !== '')) {
            return val;
          }
          // String dengan escape quote
          return `"${String(val).replace(/"/g, '""')}"`;
        }).join(',')
      )
    ];

    const csvContent = csvRows.join('\n');

    // Set header response sebagai file download
    const filename = `laporan-transaksi-${date_from || 'semua'}-sd-${date_to || 'semua'}.csv`;
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

    // BOM untuk Excel agar karakter Indonesia terbaca
    res.send('\uFEFF' + csvContent);

  } catch (err) {
    console.error('❌ exportTransactionsCSV Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal mengekspor data.' });
  }
};

module.exports = { getDashboardSummary, getWeeklyChart, getTopProducts, getDailyProfit, getProfitSummary, exportTransactionsCSV };