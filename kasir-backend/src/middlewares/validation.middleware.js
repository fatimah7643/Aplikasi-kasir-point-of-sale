const { validationResult } = require('express-validator');
const { errorResponse } = require('../utils/response');

/**
 * Middleware: Tangkap error validasi dari express-validator
 * Dipasang setelah chain validasi di route
 */
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map(err => ({
      field: err.path,
      message: err.msg
    }));

    return errorResponse(res, {
      statusCode: 422,
      message: 'Data yang dikirim tidak valid.',
      errors: formattedErrors
    });
  }

  next();
};

module.exports = { handleValidationErrors };