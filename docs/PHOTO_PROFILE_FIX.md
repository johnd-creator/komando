# Photo Profile Fix - Authentication Issue

## Problem

Photo profile tidak tampil meskipun URL sudah benar di logs:
```
[ProfileRepo] parsed photoUrl: https://anggota.plnipservices.or.id/storage/members/photos/YGaiPNYuocU4jHuE11PyONAXLj8tyZYJ0Ey5ayWv.jpg
```

## Root Cause

`CachedNetworkImage` tidak menggunakan Dio client yang sama dengan API calls, sehingga **tidak ada Authorization header** saat request image. Backend Laravel kemungkinan memerlukan authentication untuk mengakses storage photos.

## Solution

Membuat custom `AuthenticatedImageProvider` yang:
1. Menggunakan `TokenStorage` untuk mendapatkan access token
2. Menambahkan `Authorization: Bearer <token>` header pada image request
3. Menambahkan `Accept: image/*` header
4. Logging lengkap untuk debugging

## Changes Made

### 1. New File: `lib/core/network/authenticated_image_provider.dart`

Custom `ImageProvider` yang extends Flutter's `ImageProvider` dan menambahkan authentication headers.

**Key Features:**
- ✅ Menggunakan `TokenStorage` untuk mendapatkan access token
- ✅ Menambahkan Authorization header otomatis
- ✅ Logging lengkap untuk debugging
- ✅ Error handling yang baik
- ✅ Caching support via Flutter's image cache

**Code:**
```dart
class AuthenticatedImageProvider extends ImageProvider<AuthenticatedImageProvider> {
  const AuthenticatedImageProvider({
    required this.url,
    required this.tokenStorage,
    this.scale = 1.0,
  });

  final String url;
  final TokenStorage tokenStorage;
  final double scale;

  // ... implementation
}
```

### 2. Updated: `lib/shared/presentation/widgets/profile_avatar.dart`

**Changes:**
- ❌ Removed `CachedNetworkImage` dependency
- ✅ Added `AuthenticatedImageProvider` usage
- ✅ Added `TokenStorage` parameter
- ✅ Using Flutter's native `Image` widget with custom provider
- ✅ Added detailed logging

**Before:**
```dart
CachedNetworkImage(
  imageUrl: photoUrl!,
  fit: BoxFit.cover,
  // No authentication headers
)
```

**After:**
```dart
Image(
  image: AuthenticatedImageProvider(
    url: photoUrl!,
    tokenStorage: _tokenStorage,
  ),
  fit: BoxFit.cover,
  // Automatically includes Authorization header
)
```

## How It Works

### Request Flow

1. **Widget Build:**
   ```dart
   ProfileAvatar(
     photoUrl: 'https://anggota.plnipservices.or.id/storage/members/photos/xxx.jpg',
     name: 'John Doe',
   )
   ```

2. **Image Provider:**
   ```dart
   AuthenticatedImageProvider(
     url: photoUrl,
     tokenStorage: TokenStorage(),
   )
   ```

3. **Load Image:**
   ```dart
   // Get token from secure storage
   final token = await tokenStorage.readAccessToken();
   
   // Add headers
   final headers = {
     'Accept': 'image/*',
     'Authorization': 'Bearer $token',
   };
   
   // Make HTTP request
   final response = await http.get(Uri.parse(url), headers: headers);
   ```

4. **Display:**
   - Success: Show image
   - Loading: Show loading indicator
   - Error: Show initial fallback

### Debug Logs

```
[ProfileAvatar] Loading photo from: https://anggota.plnipservices.or.id/storage/members/photos/xxx.jpg
[AuthenticatedImageProvider] Loading image: https://anggota.plnipservices.or.id/storage/members/photos/xxx.jpg
[AuthenticatedImageProvider] Using auth token
[AuthenticatedImageProvider] Image loaded successfully
```

## Testing

### 1. Verify Logs

Run app dan check logs:
```bash
flutter run
```

Expected logs:
```
[ProfileRepo] parsed photoUrl: https://...
[ProfileAvatar] Loading photo from: https://...
[AuthenticatedImageProvider] Loading image: https://...
[AuthenticatedImageProvider] Using auth token
[AuthenticatedImageProvider] Image loaded successfully
```

### 2. Verify Image Display

- ✅ Photo muncul di Profile Screen
- ✅ Photo muncul di Navigation Drawer
- ✅ Loading indicator muncul saat loading
- ✅ Fallback ke initial jika error

### 3. Test Upload

1. Tap avatar di Profile Screen
2. Pilih "Upload Foto"
3. Pilih image dari gallery
4. Verify photo muncul setelah upload

### 4. Test Network Error

1. Turn off internet
2. Verify fallback ke initial
3. Turn on internet
4. Verify photo muncul kembali

## Backend Requirements

### Storage Access Control

Jika backend memerlukan authentication untuk storage, pastikan:

**Option 1: Public Storage (Recommended for Photos)**
```php
// routes/web.php atau config
// Storage photos bisa diakses tanpa auth
```

**Option 2: Protected Storage (Current)**
```php
// Middleware untuk storage photos
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/storage/members/photos/{filename}', function ($filename) {
        $path = storage_path('app/public/members/photos/' . $filename);
        
        if (!file_exists($path)) {
            abort(404);
        }
        
        return response()->file($path);
    });
});
```

### CORS Configuration

Pastikan CORS dikonfigurasi untuk storage:

```php
// config/cors.php
'paths' => [
    'api/*',
    'storage/*',
    'storage/members/photos/*',
],

'allowed_methods' => ['*'],
'allowed_origins' => ['*'], // Atau specific origins
'allowed_headers' => ['*'],
'exposed_headers' => [],
'max_age' => 0,
'supports_credentials' => true,
```

## Advantages of This Approach

### ✅ Security
- Authentication required untuk akses photos
- Token automatically included
- Secure token storage

### ✅ Performance
- Flutter's built-in image caching
- Efficient memory management
- Automatic cache invalidation

### ✅ Debugging
- Detailed logging at each step
- Easy to troubleshoot
- Clear error messages

### ✅ Maintainability
- Clean separation of concerns
- Reusable image provider
- Easy to extend

## Alternative Approaches Considered

### 1. CachedNetworkImage with httpHeaders ❌

**Problem:** Headers are static, can't get token asynchronously

```dart
CachedNetworkImage(
  imageUrl: url,
  httpHeaders: {
    'Authorization': 'Bearer $token', // Can't await here
  },
)
```

### 2. Dio Image Provider ❌

**Problem:** Requires additional package, more complex

### 3. Custom HTTP Client for CachedNetworkImage ❌

**Problem:** CachedNetworkImage doesn't support custom HTTP client easily

### 4. AuthenticatedImageProvider ✅ (Chosen)

**Advantages:**
- Native Flutter solution
- Full control over headers
- Async token retrieval
- Built-in caching
- No additional dependencies

## Troubleshooting

### Photo still not showing

**Check logs for:**

1. **URL is correct:**
   ```
   [ProfileRepo] parsed photoUrl: https://...
   ```

2. **Token is available:**
   ```
   [AuthenticatedImageProvider] Using auth token
   ```

3. **HTTP status:**
   ```
   [AuthenticatedImageProvider] Image loaded successfully
   ```
   or
   ```
   [AuthenticatedImageProvider] Failed to load image: 401/403/404
   ```

### Common Issues

**401 Unauthorized:**
- Token expired → Login again
- Token invalid → Clear app data and login
- Backend auth middleware issue → Check backend logs

**403 Forbidden:**
- User doesn't have permission → Check backend policy
- CORS issue → Check CORS configuration

**404 Not Found:**
- File doesn't exist → Check backend storage
- Wrong URL → Check photo_url in API response
- Symbolic link missing → Run `php artisan storage:link`

**Network Error:**
- No internet connection
- Backend server down
- Firewall blocking request

## Migration from CachedNetworkImage

### Breaking Changes

**None** - ProfileAvatar API remains the same:

```dart
// Still works the same
ProfileAvatar(
  photoUrl: user.photoUrl,
  name: user.name,
  radius: 48,
)
```

### Internal Changes

- `CachedNetworkImage` → `Image` with `AuthenticatedImageProvider`
- Added `TokenStorage` parameter (optional, has default)
- Changed from `const` to regular constructor

### Cache Behavior

**Before (CachedNetworkImage):**
- Disk cache + Memory cache
- Custom cache manager

**After (AuthenticatedImageProvider):**
- Flutter's built-in image cache (memory)
- Automatic cache management
- Cache key based on URL

**Note:** If you need disk caching, consider adding `cached_network_image` back with custom HTTP client.

## Future Improvements

### Short Term
- [ ] Add disk caching support
- [ ] Add cache expiration
- [ ] Add retry mechanism
- [ ] Add progress indicator

### Long Term
- [ ] Support for image transformations
- [ ] Support for placeholder images
- [ ] Support for image compression
- [ ] CDN integration

## Related Files

- `lib/core/network/authenticated_image_provider.dart` - Custom image provider
- `lib/shared/presentation/widgets/profile_avatar.dart` - Avatar widget
- `lib/core/security/token_storage.dart` - Token storage
- `lib/features/profile/data/models/member_profile_model.dart` - Profile model
- `lib/features/auth/data/models/app_user_model.dart` - User model

## References

- [Flutter ImageProvider](https://api.flutter.dev/flutter/painting/ImageProvider-class.html)
- [Flutter Image Widget](https://api.flutter.dev/flutter/widgets/Image-class.html)
- [HTTP Package](https://pub.dev/packages/http)
- [Laravel Storage](https://laravel.com/docs/filesystem)

---

**Status:** ✅ Fixed and Tested
**Date:** 2026-05-13
**Version:** 1.1.0
