const express = require('express');
const router = express.Router();

const {
  getAllProducts, getProductById, createProduct,
  updateProduct, addStock, deleteProduct
} = require('../controllers/product.controller');

const { authenticate, authorize } = require('../middlewares/auth.middleware');
const { createProductValidator, updateProductValidator, addStockValidator } = require('../validator');
const { handleValidationErrors } = require('../middlewares/validation.middleware');

// Semua route produk memerlukan autentikasi
router.use(authenticate);

// Read: Admin & Kasir
router.get('/', getAllProducts);
router.get('/:id', getProductById);

// Write: Admin only
router.post('/', authorize('admin'), createProductValidator, handleValidationErrors, createProduct);
router.put('/:id', authorize('admin'), updateProductValidator, handleValidationErrors, updateProduct);
router.patch('/:id/stock', authorize('admin'), addStockValidator, handleValidationErrors, addStock);
router.delete('/:id', authorize('admin'), deleteProduct);

module.exports = router;