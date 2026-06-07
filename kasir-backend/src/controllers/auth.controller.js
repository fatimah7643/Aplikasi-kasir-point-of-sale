const bcrypt = require('bcrypt');
const { query } = require('../config/database');
const { generateAccessToken, generateRefreshToken, verifyRefreshToken } = require('../utils/jwt');
const { successResponse, errorResponse } = require('../utils/response');

/**
 * POST /api/auth/login
 * Login untuk admin dan kasir
 */
const login = async (req, res) => {
  try {
    const { username, password } = req.body;

    // Cari user berdasarkan username
    const result = await query(
      'SELECT id, username, password, full_name, role, is_active FROM users WHERE username = $1',
      [username.toLowerCase().trim()]
    );

    const user = result.rows[0];

    // Pesan error yang SAMA untuk username/password salah
    // (mencegah username enumeration attack)
    const invalidCredMsg = 'Username atau password salah.';

    if (!user) {
      return errorResponse(res, { statusCode: 401, message: invalidCredMsg });
    }

    if (!user.is_active) {
      return errorResponse(res, { statusCode: 403, message: 'Akun Anda telah dinonaktifkan. Hubungi admin.' });
    }

    // Verifikasi password dengan bcrypt
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return errorResponse(res, { statusCode: 401, message: invalidCredMsg });
    }

    // Generate tokens
    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    // Return data user TANPA password
    const userData = {
      id: user.id,
      username: user.username,
      full_name: user.full_name,
      role: user.role
    };

    return successResponse(res, {
      statusCode: 200,
      message: `Selamat datang, ${user.full_name}!`,
      data: {
        user: userData,
        access_token: accessToken,
        refresh_token: refreshToken,
        token_type: 'Bearer',
        expires_in: process.env.JWT_EXPIRES_IN || '8h'
      }
    });

  } catch (err) {
    console.error('❌ Login Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Terjadi kesalahan saat login.' });
  }
};

/**
 * POST /api/auth/refresh
 * Perbarui access token menggunakan refresh token
 */
const refreshToken = async (req, res) => {
  try {
    const { refresh_token } = req.body;

    if (!refresh_token) {
      return errorResponse(res, { statusCode: 400, message: 'Refresh token wajib diisi.' });
    }

    let decoded;
    try {
      decoded = verifyRefreshToken(refresh_token);
    } catch (err) {
      return errorResponse(res, { statusCode: 401, message: 'Refresh token tidak valid atau telah kadaluarsa.' });
    }

    // Pastikan user masih aktif
    const result = await query(
      'SELECT id, username, full_name, role, is_active FROM users WHERE id = $1',
      [decoded.sub]
    );

    const user = result.rows[0];

    if (!user || !user.is_active) {
      return errorResponse(res, { statusCode: 401, message: 'Akun tidak ditemukan atau tidak aktif.' });
    }

    const newAccessToken = generateAccessToken(user);

    return successResponse(res, {
      message: 'Access token berhasil diperbarui.',
      data: {
        access_token: newAccessToken,
        token_type: 'Bearer',
        expires_in: process.env.JWT_EXPIRES_IN || '8h'
      }
    });

  } catch (err) {
    console.error('❌ Refresh Token Error:', err.message);
    return errorResponse(res, { statusCode: 500, message: 'Terjadi kesalahan.' });
  }
};

/**
 * GET /api/auth/me
 * Ambil profil user yang sedang login
 */
const getMe = async (req, res) => {
  try {
    return successResponse(res, {
      message: 'Profil berhasil diambil.',
      data: {
        id: req.user.id,
        username: req.user.username,
        full_name: req.user.full_name,
        role: req.user.role
      }
    });
  } catch (err) {
    return errorResponse(res, { statusCode: 500, message: 'Terjadi kesalahan.' });
  }
};

module.exports = { login, refreshToken, getMe };