const jwt = require('jsonwebtoken');

/**
 * Generate Access Token (short-lived, 8 jam)
 */
const generateAccessToken = (payload) => {
  return jwt.sign(
    {
      sub: payload.id,
      username: payload.username,
      role: payload.role,
      type: 'access'
    },
    process.env.JWT_SECRET,
    {
      expiresIn: process.env.JWT_EXPIRES_IN || '8h',
      issuer: 'kasir-app',
      audience: 'kasir-client'
    }
  );
};

/**
 * Generate Refresh Token (long-lived, 7 hari)
 * Digunakan untuk mendapatkan access token baru tanpa login ulang
 */
const generateRefreshToken = (payload) => {
  return jwt.sign(
    {
      sub: payload.id,
      type: 'refresh'
    },
    process.env.JWT_REFRESH_SECRET,
    {
      expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
      issuer: 'kasir-app',
      audience: 'kasir-client'
    }
  );
};

/**
 * Verifikasi Access Token
 */
const verifyAccessToken = (token) => {
  return jwt.verify(token, process.env.JWT_SECRET, {
    issuer: 'kasir-app',
    audience: 'kasir-client'
  });
};

/**
 * Verifikasi Refresh Token
 */
const verifyRefreshToken = (token) => {
  return jwt.verify(token, process.env.JWT_REFRESH_SECRET, {
    issuer: 'kasir-app',
    audience: 'kasir-client'
  });
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken
};