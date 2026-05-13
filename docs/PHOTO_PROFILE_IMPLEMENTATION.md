# Photo Profile Implementation

## Overview

Implementasi photo profile telah diperbaiki agar sinkron antara backend Laravel dan aplikasi Flutter. Photo profile sekarang diambil dari backend dan ditampilkan dengan benar di aplikasi.

## Changes Made

### 1. API Constants Enhancement

**File:** `lib/core/constants/api_constants.dart`

**Perubahan:**
- Menambahkan method `getAbsolutePhotoUrl()` untuk mengkonversi URL relatif dari backend menjadi URL absolut
- Menambahkan support untuk environment variables `API_BASE_URL` dan `WEB_BASE_URL` untuk local development

**Fungsi:**
```dart
static String getAbsolutePhotoUrl(String? photoUrl) {
  if (photoUrl == null || photoUrl.isEmpty) {
    return '';
  }

  // Already absolute URL
  if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
    return photoUrl;
  }

  // Relative URL - prepend web base URL
  if (photoUrl.startsWith('/')) {
    return '$webBaseUrl$photoUrl';
  }

  // Relative URL without leading slash
  return '$webBaseUrl/$photoUrl';
}
```

### 2. Member Profile Model Update

**File:** `lib/features/profile/data/models/member_profile_model.dart`

**Perubahan:**
- Import `ApiConstants`
- Menggunakan `ApiConstants.getAbsolutePhotoUrl()` untuk mengkonversi `photo_url` dari backend

**Before:**
```dart
final rawPhotoUrl = member['photo_url'];
final photoUrl = rawPhotoUrl is String && rawPhotoUrl.isNotEmpty
    ? rawPhotoUrl
    : null;
```

**After:**
```dart
final rawPhotoUrl = member['photo_url'];
final relativePhotoUrl = rawPhotoUrl is String && rawPhotoUrl.isNotEmpty
    ? rawPhotoUrl
    : null;

// Convert relative URL to absolute URL
final photoUrl = relativePhotoUrl != null 
    ? ApiConstants.getAbsolutePhotoUrl(relativePhotoUrl)
    : null;
```

### 3. App User Model Update

**File:** `lib/features/auth/data/models/app_user_model.dart`

**Perubahan:**
- Import `ApiConstants`
- Mengkonversi `avatar` dan `member.photo_url` menjadi URL absolut

**Before:**
```dart
final avatar = _readNullableString(userJson, const ['avatar']);
final memberPhotoUrl = memberJson is Map<String, dynamic>
    ? _readNullableString(memberJson, const ['photo_url'])
    : null;

return AppUserModel(
  // ...
  avatar: avatar,
  photoUrl: memberPhotoUrl ?? avatar,
);
```

**After:**
```dart
final avatar = _readNullableString(userJson, const ['avatar']);
final memberPhotoUrl = memberJson is Map<String, dynamic>
    ? _readNullableString(memberJson, const ['photo_url'])
    : null;

// Convert relative URLs to absolute URLs
final absoluteAvatar = avatar != null 
    ? ApiConstants.getAbsolutePhotoUrl(avatar)
    : null;
final absoluteMemberPhotoUrl = memberPhotoUrl != null
    ? ApiConstants.getAbsolutePhotoUrl(memberPhotoUrl)
    : null;

return AppUserModel(
  // ...
  avatar: absoluteAvatar,
  photoUrl: absoluteMemberPhotoUrl ?? absoluteAvatar,
);
```

## How It Works

### Backend Response

Backend Laravel mengembalikan photo URL dalam format relatif:

```json
{
  "data": {
    "member": {
      "photo_url": "/storage/photos/member-123.jpg"
    }
  }
}
```

### Flutter Processing

1. **Parse Response:** Model menerima response dari API
2. **Extract Photo URL:** Mengambil `photo_url` dari response
3. **Convert to Absolute:** Menggunakan `ApiConstants.getAbsolutePhotoUrl()` untuk mengkonversi
4. **Store in Model:** Menyimpan URL absolut di model

### Display in UI

Widget `ProfileAvatar` menggunakan `CachedNetworkImage` untuk menampilkan photo:

```dart
CachedNetworkImage(
  imageUrl: photoUrl!,
  fit: BoxFit.cover,
  placeholder: (_, _) => Center(child: Text(_initial)),
  errorWidget: (_, _, _) => Center(child: Text(_initial)),
)
```

## URL Conversion Examples

### Production Environment

**Input:** `/storage/photos/member-123.jpg`

**Output:** `https://anggota.plnipservices.or.id/storage/photos/member-123.jpg`

### Local Development (Android Emulator)

**Input:** `/storage/photos/member-123.jpg`

**Output:** `http://10.0.2.2/storage/photos/member-123.jpg`

### Already Absolute URL

**Input:** `https://example.com/photo.jpg`

**Output:** `https://example.com/photo.jpg` (tidak diubah)

## Features

### ✅ Upload Photo
- User dapat upload photo dari gallery
- Photo diupload ke backend via `POST /profile/photo`
- Response dari backend berisi `photo_url` yang sudah dikonversi

### ✅ Delete Photo
- User dapat menghapus photo
- Request ke backend via `DELETE /profile/photo`
- Avatar kembali menampilkan initial

### ✅ Display Photo
- Photo ditampilkan di Profile Screen
- Photo ditampilkan di Navigation Drawer
- Photo ditampilkan di semua tempat yang menggunakan `ProfileAvatar` widget

### ✅ Caching
- Photo di-cache menggunakan `CachedNetworkImage`
- Mengurangi network request
- Meningkatkan performa aplikasi

### ✅ Fallback
- Jika photo tidak ada, tampilkan initial
- Jika photo gagal load, tampilkan initial
- Jika URL kosong, tampilkan initial

## Testing

### Manual Testing

1. **Login ke aplikasi**
2. **Buka Profile Screen**
3. **Tap pada avatar**
4. **Pilih "Upload Foto"**
5. **Pilih gambar dari gallery**
6. **Verify photo muncul di avatar**
7. **Logout dan login kembali**
8. **Verify photo masih muncul**

### API Testing

```bash
# Login
curl -X POST 'http://localhost/api/mobile/v1/auth/login' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "test@example.com",
    "password": "password",
    "device_name": "flutter"
  }'

# Get Profile
curl -X GET 'http://localhost/api/mobile/v1/profile' \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer <token>'

# Upload Photo
curl -X POST 'http://localhost/api/mobile/v1/profile/photo' \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer <token>' \
  -F 'photo=@/path/to/photo.jpg'

# Delete Photo
curl -X DELETE 'http://localhost/api/mobile/v1/profile/photo' \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer <token>'
```

## Backend Requirements

### Storage Configuration

Backend Laravel harus memiliki symbolic link untuk storage:

```bash
cd /var/www/html/anggota
php artisan storage:link
```

### Permissions

```bash
chmod -R 755 /var/www/html/anggota/storage
chown -R www-data:www-data /var/www/html/anggota/storage
```

### CORS Configuration

Jika menggunakan local development, pastikan CORS dikonfigurasi dengan benar:

```php
// config/cors.php
'paths' => ['api/*', 'storage/*'],
'allowed_origins' => ['*'], // Untuk development saja
```

## Environment Variables

### Production (Default)

Tidak perlu environment variables, aplikasi akan menggunakan production URLs:

```bash
flutter run
```

### Local Development

#### Android Emulator

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2/api/mobile/v1 \
  --dart-define=WEB_BASE_URL=http://10.0.2.2
```

#### iOS Simulator

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost/api/mobile/v1 \
  --dart-define=WEB_BASE_URL=http://localhost
```

#### Physical Device

```bash
flutter run \
  --dart-define=API_BASE_URL=http://192.168.1.100/api/mobile/v1 \
  --dart-define=WEB_BASE_URL=http://192.168.1.100
```

## Troubleshooting

### Photo tidak muncul

**Kemungkinan penyebab:**
1. URL tidak valid
2. File tidak ada di backend
3. Permissions salah
4. CORS error
5. Network error

**Solusi:**
1. Cek debug log untuk melihat URL yang digunakan
2. Verify file ada di backend storage
3. Cek permissions storage directory
4. Konfigurasi CORS di backend
5. Pastikan device bisa akses backend

### Upload gagal

**Kemungkinan penyebab:**
1. File size terlalu besar (max 5MB)
2. Format file tidak didukung (hanya jpg, jpeg, png, webp)
3. Token expired
4. Network error

**Solusi:**
1. Compress image sebelum upload
2. Pastikan format file didukung
3. Login ulang untuk refresh token
4. Cek koneksi internet

### Cache tidak update

**Solusi:**
```dart
// Clear cache di ProfileAvatar
CachedNetworkImage.evictFromCache(photoUrl);
```

Atau clear semua cache:
```bash
flutter clean
```

## Future Improvements

### Planned Features

- [ ] Image compression sebelum upload
- [ ] Crop image sebelum upload
- [ ] Multiple photo upload
- [ ] Photo gallery
- [ ] Photo filters
- [ ] Photo rotation
- [ ] Photo zoom

### Performance Optimization

- [ ] Lazy loading untuk photo list
- [ ] Progressive image loading
- [ ] WebP format support
- [ ] CDN integration
- [ ] Image optimization di backend

## Related Files

- `lib/core/constants/api_constants.dart` - API configuration dan URL helper
- `lib/features/profile/data/models/member_profile_model.dart` - Profile model
- `lib/features/auth/data/models/app_user_model.dart` - User model
- `lib/shared/presentation/widgets/profile_avatar.dart` - Avatar widget
- `lib/features/profile/presentation/screens/profile_screen.dart` - Profile screen
- `lib/features/profile/data/repositories/profile_repository.dart` - Profile repository
- `docs/mobile-v1.md` - API documentation
- `docs/LOCAL_DEVELOPMENT.md` - Local development guide

## References

- [Flutter CachedNetworkImage](https://pub.dev/packages/cached_network_image)
- [Laravel Storage](https://laravel.com/docs/filesystem)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [Flutter Environment Variables](https://dart.dev/guides/environment-declarations)
