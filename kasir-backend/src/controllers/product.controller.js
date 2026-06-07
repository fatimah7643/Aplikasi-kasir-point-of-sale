const { query } = require('../config/database');
const { successResponse, errorResponse, paginationMeta } = require('../utils/response');

/**
 * Helper: Filter kolom produk berdasarkan role
 * KEAMANAN UTAMA: Kasir tidak boleh melihat cost_price (harga modal/HPP)
 */
const getProductColumns = (role) => {
  if (role === 'admin') {
    return 'id, product_code, product_name, cost_price, selling_price, stock, unit, is_active, created_at, updated_at';
  }
  // Kasir: cost_price TIDAK disertakan
  return 'id, product_code, product_name, selling_price, stock, unit';
};

/**
 * GET /api/products
 * Daftar produk dengan pencarian
 * Admin: melihat semua termasuk harga modal
 * Kasir: melihat harga jual saja, stok ada
 */
const getAllProducts = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 100);
    const offset = (page - 1) * limit;
    const search = req.query.search?.trim();
    const isActive = req.query.is_active;

    const columns = getProductColumns(req.user.role);
    const conditions = [];
    const params = [];
    let paramCount = 1;

    // Filter active (admin bisa lihat semua, kasir hanya aktif)
    if (req.user.role === 'kasir') {
      conditions.push('is_active = true');
    } else if (isActive !== undefined) {
      conditions.push(`is_active = $${paramCount++}`);
      params.push(isActive === 'true');
    }

    // Pencarian berdasarkan nama (case-insensitive, cepat karena ada index)
    if (search) {
      conditions.push(`LOWER(product_name) LIKE $${paramCount++}`);
      params.push(`%${search.toLowerCase()}%`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    // Count total
    const countResult = await query(
      `SELECT COUNT(*) FROM products ${whereClause}`,
      params
    );

    // Ambil data
    const productsResult = await query(
      `SELECT ${columns} FROM products ${whereClause}
       ORDER BY product_name ASC
       LIMIT $${paramCount++} OFFSET $${paramCount++}`,
      [...params, limit, offset]
    );

    return successResponse(res, {
      message: 'Daftar barang berhasil diambil.',
      data: productsResult.rows,
      meta: paginationMeta({ total: parseInt(countResult.rows[0].count), page, limit })
    });

  } catch (err) {
    console.error('❌ getAllProducts Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal mengambil daftar barang.' });
  }
};

/**
 * GET /api/products/:id
 * Detail produk berdasarkan ID
 */
const getProductById = async (req, res) => {
  try {
    const columns = getProductColumns(req.user.role);
    const activeFilter = req.user.role === 'kasir' ? 'AND is_active = true' : '';

    const result = await query(
      `SELECT ${columns} FROM products WHERE id = $1 ${activeFilter}`,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return errorResponse(res, { statusCode: 404, message: 'Barang tidak ditemukan.' });
    }

    return successResponse(res, { message: 'Detail barang berhasil diambil.', data: result.rows[0] });

  } catch (err) {
    console.error('❌ getProductById Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal mengambil detail barang.' });
  }
};

/**
 * POST /api/products
 * Tambah produk baru (Admin only)
 */
const createProduct = async (req, res) => {
  try {
    const { product_code, product_name, cost_price, selling_price, stock = 0, unit = 'pcs' } = req.body;

    // Validasi harga jual lebih dari harga modal
    if (parseFloat(selling_price) < parseFloat(cost_price)) {
      return errorResponse(res, {
        statusCode: 400,
        message: 'Harga jual tidak boleh lebih rendah dari harga modal.'
      });
    }

    // Cek duplikat kode barang
    if (product_code) {
      const existing = await query('SELECT id FROM products WHERE product_code = $1', [product_code]);
      if (existing.rows.length > 0) {
        return errorResponse(res, { statusCode: 409, message: 'Kode barang sudah digunakan.' });
      }
    }

    const result = await query(
      `INSERT INTO products (product_code, product_name, cost_price, selling_price, stock, unit)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, product_code, product_name, cost_price, selling_price, stock, unit, is_active, created_at`,
      [product_code || null, product_name, cost_price, selling_price, stock, unit]
    );

    return successResponse(res, {
      statusCode: 201,
      message: 'Barang berhasil ditambahkan.',
      data: result.rows[0]
    });

  } catch (err) {
    console.error('❌ createProduct Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal menambahkan barang.' });
  }
};

/**
 * PUT /api/products/:id
 * Update info produk (Admin only)
 */
const updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const { product_name, product_code, cost_price, selling_price, stock, unit, is_active } = req.body;

    const existing = await query(
      'SELECT id, cost_price, selling_price FROM products WHERE id = $1',
      [id]
    );

    if (existing.rows.length === 0) {
      return errorResponse(res, { statusCode: 404, message: 'Barang tidak ditemukan.' });
    }

    const currentProduct = existing.rows[0];

    // Validasi harga: cek kombinasi baru tidak membuat harga jual < harga modal
    const newCostPrice = cost_price !== undefined ? parseFloat(cost_price) : parseFloat(currentProduct.cost_price);
    const newSellingPrice = selling_price !== undefined ? parseFloat(selling_price) : parseFloat(currentProduct.selling_price);

    if (newSellingPrice < newCostPrice) {
      return errorResponse(res, {
        statusCode: 400,
        message: 'Harga jual tidak boleh lebih rendah dari harga modal.'
      });
    }

    const updates = [];
    const params = [];
    let paramCount = 1;

    const fields = { product_name, product_code, cost_price, selling_price, stock, unit, is_active };
    for (const [key, value] of Object.entries(fields)) {
      if (value !== undefined) {
        updates.push(`${key} = $${paramCount++}`);
        params.push(value);
      }
    }

    if (updates.length === 0) {
      return errorResponse(res, { statusCode: 400, message: 'Tidak ada data yang diubah.' });
    }

    params.push(id);
    const result = await query(
      `UPDATE products SET ${updates.join(', ')} WHERE id = $${paramCount}
       RETURNING id, product_code, product_name, cost_price, selling_price, stock, unit, is_active, updated_at`,
      params
    );

    return successResponse(res, { message: 'Barang berhasil diperbarui.', data: result.rows[0] });

  } catch (err) {
    console.error('❌ updateProduct Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal memperbarui barang.' });
  }
};

/**
 * PATCH /api/products/:id/stock
 * Tambah stok barang (Admin only)
 * Menggunakan PATCH + endpoint khusus untuk kejelasan intent
 */
const addStock = async (req, res) => {
  try {
    const { id } = req.params;
    const { quantity } = req.body;

    const result = await query(
      `UPDATE products SET stock = stock + $1
       WHERE id = $2 AND is_active = true
       RETURNING id, product_name, stock`,
      [quantity, id]
    );

    if (result.rows.length === 0) {
      return errorResponse(res, { statusCode: 404, message: 'Barang tidak ditemukan atau tidak aktif.' });
    }

    return successResponse(res, {
      message: `Stok "${result.rows[0].product_name}" berhasil ditambah ${quantity} unit.`,
      data: result.rows[0]
    });

  } catch (err) {
    console.error('❌ addStock Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal menambah stok.' });
  }
};

/**
 * DELETE /api/products/:id
 * Nonaktifkan produk - soft delete (Admin only)
 */
const deleteProduct = async (req, res) => {
  try {
    const result = await query(
      'UPDATE products SET is_active = false WHERE id = $1 RETURNING id, product_name',
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return errorResponse(res, { statusCode: 404, message: 'Barang tidak ditemukan.' });
    }

    return successResponse(res, {
      message: `Barang "${result.rows[0].product_name}" berhasil dihapus.`,
      data: null
    });

  } catch (err) {
    console.error('❌ deleteProduct Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal menghapus barang.' });
  }
};

module.exports = { getAllProducts, getProductById, createProduct, updateProduct, addStock, deleteProduct };