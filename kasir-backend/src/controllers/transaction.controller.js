const { query, getClient } = require('../config/database');
const { successResponse, errorResponse, paginationMeta } = require('../utils/response');
const { generateTransactionNumber } = require('../utils/transactionNumber');

/**
 * POST /api/transactions
 * Buat transaksi baru (Kasir & Admin)
 * Menggunakan database transaction untuk atomisitas:
 * - Semua item berhasil → commit
 * - Satu item gagal (stok kurang, barang tidak ada) → rollback semua
 */
const createTransaction = async (req, res) => {
  const client = await getClient();

  try {
    const { items, discount = 0, tax = 0, payment_amount, notes } = req.body;

    await client.query('BEGIN');

    // 1. Generate nomor transaksi unik
    const transactionNumber = await generateTransactionNumber(
      (text, params) => client.query(text, params)
    );

    // 2. Validasi & ambil semua produk sekaligus (1 query, efisien)
    const productIds = items.map(item => item.product_id);
    const productsResult = await client.query(
      `SELECT id, product_name, selling_price, stock
       FROM products
       WHERE id = ANY($1::uuid[]) AND is_active = true
       FOR UPDATE`, // Row-level lock untuk mencegah race condition
      [productIds]
    );

    // Map produk untuk lookup cepat
    const productMap = {};
    productsResult.rows.forEach(p => { productMap[p.id] = p; });

    // 3. Validasi setiap item
    const processedItems = [];
    let subtotal = 0;

    for (const item of items) {
      const product = productMap[item.product_id];

      if (!product) {
        await client.query('ROLLBACK');
        return errorResponse(res, {
          statusCode: 404,
          message: `Barang dengan ID "${item.product_id}" tidak ditemukan atau tidak aktif.`
        });
      }

      if (product.stock < item.quantity) {
        await client.query('ROLLBACK');
        return errorResponse(res, {
          statusCode: 400,
          message: `Stok "${product.product_name}" tidak mencukupi. Stok tersisa: ${product.stock}, diminta: ${item.quantity}.`
        });
      }

      const itemSubtotal = parseFloat(product.selling_price) * item.quantity;
      subtotal += itemSubtotal;

      processedItems.push({
        product_id: item.product_id,
        product_name: product.product_name,
        quantity: item.quantity,
        current_selling_price: product.selling_price,
        subtotal: itemSubtotal
      });
    }

    // 4. Kalkulasi total akhir
    const discountAmount = parseFloat(discount) || 0;
    const taxAmount = parseFloat(tax) || 0;
    const grandTotal = subtotal - discountAmount + taxAmount;

    if (grandTotal < 0) {
      await client.query('ROLLBACK');
      return errorResponse(res, { statusCode: 400, message: 'Total bayar tidak boleh negatif.' });
    }

    const paymentAmt = parseFloat(payment_amount);
    if (paymentAmt < grandTotal) {
      await client.query('ROLLBACK');
      return errorResponse(res, {
        statusCode: 400,
        message: `Jumlah pembayaran (Rp ${paymentAmt.toLocaleString()}) kurang dari total (Rp ${grandTotal.toLocaleString()}).`
      });
    }

    const changeAmount = paymentAmt - grandTotal;

    // 5. Simpan transaksi header
    const trxResult = await client.query(
      `INSERT INTO transactions
       (transaction_number, subtotal, discount, tax, grand_total, payment_amount, change_amount, notes, cashier_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id, transaction_number, subtotal, discount, tax, grand_total, payment_amount, change_amount, created_at`,
      [transactionNumber, subtotal, discountAmount, taxAmount, grandTotal, paymentAmt, changeAmount, notes || null, req.user.id]
    );

    const transaction = trxResult.rows[0];

    // 6. Simpan detail item & kurangi stok (batch)
    for (const item of processedItems) {
      await client.query(
        `INSERT INTO transaction_details (transaction_id, product_id, quantity, current_selling_price, subtotal)
         VALUES ($1, $2, $3, $4, $5)`,
        [transaction.id, item.product_id, item.quantity, item.current_selling_price, item.subtotal]
      );

      await client.query(
        'UPDATE products SET stock = stock - $1 WHERE id = $2',
        [item.quantity, item.product_id]
      );
    }

    // 7. Commit jika semua berhasil
    await client.query('COMMIT');

    // 8. Response dengan data lengkap untuk struk
    return successResponse(res, {
      statusCode: 201,
      message: 'Transaksi berhasil disimpan.',
      data: {
        ...transaction,
        cashier: {
          id: req.user.id,
          full_name: req.user.full_name
        },
        items: processedItems
      }
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ createTransaction Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal memproses transaksi.' });
  } finally {
    client.release();
  }
};

/**
 * GET /api/transactions
 * Riwayat transaksi
 * Admin: semua transaksi dengan filter
 * Kasir: hanya transaksi milik sendiri
 */
const getAllTransactions = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 100);
    const offset = (page - 1) * limit;
    const dateFrom = req.query.date_from;
    const dateTo = req.query.date_to;

    const conditions = [];
    const params = [];
    let paramCount = 1;

    // Kasir hanya bisa lihat transaksi sendiri
    if (req.user.role === 'kasir') {
      conditions.push(`t.cashier_id = $${paramCount++}`);
      params.push(req.user.id);
    }

    if (dateFrom) {
      conditions.push(`t.created_at >= $${paramCount++}`);
      params.push(dateFrom);
    }

    if (dateTo) {
      conditions.push(`t.created_at <= $${paramCount++}`);
      params.push(dateTo + 'T23:59:59');
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countResult = await query(`SELECT COUNT(*) FROM transactions t ${whereClause}`, params);

    const result = await query(
      `SELECT
         t.id, t.transaction_number, t.subtotal, t.discount, t.tax,
         t.grand_total, t.payment_amount, t.change_amount, t.status, t.created_at,
         u.full_name AS cashier_name
       FROM transactions t
       JOIN users u ON t.cashier_id = u.id
       ${whereClause}
       ORDER BY t.created_at DESC
       LIMIT $${paramCount++} OFFSET $${paramCount++}`,
      [...params, limit, offset]
    );

    return successResponse(res, {
      message: 'Riwayat transaksi berhasil diambil.',
      data: result.rows,
      meta: paginationMeta({ total: parseInt(countResult.rows[0].count), page, limit })
    });

  } catch (err) {
    console.error('❌ getAllTransactions Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal mengambil riwayat transaksi.' });
  }
};

/**
 * GET /api/transactions/:id
 * Detail transaksi beserta item belanja (untuk re-print struk)
 */
const getTransactionById = async (req, res) => {
  try {
    const conditions = ['t.id = $1'];
    const params = [req.params.id];

    // Kasir hanya bisa lihat milik sendiri
    if (req.user.role === 'kasir') {
      conditions.push('t.cashier_id = $2');
      params.push(req.user.id);
    }

    const trxResult = await query(
      `SELECT
         t.id, t.transaction_number, t.subtotal, t.discount, t.tax,
         t.grand_total, t.payment_amount, t.change_amount, t.notes, t.status, t.created_at,
         u.full_name AS cashier_name, u.username AS cashier_username
       FROM transactions t
       JOIN users u ON t.cashier_id = u.id
       WHERE ${conditions.join(' AND ')}`,
      params
    );

    if (trxResult.rows.length === 0) {
      return errorResponse(res, { statusCode: 404, message: 'Transaksi tidak ditemukan.' });
    }

    // Ambil detail item
    const detailsResult = await query(
      `SELECT
         td.id, td.quantity, td.current_selling_price, td.subtotal,
         p.product_name, p.product_code, p.unit
       FROM transaction_details td
       JOIN products p ON td.product_id = p.id
       WHERE td.transaction_id = $1
       ORDER BY p.product_name`,
      [req.params.id]
    );

    return successResponse(res, {
      message: 'Detail transaksi berhasil diambil.',
      data: {
        ...trxResult.rows[0],
        items: detailsResult.rows
      }
    });

  } catch (err) {
    console.error('❌ getTransactionById Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal mengambil detail transaksi.' });
  }
};

/**
 * GET /api/transactions/summary/today
 * Ringkasan penjualan hari ini (Admin only)
 */
const getTodaySummary = async (req, res) => {
  try {
    const result = await query(`
      SELECT
        COUNT(*) AS total_transactions,
        COALESCE(SUM(grand_total), 0) AS total_revenue,
        COALESCE(SUM(discount), 0) AS total_discount,
        COALESCE(SUM(tax), 0) AS total_tax,
        COALESCE(AVG(grand_total), 0) AS avg_transaction
      FROM transactions
      WHERE DATE(created_at) = CURRENT_DATE AND status = 'completed'
    `);

    const topProducts = await query(`
      SELECT
        p.product_name,
        SUM(td.quantity) AS total_qty,
        SUM(td.subtotal) AS total_revenue
      FROM transaction_details td
      JOIN transactions t ON td.transaction_id = t.id
      JOIN products p ON td.product_id = p.id
      WHERE DATE(t.created_at) = CURRENT_DATE AND t.status = 'completed'
      GROUP BY p.id, p.product_name
      ORDER BY total_qty DESC
      LIMIT 5
    `);

    return successResponse(res, {
      message: 'Ringkasan penjualan hari ini.',
      data: {
        summary: result.rows[0],
        top_products: topProducts.rows
      }
    });

  } catch (err) {
    console.error('❌ getTodaySummary Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal mengambil ringkasan.' });
  }
};

module.exports = { createTransaction, getAllTransactions, getTransactionById, getTodaySummary };