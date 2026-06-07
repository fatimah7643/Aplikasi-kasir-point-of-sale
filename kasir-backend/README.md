# 🏪 Kasir Backend API

Backend Node.js untuk Aplikasi Kasir UMKM Toko Sembako. Dibangun dengan fokus pada **keamanan data** dan **kemudahan pemeliharaan**.

---

## 🏗️ Arsitektur & Stack

```
kasir-backend/
├── src/
│   ├── app.js                    # Entry point, middleware, server
│   ├── config/
│   │   ├── database.js           # PostgreSQL pool & helper
│   │   ├── migrate.js            # Script migrasi tabel
│   │   └── seed.js               # Data awal (user & produk)
│   ├── controllers/
│   │   ├── auth.controller.js    # Login, refresh token, profil
│   │   ├── user.controller.js    # Manajemen user (Admin only)
│   │   ├── product.controller.js # CRUD produk + filter role
│   │   └── transaction.controller.js # Transaksi atomik
│   ├── middlewares/
│   │   ├── auth.middleware.js    # JWT verify + role check
│   │   └── validation.middleware.js # Express-validator handler
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── user.routes.js
│   │   ├── product.routes.js
│   │   └── transaction.routes.js
│   ├── utils/
│   │   ├── jwt.js                # Generate & verify token
│   │   ├── response.js           # Format respons standar
│   │   └── transactionNumber.js  # Generate nomor nota
│   └── validators/
│       └── index.js              # Validasi input semua route
├── .env.example
├── Kasir_App_API.postman_collection.json
└── Kasir_App_Environment.postman_environment.json
```

---

## ⚡ Cara Setup

### 1. Clone & Install
```bash
npm install
```

### 2. Konfigurasi Environment
```bash
cp .env.example .env
# Edit .env dengan kredensial Supabase dan JWT secret Anda
```

**Generate JWT Secret yang aman:**
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

### 3. Setup Database (Supabase)
Buat project di [supabase.com](https://supabase.com), salin `DATABASE_URL` ke `.env`.

```bash
# Buat semua tabel
npm run db:migrate

# Isi data awal (user admin + 15 produk sembako)
npm run db:seed
```

### 4. Jalankan Server
```bash
npm run dev      # Development (auto-reload)
npm start        # Production
```

---

## 🔐 Keamanan yang Diimplementasikan

| Fitur | Detail |
|-------|--------|
| **Password Hashing** | bcrypt dengan 12 salt rounds |
| **JWT Access Token** | Expire 8 jam, signed dengan HS256 |
| **JWT Refresh Token** | Expire 7 hari, secret terpisah |
| **Rate Limiting Login** | Max 10x per 15 menit (anti brute-force) |
| **Rate Limiting Global** | Max 100 req per 15 menit |
| **HTTP Security Headers** | Helmet (X-Frame-Options, HSTS, dll) |
| **Input Validation** | express-validator di semua endpoint |
| **SQL Injection Prevention** | Parameterized queries (pg library) |
| **Role-Based Access** | Admin & Kasir dengan hak berbeda |
| **Harga Modal Tersembunyi** | Cost_price tidak dikirim ke Kasir |
| **Soft Delete** | User & produk dinonaktifkan, bukan dihapus |
| **DB Transaction Atomic** | BEGIN/COMMIT/ROLLBACK untuk transaksi |
| **CORS** | Whitelist origin yang diizinkan |

---

## 📡 API Endpoints

### Auth
| Method | Endpoint | Akses | Deskripsi |
|--------|----------|-------|-----------|
| POST | `/api/auth/login` | Public | Login |
| POST | `/api/auth/refresh` | Public | Perbarui access token |
| GET | `/api/auth/me` | Auth | Profil sendiri |

### Products
| Method | Endpoint | Akses | Deskripsi |
|--------|----------|-------|-----------|
| GET | `/api/products` | Auth | Daftar produk (Admin: +cost_price) |
| GET | `/api/products?search=beras` | Auth | Cari produk |
| GET | `/api/products/:id` | Auth | Detail produk |
| POST | `/api/products` | Admin | Tambah produk |
| PUT | `/api/products/:id` | Admin | Update produk |
| PATCH | `/api/products/:id/stock` | Admin | Tambah stok |
| DELETE | `/api/products/:id` | Admin | Nonaktifkan produk |

### Transactions
| Method | Endpoint | Akses | Deskripsi |
|--------|----------|-------|-----------|
| POST | `/api/transactions` | Auth | Buat transaksi |
| GET | `/api/transactions` | Auth | Riwayat (Kasir: milik sendiri) |
| GET | `/api/transactions/:id` | Auth | Detail + item belanja |
| GET | `/api/transactions/summary/today` | Admin | Ringkasan hari ini |

### Users
| Method | Endpoint | Akses | Deskripsi |
|--------|----------|-------|-----------|
| GET | `/api/users` | Admin | Daftar user |
| GET | `/api/users/:id` | Admin | Detail user |
| POST | `/api/users` | Admin | Buat user baru |
| PUT | `/api/users/:id` | Admin | Update user |
| DELETE | `/api/users/:id` | Admin | Nonaktifkan user |

---

## 🧪 Testing dengan Postman

### Setup Environment
1. Buka Postman → **Environments** → **Import**
2. Import file: `Kasir_App_Environment.postman_environment.json`
3. Aktifkan environment **"Kasir App - Development"**

### Import Collection
1. **Collections** → **Import**
2. Import file: `Kasir_App_API.postman_collection.json`

### Urutan Testing
```
1. 🔐 Auth → Login Admin      (token tersimpan otomatis ke env)
2. 🔐 Auth → Login Kasir      (token tersimpan otomatis ke env)
3. 📦 Products → Lihat Semua  (product_id tersimpan otomatis)
4. 🛒 Transactions → Buat     (pakai product_id dari step 3)
5. Lanjutkan test lainnya...
```

### Test Otomatis
Setiap request memiliki **Tests** yang memverifikasi:
- Status code yang benar
- Format response konsisten
- ⭐ **Security Test**: Kasir tidak melihat `cost_price`
- Token tersimpan otomatis ke environment variable

---

## 🔑 Akun Default (setelah seed)

| Role | Username | Password |
|------|----------|----------|
| Admin | `admin` | `Admin@123` |
| Kasir | `kasir1` | `Kasir@123` |

---

## 📊 Format Respons

Semua respons menggunakan format standar:

**Sukses:**
```json
{
  "success": true,
  "message": "Deskripsi pesan",
  "data": { ... },
  "meta": { "total": 100, "page": 1, "limit": 20 }
}
```

**Error:**
```json
{
  "success": false,
  "message": "Deskripsi error",
  "errors": [{ "field": "nama_field", "message": "Detail error" }]
}
```