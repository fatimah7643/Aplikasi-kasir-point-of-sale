const express = require('express');
const router = express.Router();

const { getDashboardSummary, getWeeklyChart, getTopProducts, getProfitSummary, getDailyProfit, exportTransactionsCSV } = require('../controllers/dashboard.controller');
const { authenticate, authorize } = require('../middlewares/auth.middleware');

// Semua dashboard route: Admin only
router.use(authenticate, authorize('admin'));

router.get('/summary',       getDashboardSummary);
router.get('/chart/weekly',  getWeeklyChart);
router.get('/top-products',  getTopProducts);
router.get('/profit/daily',  getDailyProfit);
router.get('/profit/summary', getProfitSummary);
router.get('/transactions/export', exportTransactionsCSV);
module.exports = router;