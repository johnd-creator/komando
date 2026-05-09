# Rencana Perbaikan Login Google SSO dan Login Manual

## Context

**Masalah:** Setelah percobaan login Google SSO gagal, aplikasi dapat menyisakan state autentikasi lama sehingga login manual, restore session, atau opsi biometrik terlihat tidak konsisten.

Endpoint mobile `POST /auth/google/token` saat ini memang mengembalikan `501 Not Implemented` sesuai `docs/mobile-v1.md`. Route tersebut hanya disiapkan untuk kontrak mobile OAuth dan belum boleh menerima native provider token sampai verifier `id_token` server-side aktif.

## Root Cause Analysis

1. **Backend Google SSO mobile belum aktif**
   - `POST /api/mobile/v1/auth/google/token` masih `501`.
   - Pada error `501`, token baru tidak tersimpan karena request gagal sebelum `saveAccessToken()` dipanggil.

2. **Token lama dapat tetap tersimpan**
   - Token dari session sebelumnya masih bisa berada di secure storage ketika user mencoba login baru.
   - Jika token lama invalid atau expired, UI dapat tetap membaca adanya saved session atau biometrik aktif.

3. **Login baru belum membersihkan state lama sebelum attempt**
   - `AuthRepositoryImpl.login()` dan `loginWithGoogle()` saat ini langsung memanggil remote data source.
   - State lama sebaiknya dibersihkan sebelum attempt login manual atau Google agar request berikutnya tidak membawa bearer token lama.

4. **Session restore belum cleanup saat `/me` gagal**
   - `restoreSession()` membaca token dan langsung memanggil `/me`.
   - Jika `/me` gagal karena token invalid/expired, token dan biometric flag belum dibersihkan.

## Prinsip Perbaikan Frontend

Token lifecycle harus ditangani di repository/data layer, bukan di Bloc atau use case. `AuthBloc` cukup mengubah event menjadi state UI; Bloc tidak perlu tahu detail secure storage.

Jangan menambahkan method seperti `clearTokenOnFailure()` di `LoginUseCase`, `GoogleLoginUseCase`, atau `AuthBloc`. Cleanup dilakukan langsung oleh `AuthRepositoryImpl` karena class itu sudah memiliki akses ke `TokenStorage` dan `BiometricAuthService`.

## Rekomendasi Implementasi Flutter

### 1. Bersihkan State Auth Sebelum Login Baru

**File:** `lib/features/auth/data/repositories/auth_repository_impl.dart`

Sebelum memanggil remote login manual atau Google login:

```dart
await _tokenStorage.clearAccessToken();
await _tokenStorage.clearBiometricEnabled();
```

Terapkan pada:

- `login()`
- `loginWithGoogle()`

Tujuannya adalah memastikan attempt login baru tidak membawa bearer token lama lewat interceptor `ApiClient`.

### 2. Simpan Token Hanya Jika Response Valid

Pada `login()` dan `loginWithGoogle()`, simpan token hanya jika `result.accessToken.isNotEmpty`.

Contoh pola:

```dart
if (result.accessToken.isEmpty) {
  throw Exception('Access token kosong dari server.');
}

await _tokenStorage.saveAccessToken(result.accessToken);
```

Catatan:

- `result.user` pada kode saat ini bertipe `AppUserModel`, bukan nullable, jadi jangan gunakan validasi `result.user == null`.
- Jika backend mengembalikan user kosong, validasi model tambahan dapat dibuat terpisah, tetapi bukan bagian utama perbaikan token lifecycle ini.

### 3. Cleanup Saat Restore Session Gagal

**File:** `lib/features/auth/data/repositories/auth_repository_impl.dart`

Update `restoreSession()` agar membungkus request `/me` dengan `try/catch`.

Jika `/me` gagal:

- Clear `access_token`.
- Clear biometric flag.
- Return `null`.

Pola yang diharapkan:

```dart
try {
  return await _remoteDataSource.me();
} catch (_) {
  await _tokenStorage.clearAccessToken();
  await _tokenStorage.clearBiometricEnabled();
  return null;
}
```

### 4. Jangan Ubah Bloc untuk Cleanup Storage

**File:** `lib/features/auth/presentation/bloc/auth_bloc.dart`

Tidak perlu menambahkan cleanup token di catch block Bloc. Catch block tetap cukup:

```dart
emit(AuthFailure(ApiErrorHandler.getMessage(error)));
emit(const AuthUnauthenticated());
```

Repository sudah bertanggung jawab membuat state storage konsisten sebelum error sampai ke Bloc.

### 5. Disable Sementara Google SSO Native Flow

**File:** `lib/features/auth/presentation/screens/login_screen.dart`

Selama backend masih mengembalikan `501`, tombol "Masuk dengan Google" tetap tampil, tetapi `_openGoogleSso()` tidak menjalankan native `GoogleSignIn`.

Perilaku sementara:

```dart
Future<void> _openGoogleSso() async {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Login Google sedang disiapkan. Silakan gunakan login manual.'),
      duration: Duration(seconds: 3),
    ),
  );
}
```

Alasan:

- Layout login tetap stabil.
- User mendapat pesan yang jelas.
- Aplikasi tidak melakukan request ke endpoint yang diketahui belum aktif.

Saat endpoint Laravel sudah aktif, native `GoogleSignIn` dapat diaktifkan kembali dengan flow existing: ambil `idToken`, kirim ke `AuthGoogleLoginRequested`, lalu simpan bearer token dari response backend.

## File yang Perlu Dimodifikasi Saat Implementasi

1. `lib/features/auth/data/repositories/auth_repository_impl.dart`
   - Clear `access_token` dan biometric flag sebelum `login()` dan `loginWithGoogle()`.
   - Validasi `accessToken.isNotEmpty` sebelum save.
   - Cleanup token dan biometric flag saat `restoreSession()` gagal memanggil `/me`.

2. `lib/features/auth/presentation/screens/login_screen.dart`
   - Ubah `_openGoogleSso()` menjadi temporary disabled flow dengan SnackBar.
   - Simpan kode native flow lama hanya jika masih dibutuhkan untuk re-enable cepat, atau referensikan dari git history bila ingin menjaga file tetap bersih.

3. `test/`
   - Tambahkan atau update test repository dan widget/Bloc sesuai perubahan.
   - Jika `auth_bloc_test.dart` disentuh, pastikan fake repository mengikuti interface `AuthRepository` terbaru.

## Testing Manual

1. **Login manual setelah Google SSO disabled**
   - Tap "Masuk dengan Google".
   - Pastikan muncul pesan `Login Google sedang disiapkan. Silakan gunakan login manual.`
   - Login manual dengan kredensial valid.
   - Login harus sukses.

2. **Login manual berulang**
   - Login manual sukses.
   - Logout.
   - Login manual lagi dengan akun yang sama.
   - Login harus sukses.

3. **Restore session token invalid**
   - Simulasikan token invalid/expired di secure storage.
   - Jalankan restore session.
   - App harus kembali ke login state.
   - Token dan biometric flag harus dibersihkan.

4. **Biometrik setelah token invalid**
   - Aktifkan biometrik pada session valid.
   - Buat token invalid/expired.
   - Restore atau login biometrik harus gagal bersih.
   - UI tidak boleh tetap menawarkan biometrik untuk token yang sudah invalid.

## Testing Automated

1. **Unit test `AuthRepositoryImpl`**
   - `login()` membersihkan token dan biometric flag sebelum remote login.
   - `loginWithGoogle()` membersihkan token dan biometric flag sebelum remote login.
   - Token hanya disimpan jika `accessToken` tidak kosong.
   - Empty `accessToken` menghasilkan error dan tidak menyimpan token.
   - `restoreSession()` membersihkan token dan biometric flag ketika `/me` gagal.

2. **Widget atau Bloc-adjacent test login screen**
   - Tap tombol Google menampilkan SnackBar sementara.
   - Tidak ada event `AuthGoogleLoginRequested` yang dikirim selama temporary disabled flow.

3. **Regression test auth state**
   - Login manual sukses tetap emit `AuthAuthenticated`.
   - Login manual gagal tetap emit `AuthFailure` lalu `AuthUnauthenticated`.
   - Restore session dengan token valid tetap emit authenticated path.

## Langkah Verifikasi Implementasi

1. Jalankan `flutter analyze`.
2. Jalankan `flutter test`.
3. Test manual di device/emulator untuk login manual, logout, restore session, dan tombol Google sementara.
4. Setelah backend siap, aktifkan kembali native Google flow dan test:
   - Google login sukses.
   - Token tersimpan.
   - `/me` sukses dengan bearer token.
   - Logout revoke token.

## Expected Outcome

- Login manual tetap bisa digunakan setelah user menekan tombol Google SSO.
- Token dan biometric flag lama tidak lagi membuat state auth tidak konsisten.
- Session invalid dibersihkan otomatis saat restore gagal.
- Frontend siap mengaktifkan Google SSO native begitu endpoint Laravel `/auth/google/token` sudah benar-benar berjalan.
