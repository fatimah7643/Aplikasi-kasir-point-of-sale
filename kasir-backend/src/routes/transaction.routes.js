const express = require('express');
const router = express.Router();

const { createTransaction, getAllTransactions, getTransactionById, getTodaySummary } = require('../controllers/transaction.controller');
const { authenticate, authorize } = require('../middlewares/auth.middleware');
const { createTransactionValidator } = require('../validator');
const { handleValidationErrors } = require('../middlewares/validation.middleware');

router.use(authenticate);

// Ringkasan hari ini - Admin only (letakkan sebelum /:id agar tidak bentrok)
router.get('/summary/today', authorize('admin'), getTodaySummary);

// Riwayat: Admin lihat semua, Kasir lihat milik sendiri
router.get('/', getAllTransactions);

// Detail transaksi: Admin lihat semua, Kasir lihat milik sendiri
router.get('/:id', getTransactionById);

// Buat transaksi: Admin & Kasir
router.post('/', createTransactionValidator, handleValidationErrors, createTransaction);

module.exports = router;