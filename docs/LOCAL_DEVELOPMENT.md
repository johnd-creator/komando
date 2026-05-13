# Local Development Setup

## Backend Configuration

Untuk development lokal, backend Laravel berada di `/var/www/html/anggota` seperti yang didokumentasikan di `docs/mobile-v1.md`.

## Flutter Configuration

### 1. Menggunakan Local Backend

Untuk menghubungkan aplikasi Flutter ke backend lokal, gunakan environment variables saat menjalankan aplikasi:

#### Android Emulator

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2/api/mobile/v1 --dart-define=WEB_BASE_URL=http://10.0.2.2
```

**Catatan:** `10.0.2.2` adalah IP khusus yang digunakan Android Emulator untuk mengakses `localhost` dari host machine.

#### iOS Simulator

```bash
flutter run --dart-define=API_BASE_URL=http://localhost/api/mobile/v1 --dart-define=WEB_BASE_URL=http://localhost
```

#### Physical Device (Same Network)

Jika menggunakan device fisik yang terhubung ke network yang sama dengan development machine:

```bash
# Ganti 192.168.1.100 dengan IP address development machine Anda
flutter run --dart-define=API_BASE_URL=http://192.168.1.100/api/mobile/v1 --dart-define=WEB_BASE_URL=http://192.168.1.100
```

### 2. Menggunakan Production Backend (Default)

Jika tidak menggunakan environment variables, aplikasi akan otomatis menggunakan production backend:

```bash
flutter run
```

Default URLs:
- API Base URL: `https://anggota.plnipservices.or.id/api/mobile/v1`
- Web Base URL: `https://anggota.plnipservices.or.id`

## Photo Profile Implementation

### Backend Response Format

Backend Laravel mengembalikan `photo_url` dalam format relatif:

```json
{
  "data": {
    "member": {
      "photo_url": "/storage/photos/member-123.jpg"
    }
  }
}
```

### Flutter Conversion

Flutter secara otomatis mengkonversi URL relatif menjadi URL absolut menggunakan `ApiConstants.getAbsolutePhotoUrl()`:

**Input:** `/storage/photos/member-123.jpg`

**Output (Production):** `https://anggota.plnipservices.or.id/storage/photos/member-123.jpg`

**Output (Local):** `http://10.0.2.2/storage/photos/member-123.jpg`

### Implementasi di Model

Konversi URL dilakukan di dua tempat:

1. **MemberProfileModel** (`lib/features/profile/data/models/member_profile_model.dart`)
   - Mengkonversi `photo_url` dari response `/profile` endpoint

2. **AppUserModel** (`lib/features/auth/data/models/app_user_model.dart`)
   - Mengkonversi `avatar` dan `member.photo_url` dari response `/auth/login` dan `/me` endpoints

### Widget Display

**ProfileAvatar** (`lib/shared/presentation/widgets/profile_avatar.dart`) menggunakan `CachedNetworkImage` untuk menampilkan photo dengan:
- Caching otomatis
- Placeholder saat loading
- Fallback ke initial jika gagal load atau URL kosong

## Testing Photo Profile

### 1. Upload Photo via Flutter

```dart
// Di ProfileScreen, tap pada avatar
// Pilih "Upload Foto"
// Pilih gambar dari gallery
// Photo akan diupload ke backend dan ditampilkan
```

### 2. Verify Backend Storage

Setelah upload, cek di backend:

```bash
ls -la /var/www/html/anggota/storage/app/public/photos/
```

### 3. Verify Photo URL

Check response dari API:

```bash
curl -X GET 'http://localhost/api/mobile/v1/profile' \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer <your_token>'
```

Response harus mengandung:

```json
{
  "data": {
    "member": {
      "photo_url": "/storage/photos/member-123.jpg"
    }
  }
}
```

### 4. Verify Photo Display

Photo harus muncul di:
- Profile Screen (avatar besar)
- Navigation drawer (avatar kecil)
- Semua tempat yang menggunakan `ProfileAvatar` widget

## Troubleshooting

### Photo tidak muncul

1. **Cek URL di debug log:**
   ```
   [ProfileRepo] parsed photoUrl: http://10.0.2.2/storage/photos/member-123.jpg
   ```

2. **Cek apakah file ada di backend:**
   ```bash
   ls -la /var/www/html/anggota/storage/app/public/photos/
   ```

3. **Cek symbolic link storage:**
   ```bash
   cd /var/www/html/anggota
   php artisan storage:link
   ```

4. **Cek permissions:**
   ```bash
   chmod -R 755 /var/www/html/anggota/storage
   chown -R www-data:www-data /var/www/html/anggota/storage
   ```

### CORS Error

Jika mengalami CORS error saat load photo dari local backend, tambahkan di backend Laravel:

```php
// config/cors.php
'paths' => ['api/*', 'storage/*'],
```

### Network Error

Pastikan:
- Backend Laravel running (`php artisan serve` atau Apache/Nginx)
- Device/emulator bisa akses backend (ping IP address)
- Firewall tidak memblokir koneksi

## Build Configuration

### Development Build

```bash
flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2/api/mobile/v1 --dart-define=WEB_BASE_URL=http://10.0.2.2
```

### Production Build

```bash
flutter build apk --release
```

Production build akan otomatis menggunakan production URLs.

## VS Code Launch Configuration

Tambahkan di `.vscode/launch.json` untuk kemudahan development:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Local Backend)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=API_BASE_URL=http://10.0.2.2/api/mobile/v1",
        "--dart-define=WEB_BASE_URL=http://10.0.2.2"
      ]
    },
    {
      "name": "Flutter (Production)",
      "request": "launch",
      "type": "dart"
    }
  ]
}
```

Dengan konfigurasi ini, Anda bisa memilih environment dari VS Code debug panel.
