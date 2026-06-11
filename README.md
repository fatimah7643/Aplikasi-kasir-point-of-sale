# 🏪 Aplikasi Kasir — Point of Sale UMKM Toko Sembako

Aplikasi kasir berbasis mobile multi-user yang dirancang untuk mempermudah operasional toko kelontong dan sembako milik UMKM. Dibangun dengan antarmuka besar dan ramah pengguna usia 35–60 tahun.

---

## 📸 Tampilan Aplikasi

### Mockup aplikasi
![mockup](assets/mockup-app.png)


## 🛠️ Stack Teknologi

| Layer | Teknologi |
|-------|-----------|
| Mobile Frontend | Flutter (Android) |
| Backend API | Node.js + Express |
| Database | PostgreSQL (Supabase) |
| State Management | Provider |
| Authentication | JWT (Access + Refresh Token) |
| Hosting Backend | Render |

---

## 👥 Role Pengguna

| Role | Akses |
|------|-------|
| **Admin** | Kelola produk, stok, user, lihat dashboard, rekap laba, export CSV |
| **Kasir** | Cari produk, buat transaksi, cetak struk |

---

## 📁 Struktur Repositori

```
Aplikasi-kasir-point-of-sale/
├── kasir-backend/          # Backend Node.js
│   ├── src/
│   │   ├── app.js
│   │   ├── config/
│   │   │   ├── database.js
│   │   │   ├── migrate.js
│   │   │   └── seed.js
│   │   ├── controllers/
│   │   ├── middlewares/
│   │   ├── routes/
│   │   ├── utils/
│   │   └── validators/
│   ├── .env.example
│   └── package.json
│
└── kasir_app/              # Flutter Android
    ├── lib/
    │   ├── core/
    │   │   ├── constants/
    │   │   ├── models/
    │   │   ├── providers/
    │   │   └── services/
    │   ├── features/
    │   │   ├── auth/
    │   │   ├── kasir/
    │   │   └── admin/
    │   └── main.dart
    └── pubspec.yaml
```

---

## 🗄️ Setup Backend

### Prasyarat
- Node.js v18 atau lebih baru
- Akun [Supabase](https://supabase.com) (database)

### 1. Clone Repositori

```bash
git clone https://github.com/USERNAME/NAMA-REPO.git
cd Aplikasi-kasir-point-of-sale/kasir-backend
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Konfigurasi Environment

```bash
cp .env.example .env
```

Buka file `.env` dan isi semua nilai yang diperlukan:

```env
PORT=3000
NODE_ENV=development

# Dari Supabase: Settings → Database → Connection String → URI
DATABASE_URL=postgresql://postgres:PASSWORD@db.XXXX.supabase.co:5432/postgres

# Generate dengan: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
JWT_SECRET=isi_dengan_random_string_panjang
JWT_EXPIRES_IN=8h
JWT_REFRESH_SECRET=isi_dengan_random_string_berbeda
JWT_REFRESH_EXPIRES_IN=7d

RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
AUTH_RATE_LIMIT_MAX=10

BCRYPT_SALT_ROUNDS=12
ALLOWED_ORIGINS=http://localhost:3000
```

#### Cara Generate JWT Secret

```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

Jalankan **dua kali** — hasil pertama untuk `JWT_SECRET`, hasil kedua untuk `JWT_REFRESH_SECRET`.

### 4. Setup Database Supabase

1. Buka [supabase.com](https://supabase.com) → buat project baru
2. Salin **Connection String** dari Settings → Database → URI
3. Paste ke `DATABASE_URL` di file `.env`

### 5. Migrasi Database

```bash
npm run db:migrate
```

### 6. Seed Data Awal

```bash
npm run db:seed
```

Perintah ini akan membuat:
- Akun admin default (`admin` / `Admin@123`)
- Akun kasir default (`kasir1` / `Kasir@123`)
- 15 produk sembako contoh

### 7. Jalankan Server

```bash
# Development (auto-reload)
npm run dev

# Production
npm start
```

Server berjalan di `http://localhost:3000`

Cek status: `http://localhost:3000/health`

---

## 📱 Setup Flutter (Frontend)

### Prasyarat
- Flutter SDK 3.x atau lebih baru
- Android Studio (untuk emulator)
- Android SDK API 26 atau lebih baru

### 1. Masuk ke Folder Flutter

```bash
cd ../kasir_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Konfigurasi URL Backend

Buka `lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  // Untuk emulator Android
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Untuk HP fisik (ganti dengan IP PC kamu)
  // static const String baseUrl = 'http://192.168.1.x:3000/api';

  // Untuk production (backend sudah di-deploy)
  // static const String baseUrl = 'https://kasir-backend.onrender.com/api';
}
```

### 4. Konfigurasi Android

Pastikan `android/app/build.gradle.kts` sudah benar:

```kotlin
defaultConfig {
    applicationId = "com.umkm.kasir_app"
    minSdk = 26          // Android 8.0 minimum
    targetSdk = 34
    versionCode = 1
    versionName = "1.0.0"
}
```

Pastikan `android/app/src/main/AndroidManifest.xml` memiliki:

```xml
<uses-permission android:name="android.permission.INTERNET"/>

<application
    android:usesCleartextTraffic="true"
    ...>
```

> ⚠️ `usesCleartextTraffic="true"` hanya untuk development. Hapus saat production jika backend sudah HTTPS.

### 5. Jalankan Aplikasi

```bash
# Ke emulator
flutter run -d emulator-5554

# Ke HP fisik (ganti dengan device ID kamu)
flutter run -d DEVICE_ID

# Cek device yang tersedia
flutter devices
```

### 6. Build APK (untuk install tanpa kabel)

```bash
flutter build apk --release
```

File APK ada di:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🚀 Deploy Backend ke Render

1. Push kode ke GitHub
2. Buka [render.com](https://render.com) → New → Web Service
3. Connect repositori GitHub
4. Isi konfigurasi:

| Field | Value |
|-------|-------|
| Name | `kasir-backend` |
| Region | Singapore |
| Root Directory | `kasir-backend` |
| Build Command | `npm install` |
| Start Command | `node src/app.js` |
| Instance Type | Free |

5. Tambahkan semua environment variables dari `.env`
6. Klik **Deploy Web Service**
7. Setelah deploy, update `app_constants.dart` dengan URL Render

---

## 🔐 Keamanan

| Fitur | Implementasi |
|-------|-------------|
| Password | bcrypt (12 salt rounds) |
| Autentikasi | JWT Access Token (8h) + Refresh Token (7d) |
| Anti Brute Force | Rate limiting login (10x/15 menit) |
| HTTP Headers | Helmet.js |
| SQL Injection | Parameterized queries |
| Harga Modal | Disembunyikan dari role kasir di level API |
| Soft Delete | User & produk dinonaktifkan, tidak dihapus |
| Transaksi DB | Atomic (BEGIN/COMMIT/ROLLBACK) |

---

## 📡 API Endpoints

### Auth
| Method | Endpoint | Akses | Deskripsi |
|--------|----------|-------|-----------|
| POST | `/api/auth/login` | Public | Login |
| POST | `/api/auth/refresh` | Public | Refresh token |
| GET | `/api/auth/me` | Auth | Profil sendiri |

### Products
| Method | Endpoint | Akses | Deskripsi |
|--------|----------|-------|-----------|
| GET | `/api/products` | Auth | Daftar produk |
| GET | `/api/products?search=beras` | Auth | Cari produk |
| GET | `/api/products/:id` | Auth | Detail produk |
| POST | `/api/products` | Admin | Tambah produk |
| PUT | `/api/products/:id` | Admin | Update produk |
| PATCH | `/api/products/:id/stock` | Admin | Tambah stok |
| DELETE | `/api/products/:id` | Admin | Hapus produk |

### Transactions
| Method | Endpoint | Akses | Deskripsi |
|--------|----------|-------|-----------|
| POST | `/api/transactions` | Auth | Buat transaksi |
| GET | `/api/transactions` | Auth | Riwayat transaksi |
| GET | `/api/transactions/:id` | Auth | Detail transaksi |
| GET | `/api/transactions/summary/today` | Admin | Summary hari ini |

### Users
| Method | Endpoint | Akses | Deskripsi |
|--------|----------|-------|-----------|
| GET | `/api/users` | Admin | Daftar user |
| POST | `/api/users` | Admin | Tambah user |
| PUT | `/api/users/:id` | Admin | Update user |
| DELETE | `/api/users/:id` | Admin | Nonaktifkan user |

### Dashboard
| Method | Endpoint | Akses | Deskripsi |
|--------|----------|-------|-----------|
| GET | `/api/dashboard/summary` | Admin | Summary penjualan |
| GET | `/api/dashboard/chart/weekly` | Admin | Grafik mingguan |
| GET | `/api/dashboard/top-products` | Admin | Produk terlaris |
| GET | `/api/dashboard/profit/summary?period=today` | Admin | Rekap laba |
| GET | `/api/dashboard/profit/daily` | Admin | Laba harian |
| GET | `/api/dashboard/transactions/export` | Admin | Export CSV |

---

## 🔑 Akun Default

Setelah menjalankan `npm run db:seed`:

| Role | Username | Password |
|------|----------|----------|
| Admin | `admin` | `Admin@123` |
| Kasir | `kasir1` | `Kasir@123` |

> ⚠️ Ganti password default setelah pertama kali login di production!

---

## 📊 Format Response API

**Sukses:**
```json
{
  "success": true,
  "message": "Deskripsi pesan",
  "data": { },
  "meta": {
    "total": 100,
    "page": 1,
    "limit": 20,
    "total_pages": 5
  }
}
```

**Error:**
```json
{
  "success": false,
  "message": "Deskripsi error",
  "errors": [
    { "field": "username", "message": "Username wajib diisi" }
  ]
}
```

---

## 🧪 Testing API

Import file berikut ke Postman:
- `kasir-backend/Kasir_App_API.postman_collection.json`
- `kasir-backend/Kasir_App_Environment.postman_environment.json`

Urutan testing:
1. 🔐 Auth → Login Admin (token tersimpan otomatis)
2. 🔐 Auth → Login Kasir
3. 📦 Products → Lihat Semua (product_id tersimpan otomatis)
4. 🛒 Transactions → Buat Transaksi
5. Lanjutkan test lainnya...

---

## 📋 Troubleshooting

| Masalah | Solusi |
|---------|--------|
| `password authentication failed` | Cek DATABASE_URL di .env |
| `connection refused` | Pastikan Supabase project aktif (tidak paused) |
| `JWT_SECRET is not defined` | File .env belum dibuat |
| `Cannot find module` | Jalankan `npm install` |
| App tidak bisa konek backend | Pastikan IP di app_constants.dart benar |
| HP tidak terdeteksi Flutter | Aktifkan USB Debugging di Developer Options |

---

## 📄 Lisensi

Project ini dibuat untuk keperluan UMKM toko sembako pribadi.