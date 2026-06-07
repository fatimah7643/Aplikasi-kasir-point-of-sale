const express = require('express');
const router = express.Router();

const { getAllUsers, getUserById, createUser, updateUser, deleteUser } = require('../controllers/user.controller');
const { authenticate, authorize } = require('../middlewares/auth.middleware');
const { createUserValidator, updateUserValidator } = require('../validator');
const { handleValidationErrors } = require('../middlewares/validation.middleware');

// Semua route user hanya untuk Admin
router.use(authenticate, authorize('admin'));

router.get('/', getAllUsers);
router.get('/:id', getUserById);
router.post('/', createUserValidator, handleValidationErrors, createUser);
router.put('/:id', updateUserValidator, handleValidationErrors, updateUser);
router.delete('/:id', deleteUser);

module.exports = router;