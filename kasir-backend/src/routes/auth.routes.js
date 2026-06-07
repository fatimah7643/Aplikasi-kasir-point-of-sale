const express = require('express');
const router = express.Router();

const { login, refreshToken, getMe } = require('../controllers/auth.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const { loginValidator } = require('../validator');
const { handleValidationErrors } = require('../middlewares/validation.middleware');
const rateLimit = require('express-rate-limit');

// Rate limiter khusus untuk endpoint login (cegah brute force)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 menit
  max: parseInt(process.env.AUTH_RATE_LIMIT_MAX) || 10,
  message: {
    success: false,
    message: 'Terlalu banyak percobaan login. Coba lagi dalam 15 menit.'
  },
  standardHeaders: true,
  legacyHeaders: false
});

/**
 * @route   POST /api/auth/login
 * @desc    Login dan dapatkan JWT token
 * @access  Public
 */
router.post('/login', loginLimiter, loginValidator, handleValidationErrors, login);

/**
 * @route   POST /api/auth/refresh
 * @desc    Perbarui access token dengan refresh token
 * @access  Public
 */
router.post('/refresh', refreshToken);

/**
 * @route   GET /api/auth/me
 * @desc    Ambil profil user yang sedang login
 * @access  Private
 */
router.get('/me', authenticate, getMe);

module.exports = router;