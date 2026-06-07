require('dotenv').config();
const bcrypt = require('bcrypt');
const { query, testConnection } = require('./database');

const seedUsers = async () => {
  const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12;

  const adminPassword = await bcrypt.hash('Admin@123', saltRounds);
  const kasirPassword = await bcrypt.hash('Kasir@123', saltRounds);

  await query(`
    INSERT INTO users (username, password, full_name, role) VALUES
      ('admin', $1, 'Administrator', 'admin'),
      ('kasir1', $2, 'Budi Santoso', 'kasir')
    ON CONFLICT (username) DO NOTHING
  `, [adminPassword, kasirPassword]);

  console.log('✅ Seed users: admin / Admin@123 | kasir1 / Kasir@123');
};

const seedProducts = async () => {
  await query(`
    INSERT INTO products (product_code, product_name, cost_price, selling_price, stock, unit) VALUES
      ('BRS-001', 'Beras Premium 5kg', 65000, 75000, 100, 'karung'),
      ('BRS-002', 'Beras Medium 5kg', 55000, 63000, 80, 'karung'),
      ('GLA-001', 'Gula Pasir 1kg', 14000, 16500, 200, 'kg'),
      ('MNY-001', 'Minyak Goreng Tropical 2L', 28000, 33000, 150, 'botol'),
      ('TLR-001', 'Telur Ayam 1kg', 27000, 30000, 100, 'kg'),
      ('MIE-001', 'Indomie Goreng', 2800, 3500, 500, 'bungkus'),
      ('MIE-002', 'Indomie Kuah', 2800, 3500, 500, 'bungkus'),
      ('KPI-001', 'Kopi Kapal Api 165gr', 16000, 19000, 80, 'sachet'),
      ('SUP-001', 'Sabun Lifebuoy 80gr', 4500, 6000, 200, 'buah'),
      ('ODL-001', 'Odol Pepsodent 75gr', 8500, 11000, 100, 'buah'),
      ('AQU-001', 'Aqua Botol 600ml', 2500, 4000, 300, 'botol'),
      ('SBK-001', 'Sabun Cuci Piring Sunlight 800ml', 14000, 18000, 80, 'botol'),
      ('KCG-001', 'Kecap Manis ABC 135ml', 6500, 9000, 120, 'botol'),
      ('SMP-001', 'Sampo Pantene 70ml', 9000, 13000, 90, 'botol'),
      ('GRM-001', 'Garam Halus 250gr', 2000, 3000, 300, 'bungkus')
    ON CONFLICT (product_code) DO NOTHING
  `);

  console.log('✅ Seed products: 15 produk sembako berhasil ditambahkan');
};

const runSeeds = async () => {
  console.log('🌱 Memulai seeding data...\n');

  const connected = await testConnection();
  if (!connected) {
    console.error('❌ Tidak dapat terhubung ke database.');
    process.exit(1);
  }

  try {
    await seedUsers();
    await seedProducts();
    console.log('\n✅ Seeding selesai!');
    console.log('\n📋 Akun Default:');
    console.log('   Admin    → username: admin    | password: Admin@123');
    console.log('   Kasir    → username: kasir1   | password: Kasir@123');
  } catch (err) {
    console.error('❌ Seeding gagal:', err.message);
    process.exit(1);
  }

  process.exit(0);
};

runSeeds();