/**
 * Standarisasi format respons API
 * Semua respons menggunakan format yang konsisten
 */

const successResponse = (res, { statusCode = 200, message = 'Berhasil', data = null, meta = null }) => {
  const response = { success: true, message };
  if (data !== null) response.data = data;
  if (meta !== null) response.meta = meta;
  return res.status(statusCode).json(response);
};

const errorResponse = (res, { statusCode = 500, message = 'Terjadi kesalahan server', errors = null }) => {
  const response = { success: false, message };
  if (errors !== null) response.errors = errors;

  // Jangan expose stack trace di production
  if (process.env.NODE_ENV === 'development' && errors instanceof Error) {
    response.stack = errors.stack;
  }

  return res.status(statusCode).json(response);
};

const paginationMeta = ({ total, page, limit }) => ({
  total,
  page: parseInt(page),
  limit: parseInt(limit),
  total_pages: Math.ceil(total / limit),
  has_next: page * limit < total,
  has_prev: page > 1
});

module.exports = { successResponse, errorResponse, paginationMeta };