const bcrypt = require('bcrypt');
const { query } = require('../config/database');
const { successResponse, errorResponse, paginationMeta } = require('../utils/response');

/**
 * GET /api/users
 * Daftar semua user (Admin only)
 */
const getAllUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const role = req.query.role;

    let whereClause = '';
    const params = [];

    if (role && ['admin', 'kasir'].includes(role)) {
      whereClause = 'WHERE role = $1';
      params.push(role);
    }

    const countResult = await query(
      `SELECT COUNT(*) FROM users ${whereClause}`,
      params
    );

    const usersResult = await query(
      `SELECT id, username, full_name, role, is_active, created_at, updated_at
       FROM users ${whereClause}
       ORDER BY created_at DESC
       LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
      [...params, limit, offset]
    );

    return successResponse(res, {
      message: 'Daftar user berhasil diambil.',
      data: usersResult.rows,
      meta: paginationMeta({ total: parseInt(countResult.rows[0].count), page, limit })
    });

  } catch (err) {
    console.error('❌ getAllUsers Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal mengambil daftar user.' });
  }
};

/**
 * GET /api/users/:id
 * Detail user berdasarkan ID (Admin only)
 */
const getUserById = async (req, res) => {
  try {
    const result = await query(
      'SELECT id, username, full_name, role, is_active, created_at, updated_at FROM users WHERE id = $1',
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return errorResponse(res, { statusCode: 404, message: 'User tidak ditemukan.' });
    }

    return successResponse(res, { message: 'Detail user berhasil diambil.', data: result.rows[0] });

  } catch (err) {
    console.error('❌ getUserById Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal mengambil detail user.' });
  }
};

/**
 * POST /api/users
 * Buat user baru (Admin only)
 */
const createUser = async (req, res) => {
  try {
    const { username, password, full_name, role } = req.body;

    // Cek duplikat username
    const existingUser = await query('SELECT id FROM users WHERE username = $1', [username.toLowerCase()]);
    if (existingUser.rows.length > 0) {
      return errorResponse(res, { statusCode: 409, message: 'Username sudah digunakan.' });
    }

    const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    const result = await query(
      `INSERT INTO users (username, password, full_name, role)
       VALUES ($1, $2, $3, $4)
       RETURNING id, username, full_name, role, is_active, created_at`,
      [username.toLowerCase(), hashedPassword, full_name, role]
    );

    return successResponse(res, {
      statusCode: 201,
      message: 'User berhasil dibuat.',
      data: result.rows[0]
    });

  } catch (err) {
    console.error('❌ createUser Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal membuat user.' });
  }
};

/**
 * PUT /api/users/:id
 * Update user (Admin only)
 */
const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { full_name, password, is_active } = req.body;

    // Cek user exists
    const existing = await query('SELECT id FROM users WHERE id = $1', [id]);
    if (existing.rows.length === 0) {
      return errorResponse(res, { statusCode: 404, message: 'User tidak ditemukan.' });
    }

    // Cegah admin menonaktifkan diri sendiri
    if (req.user.id === id && is_active === false) {
      return errorResponse(res, {
        statusCode: 400,
        message: 'Anda tidak dapat menonaktifkan akun Anda sendiri.'
      });
    }

    const updates = [];
    const params = [];
    let paramCount = 1;

    if (full_name !== undefined) {
      updates.push(`full_name = $${paramCount++}`);
      params.push(full_name);
    }

    if (password !== undefined) {
      const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12;
      const hashedPassword = await bcrypt.hash(password, saltRounds);
      updates.push(`password = $${paramCount++}`);
      params.push(hashedPassword);
    }

    if (is_active !== undefined) {
      updates.push(`is_active = $${paramCount++}`);
      params.push(is_active);
    }

    if (updates.length === 0) {
      return errorResponse(res, { statusCode: 400, message: 'Tidak ada data yang diubah.' });
    }

    params.push(id);
    const result = await query(
      `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramCount}
       RETURNING id, username, full_name, role, is_active, updated_at`,
      params
    );

    return successResponse(res, { message: 'User berhasil diperbarui.', data: result.rows[0] });

  } catch (err) {
    console.error('❌ updateUser Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal memperbarui user.' });
  }
};

/**
 * DELETE /api/users/:id
 * Hapus user (Admin only) - Soft delete via is_active = false
 */
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    if (req.user.id === id) {
      return errorResponse(res, { statusCode: 400, message: 'Anda tidak dapat menghapus akun Anda sendiri.' });
    }

    const result = await query(
      'UPDATE users SET is_active = false WHERE id = $1 RETURNING id, username',
      [id]
    );

    if (result.rows.length === 0) {
      return errorResponse(res, { statusCode: 404, message: 'User tidak ditemukan.' });
    }

    return successResponse(res, {
      message: `User "${result.rows[0].username}" berhasil dinonaktifkan.`,
      data: null
    });

  } catch (err) {
    console.error('❌ deleteUser Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Gagal menghapus user.' });
  }
};

module.exports = { getAllUsers, getUserById, createUser, updateUser, deleteUser };