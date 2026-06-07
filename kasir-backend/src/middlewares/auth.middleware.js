const { verifyAccessToken } = require('../utils/jwt');
const { errorResponse } = require('../utils/response');
const { query } = require('../config/database');

/**
 * Middleware: Verifikasi JWT Token
 * Wajib dipasang di semua route yang membutuhkan autentikasi
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(res, {
        statusCode: 401,
        message: 'Akses ditolak. Token tidak ditemukan.'
      });
    }

    const token = authHeader.split(' ')[1];

    let decoded;
    try {
      decoded = verifyAccessToken(token);
    } catch (jwtError) {
      if (jwtError.name === 'TokenExpiredError') {
        return errorResponse(res, {
          statusCode: 401,
          message: 'Sesi telah berakhir. Silakan login kembali.'
        });
      }
      return errorResponse(res, {
        statusCode: 401,
        message: 'Token tidak valid.'
      });
    }

    // Verifikasi user masih aktif di database
    // (penting: admin bisa menonaktifkan user kapan saja)
    const result = await query(
      'SELECT id, username, full_name, role, is_active FROM users WHERE id = $1',
      [decoded.sub]
    );

    if (result.rows.length === 0 || !result.rows[0].is_active) {
      return errorResponse(res, {
        statusCode: 401,
        message: 'Akun tidak ditemukan atau telah dinonaktifkan.'
      });
    }

    // Attach user info ke request untuk digunakan controller
    req.user = result.rows[0];
    next();

  } catch (err) {
    console.error('❌ Auth Middleware Error:', err.message);
    return errorResponse(res, {
      statusCode: 500,
      message: 'Terjadi kesalahan pada verifikasi autentikasi.'
    });
  }
};

/**
 * Middleware: Otorisasi Role
 * Gunakan setelah `authenticate`
 * Contoh: authorize('admin') atau authorize('admin', 'kasir')
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return errorResponse(res, { statusCode: 401, message: 'Tidak terautentikasi.' });
    }

    if (!roles.includes(req.user.role)) {
      return errorResponse(res, {
        statusCode: 403,
        message: `Akses ditolak. Hanya ${roles.join(' atau ')} yang diizinkan.`
      });
    }

    next();
  };
};

module.exports = { authenticate, authorize };