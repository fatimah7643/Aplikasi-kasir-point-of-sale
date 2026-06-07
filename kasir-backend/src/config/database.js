const { Pool } = require('pg');


/**
 * PostgreSQL Connection Pool
 * Menggunakan connection pool untuk efisiensi koneksi
 * dan keamanan terhadap SQL Injection (via parameterized queries)
 */
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false
  },
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

// Event listener untuk monitoring koneksi
pool.on('connect', () => {
  if (process.env.NODE_ENV === 'development') {
    console.log('✅ Database: Koneksi baru dibuat');
  }
});

pool.on('error', (err) => {
  console.error('❌ Database Error:', err.message);
  process.exit(-1);
});

/**
 * Helper query dengan logging di development
 */
const query = async (text, params) => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;

    if (process.env.NODE_ENV === 'development') {
      console.log('🗃️  Query:', { text: text.substring(0, 80), duration: `${duration}ms`, rows: res.rowCount });
    }

    return res;
  } catch (err) {
    console.error('❌ Query Error:', err.message);
    throw err;
  }
};

/**
 * Helper untuk transaksi database (BEGIN/COMMIT/ROLLBACK)
 */
const getClient = async () => {
  const client = await pool.connect();
  const originalQuery = client.query.bind(client);

  // Wrapper untuk logging di development
  client.query = async (text, params) => {
    const start = Date.now();
    const res = await originalQuery(text, params);
    const duration = Date.now() - start;

    if (process.env.NODE_ENV === 'development') {
      console.log('🔄 Transaction Query:', { text: text.substring(0, 80), duration: `${duration}ms` });
    }
    return res;
  };

  return client;
};

const testConnection = async () => {
  try {
    const result = await query('SELECT NOW() as current_time');
    console.log('✅ Database terhubung:', result.rows[0].current_time);
    return true;
  } catch (err) {
    console.error('❌ Gagal terhubung ke database:', err.message);
    return false;
  }
};

module.exports = { query, getClient, pool, testConnection };