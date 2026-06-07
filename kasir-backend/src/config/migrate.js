require('dotenv').config();
const { query, testConnection } = require('./database');

const migrations = [
  {
    name: 'create_users_table',
    sql: `
      CREATE TABLE IF NOT EXISTS users (
        id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        username    VARCHAR(50) UNIQUE NOT NULL,
        password    TEXT NOT NULL,
        full_name   VARCHAR(100) NOT NULL,
        role        VARCHAR(10) NOT NULL CHECK (role IN ('admin', 'kasir')),
        is_active   BOOLEAN DEFAULT true,
        created_at  TIMESTAMPTZ DEFAULT NOW(),
        updated_at  TIMESTAMPTZ DEFAULT NOW()
      );

      -- Index untuk pencarian username (login)
      CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
      CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
    `
  },
  {
    name: 'create_products_table',
    sql: `
      CREATE TABLE IF NOT EXISTS products (
        id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        product_code    VARCHAR(50) UNIQUE,
        product_name    VARCHAR(150) NOT NULL,
        cost_price      NUMERIC(15, 2) NOT NULL DEFAULT 0 CHECK (cost_price >= 0),
        selling_price   NUMERIC(15, 2) NOT NULL DEFAULT 0 CHECK (selling_price >= 0),
        stock           INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
        unit            VARCHAR(20) DEFAULT 'pcs',
        is_active       BOOLEAN DEFAULT true,
        created_at      TIMESTAMPTZ DEFAULT NOW(),
        updated_at      TIMESTAMPTZ DEFAULT NOW()
      );

      -- Index untuk pencarian nama produk (ILIKE) - performa pencarian manual
      CREATE INDEX IF NOT EXISTS idx_products_name ON products USING gin(to_tsvector('indonesian', product_name));
      CREATE INDEX IF NOT EXISTS idx_products_name_ilike ON products(LOWER(product_name));
      CREATE INDEX IF NOT EXISTS idx_products_code ON products(product_code);
      CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
    `
  },
  {
    name: 'create_transactions_table',
    sql: `
      CREATE TABLE IF NOT EXISTS transactions (
        id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        transaction_number  VARCHAR(30) UNIQUE NOT NULL,
        subtotal            NUMERIC(15, 2) NOT NULL DEFAULT 0,
        discount            NUMERIC(15, 2) NOT NULL DEFAULT 0 CHECK (discount >= 0),
        tax                 NUMERIC(15, 2) NOT NULL DEFAULT 0 CHECK (tax >= 0),
        grand_total         NUMERIC(15, 2) NOT NULL DEFAULT 0,
        payment_amount      NUMERIC(15, 2) NOT NULL DEFAULT 0,
        change_amount       NUMERIC(15, 2) NOT NULL DEFAULT 0,
        notes               TEXT,
        status              VARCHAR(20) DEFAULT 'completed' CHECK (status IN ('completed', 'void')),
        cashier_id          UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
        created_at          TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE INDEX IF NOT EXISTS idx_transactions_number ON transactions(transaction_number);
      CREATE INDEX IF NOT EXISTS idx_transactions_cashier ON transactions(cashier_id);
      CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
    `
  },
  {
    name: 'create_transaction_details_table',
    sql: `
      CREATE TABLE IF NOT EXISTS transaction_details (
        id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        transaction_id        UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
        product_id            UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
        quantity              INTEGER NOT NULL CHECK (quantity > 0),
        current_selling_price NUMERIC(15, 2) NOT NULL,
        subtotal              NUMERIC(15, 2) NOT NULL,
        created_at            TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE INDEX IF NOT EXISTS idx_transaction_details_trx ON transaction_details(transaction_id);
      CREATE INDEX IF NOT EXISTS idx_transaction_details_product ON transaction_details(product_id);
    `
  },
  {
    name: 'create_updated_at_trigger',
    sql: `
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
      END;
      $$ language 'plpgsql';

      DROP TRIGGER IF EXISTS update_users_updated_at ON users;
      CREATE TRIGGER update_users_updated_at
        BEFORE UPDATE ON users
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

      DROP TRIGGER IF EXISTS update_products_updated_at ON products;
      CREATE TRIGGER update_products_updated_at
        BEFORE UPDATE ON products
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    `
  }
];

const runMigrations = async () => {
  console.log('🔄 Memulai migrasi database...\n');

  const connected = await testConnection();
  if (!connected) {
    console.error('❌ Tidak dapat terhubung ke database. Cek konfigurasi DATABASE_URL.');
    process.exit(1);
  }

  for (const migration of migrations) {
    try {
      console.log(`⏳ Menjalankan: ${migration.name}`);
      await query(migration.sql);
      console.log(`✅ Selesai: ${migration.name}`);
    } catch (err) {
      console.error(`❌ Gagal: ${migration.name}`, err.message);
      process.exit(1);
    }
  }

  console.log('\n✅ Semua migrasi berhasil dijalankan!');
  process.exit(0);
};

runMigrations();