const { body, query, param } = require('express-validator');

// =============================================
// AUTH VALIDATORS
// =============================================
const loginValidator = [
  body('username')
    .trim()
    .notEmpty().withMessage('Username wajib diisi.')
    .isLength({ min: 3, max: 50 }).withMessage('Username harus 3-50 karakter.')
    .matches(/^[a-zA-Z0-9_]+$/).withMessage('Username hanya boleh huruf, angka, dan underscore.'),

  body('password')
    .notEmpty().withMessage('Password wajib diisi.')
    .isLength({ min: 6 }).withMessage('Password minimal 6 karakter.')
];

// =============================================
// USER VALIDATORS (Admin only)
// =============================================
const createUserValidator = [
  body('username')
    .trim()
    .notEmpty().withMessage('Username wajib diisi.')
    .isLength({ min: 3, max: 50 }).withMessage('Username harus 3-50 karakter.')
    .matches(/^[a-zA-Z0-9_]+$/).withMessage('Username hanya boleh huruf, angka, dan underscore.'),

  body('password')
    .notEmpty().withMessage('Password wajib diisi.')
    .isLength({ min: 8 }).withMessage('Password minimal 8 karakter.')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/).withMessage('Password harus mengandung huruf besar, huruf kecil, dan angka.'),

  body('full_name')
    .trim()
    .notEmpty().withMessage('Nama lengkap wajib diisi.')
    .isLength({ min: 2, max: 100 }).withMessage('Nama lengkap harus 2-100 karakter.'),

  body('role')
    .notEmpty().withMessage('Role wajib diisi.')
    .isIn(['admin', 'kasir']).withMessage('Role harus admin atau kasir.')
];

const updateUserValidator = [
  param('id').isUUID().withMessage('ID user tidak valid.'),

  body('full_name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 }).withMessage('Nama lengkap harus 2-100 karakter.'),

  body('password')
    .optional()
    .isLength({ min: 8 }).withMessage('Password minimal 8 karakter.')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/).withMessage('Password harus mengandung huruf besar, huruf kecil, dan angka.'),

  body('is_active')
    .optional()
    .isBoolean().withMessage('is_active harus bernilai true atau false.')
];

// =============================================
// PRODUCT VALIDATORS
// =============================================
const createProductValidator = [
  body('product_name')
    .trim()
    .notEmpty().withMessage('Nama barang wajib diisi.')
    .isLength({ min: 2, max: 150 }).withMessage('Nama barang harus 2-150 karakter.'),

  body('product_code')
    .optional({ nullable: true })
    .trim()
    .isLength({ max: 50 }).withMessage('Kode barang maksimal 50 karakter.'),

  body('cost_price')
    .notEmpty().withMessage('Harga modal wajib diisi.')
    .isFloat({ min: 0 }).withMessage('Harga modal harus angka positif.'),

  body('selling_price')
    .notEmpty().withMessage('Harga jual wajib diisi.')
    .isFloat({ min: 0 }).withMessage('Harga jual harus angka positif.'),

  body('stock')
    .optional()
    .isInt({ min: 0 }).withMessage('Stok harus bilangan bulat positif.'),

  body('unit')
    .optional()
    .trim()
    .isLength({ max: 20 }).withMessage('Satuan maksimal 20 karakter.')
];

const updateProductValidator = [
  param('id').isUUID().withMessage('ID barang tidak valid.'),

  body('product_name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 150 }).withMessage('Nama barang harus 2-150 karakter.'),

  body('cost_price')
    .optional()
    .isFloat({ min: 0 }).withMessage('Harga modal harus angka positif.'),

  body('selling_price')
    .optional()
    .isFloat({ min: 0 }).withMessage('Harga jual harus angka positif.'),

  body('stock')
    .optional()
    .isInt({ min: 0 }).withMessage('Stok harus bilangan bulat positif.'),

  body('unit')
    .optional()
    .trim()
    .isLength({ max: 20 }).withMessage('Satuan maksimal 20 karakter.')
];

const addStockValidator = [
  param('id').isUUID().withMessage('ID barang tidak valid.'),

  body('quantity')
    .notEmpty().withMessage('Jumlah penambahan stok wajib diisi.')
    .isInt({ min: 1 }).withMessage('Jumlah stok harus minimal 1.')
];

// =============================================
// TRANSACTION VALIDATORS
// =============================================
const createTransactionValidator = [
  body('items')
    .isArray({ min: 1 }).withMessage('Minimal 1 barang harus dimasukkan ke keranjang.'),

  body('items.*.product_id')
    .isUUID().withMessage('ID barang tidak valid.'),

  body('items.*.quantity')
    .isInt({ min: 1 }).withMessage('Jumlah barang minimal 1.'),

  body('discount')
    .optional()
    .isFloat({ min: 0 }).withMessage('Diskon harus angka positif.'),

  body('tax')
    .optional()
    .isFloat({ min: 0 }).withMessage('Pajak harus angka positif.'),

  body('payment_amount')
    .notEmpty().withMessage('Jumlah pembayaran wajib diisi.')
    .isFloat({ min: 0 }).withMessage('Jumlah pembayaran harus angka positif.')
];

module.exports = {
  loginValidator,
  createUserValidator,
  updateUserValidator,
  createProductValidator,
  updateProductValidator,
  addStockValidator,
  createTransactionValidator
};