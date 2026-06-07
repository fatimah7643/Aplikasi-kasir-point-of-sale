require('dotenv').config();

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const { testConnection } = require('./config/database');
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const productRoutes = require('./routes/product.routes');
const transactionRoutes = require('./routes/transaction.routes');
const { errorResponse } = require('./utils/response');
const dashboardRoutes = require('./routes/dashboard.routes');

const app = express();

// =============================================
// SECURITY MIDDLEWARE
// =============================================

/**
 * Helmet: Set HTTP security headers
 * - X-Content-Type-Options, X-Frame-Options, HSTS, dll
 */
app.use(helmet());

/**
 * CORS: Izinkan hanya origin yang terdaftar
 */
const allowedOrigins = (process.env.ALLOWED_ORIGINS || 'http://localhost:3000')
  .split(',')
  .map(o => o.trim());

app.use(cors({
  origin: (origin, callback) => {
    // Izinkan request tanpa origin (Postman, mobile app native)
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('CORS: Origin tidak diizinkan.'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));

/**
 * Rate Limiting Global: Cegah DDoS & brute force
 */
const globalLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    success: false,
    message: 'Terlalu banyak request. Coba lagi nanti.'
  },
  standardHeaders: true,
  legacyHeaders: false
});
app.use('/api/', globalLimiter);

// =============================================
// PARSING MIDDLEWARE
// =============================================
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// =============================================
// LOGGING
// =============================================
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// =============================================
// HEALTH CHECK
// =============================================
app.get('/health', async (req, res) => {
  const dbOk = await testConnection().catch(() => false);
  res.status(dbOk ? 200 : 503).json({
    status: dbOk ? 'OK' : 'ERROR',
    service: 'Kasir Backend API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    database: dbOk ? 'Connected' : 'Disconnected'
  });
});

// =============================================
// API ROUTES
// =============================================
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/products', productRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/dashboard', dashboardRoutes);

// =============================================
// 404 HANDLER
// =============================================
app.use((req, res) => {
  errorResponse(res, {
    statusCode: 404,
    message: `Route "${req.method} ${req.originalUrl}" tidak ditemukan.`
  });
});

// =============================================
// GLOBAL ERROR HANDLER
// =============================================
app.use((err, req, res, next) => {
  console.error('❌ Unhandled Error:', err);

  // CORS error
  if (err.message?.includes('CORS')) {
    return errorResponse(res, { statusCode: 403, message: err.message });
  }

  errorResponse(res, {
    statusCode: err.status || 500,
    message: process.env.NODE_ENV === 'production'
      ? 'Terjadi kesalahan pada server.'
      : err.message
  });
});

// =============================================
// START SERVER
// =============================================
const PORT = process.env.PORT || 3000;

const startServer = async () => {
  const dbConnected = await testConnection();

  if (!dbConnected) {
    console.error('❌ Server tidak dapat dimulai: Database tidak terhubung.');
    process.exit(1);
  }

  app.listen(PORT, () => {
    console.log('\n========================================');
    console.log('  🏪 Kasir Backend API');
    console.log('========================================');
    console.log(`  🚀 Server    : http://localhost:${PORT}`);
    console.log(`  🏥 Health    : http://localhost:${PORT}/health`);
    console.log(`  🌍 ENV       : ${process.env.NODE_ENV}`);
    console.log('========================================\n');
  });
};

startServer();

module.exports = app;