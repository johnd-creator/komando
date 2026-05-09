# Rencana Perbaikan Endpoint Laravel untuk Google SSO Flutter

## Context

Aplikasi Flutter sudah menyiapkan native Google Sign-In dan akan mengirim Google `id_token` ke endpoint mobile:

```http
POST /api/mobile/v1/auth/google/token
```

Saat ini endpoint tersebut sengaja mengembalikan `501 Not Implemented` sampai backend memiliki verifier `id_token` server-side. Endpoint tidak boleh menerima token Google hanya berdasarkan payload client karena token harus diverifikasi signature, issuer, expiry, dan audience-nya di backend.

## Kontrak Endpoint

### Request

**URL produksi:**

```http
POST https://anggota.plnipservices.or.id/api/mobile/v1/auth/google/token
```

**Headers:**

```http
Accept: application/json
Content-Type: application/json
```

**Body:**

```json
{
  "id_token": "google-id-token",
  "device_name": "flutter",
  "server_auth_code": "optional-server-auth-code"
}
```

**Field rules:**

- `id_token`: required, string.
- `device_name`: required, string, dipakai sebagai nama token/device seperti login manual.
- `server_auth_code`: optional, string. Jangan diwajibkan untuk login v1 jika bearer token mobile hanya membutuhkan verifikasi `id_token`.

### Response Sukses

Response harus mengikuti bentuk `POST /auth/login` di `docs/mobile-v1.md` agar Flutter bisa memakai parser auth yang sama:

```json
{
  "access_token": "token-value",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "name": "Nama Anggota",
    "email": "anggota@example.com",
    "role": { "id": 4, "name": "anggota", "label": "Anggota" },
    "current_unit_id": 1,
    "member_context_unit_id": 1,
    "member": {}
  }
}
```

Token harus kompatibel dengan:

```http
Authorization: Bearer <access_token>
```

dan harus langsung bisa dipakai untuk `GET /api/mobile/v1/me`.

## Validasi Google ID Token

Backend wajib memverifikasi `id_token` secara server-side sebelum menerbitkan bearer token aplikasi.

Validasi minimum:

- Signature token valid terhadap public keys Google.
- `iss` adalah issuer Google yang valid.
- `exp` belum kadaluarsa.
- `aud` cocok dengan salah satu Google OAuth client ID yang diizinkan backend.
- Email tersedia dan `email_verified` bernilai true.

Konfigurasi client ID disarankan lewat environment variable, misalnya:

```env
GOOGLE_ANDROID_CLIENT_ID=...
GOOGLE_IOS_CLIENT_ID=...
GOOGLE_WEB_CLIENT_ID=...
GOOGLE_ALLOWED_CLIENT_IDS="${GOOGLE_ANDROID_CLIENT_ID},${GOOGLE_IOS_CLIENT_ID},${GOOGLE_WEB_CLIENT_ID}"
```

Catatan:

- Flutter saat ini memiliki `GOOGLE_SERVER_CLIENT_ID` di `login_screen.dart`; nilai ini harus cocok dengan salah satu audience yang diizinkan backend.
- Jangan menerima native provider token tanpa verifikasi signature dan audience.
- Jangan mengandalkan email dari client request biasa; email harus berasal dari token Google yang sudah verified.

## Mapping User Laravel

Login Google mobile v1 hanya boleh berhasil untuk user yang sudah terdaftar dan aktif di sistem.

Alur mapping:

1. Verifikasi `id_token`.
2. Ambil email verified dari payload Google.
3. Cari user Laravel berdasarkan email tersebut.
4. Pastikan user aktif dan boleh mengakses mobile app.
5. Terbitkan bearer token mobile dengan mekanisme yang sama seperti login manual.

Kebijakan v1:

- Tidak membuat akun otomatis dari Google.
- Tidak mengubah email user berdasarkan payload Google.
- Jika email Google tidak ada di sistem, return error yang jelas.
- Jika user nonaktif atau tidak punya akses mobile, return error authorization.

Rekomendasi status error:

- `403`: user ditemukan tetapi nonaktif, diblokir, atau tidak boleh login mobile.
- `422`: email Google verified tetapi tidak terdaftar, atau payload token tidak memenuhi syarat login.

## Token Laravel

Gunakan mekanisme token yang sama dengan `POST /api/mobile/v1/auth/login`.

Ketentuan:

- `device_name` dipakai sebagai nama token/device.
- Token yang diterbitkan harus bisa dipakai oleh middleware auth mobile yang sama.
- `GET /api/mobile/v1/me` harus mengembalikan user yang sama setelah login Google.
- `POST /api/mobile/v1/auth/logout` harus bisa revoke token Google login sama seperti token login manual.

Jika backend memakai Laravel Sanctum, implementasi harus membuat personal access token dari user yang sudah lolos verifikasi Google, bukan membuat session web.

## Error Response

Endpoint tidak boleh lagi mengembalikan `501` setelah verifier aktif.

Rekomendasi status:

- `200`: login berhasil.
- `422`: request body invalid, `id_token` invalid/expired, audience tidak cocok, issuer tidak valid, atau email Google belum verified.
- `403`: user tidak ditemukan, user nonaktif, atau user tidak boleh memakai aplikasi mobile.
- `500`: error internal yang tidak terduga.

Contoh response error:

```json
{
  "message": "Login Google tidak dapat digunakan untuk akun ini."
}
```

Untuk validation error Laravel, response boleh mengikuti format validation default selama Flutter tetap bisa menampilkan `message`.

## Checklist Implementasi Laravel

1. Tambahkan config environment untuk daftar Google OAuth client ID yang diizinkan.
2. Tambahkan service verifier Google token, misalnya `GoogleIdTokenVerifier`, yang mengembalikan payload verified atau throw validation exception.
3. Tambahkan controller method mobile Google token login.
4. Daftarkan route `POST /api/mobile/v1/auth/google/token` di group API mobile v1.
5. Reuse transformer/resource response login manual agar shape `access_token`, `token_type`, dan `user` konsisten.
6. Pastikan endpoint tidak memakai guard/session web SSO Laravel.
7. Pastikan logging tidak menyimpan `id_token`, bearer token, atau payload sensitif.
8. Hapus temporary `501 Not Implemented` response setelah verifier aktif.

## Feature Tests Backend

Tambahkan test untuk skenario berikut:

1. **Success**
   - `id_token` valid, audience diizinkan, email verified, user aktif.
   - Response `200` berisi `access_token`, `token_type: Bearer`, dan `user.role`.
   - Token bisa dipakai untuk `GET /api/mobile/v1/me`.

2. **Invalid token**
   - `id_token` kosong, malformed, expired, issuer salah, signature invalid, atau audience tidak diizinkan.
   - Response `422`.
   - Tidak ada token aplikasi yang dibuat.

3. **Email belum verified**
   - Token valid tetapi `email_verified` false.
   - Response `422`.
   - Tidak ada token aplikasi yang dibuat.

4. **Email tidak terdaftar**
   - Token valid dan email verified, tetapi tidak ada user Laravel dengan email tersebut.
   - Response `422` atau `403` sesuai policy final.
   - Tidak ada token aplikasi yang dibuat.

5. **User nonaktif atau tidak boleh mobile login**
   - Token valid, email terdaftar, tetapi user tidak boleh login.
   - Response `403`.
   - Tidak ada token aplikasi yang dibuat.

6. **Logout**
   - Login Google sukses.
   - `POST /api/mobile/v1/auth/logout` revoke token.
   - Token yang sama tidak bisa dipakai lagi untuk `/me`.

## Koordinasi dengan Flutter

Setelah endpoint Laravel siap:

1. Aktifkan kembali native `GoogleSignIn` di `lib/features/auth/presentation/screens/login_screen.dart`.
2. Pastikan `GOOGLE_SERVER_CLIENT_ID` Flutter cocok dengan salah satu client ID di allowlist backend.
3. Pastikan Flutter mengirim:
   - `id_token`
   - `server_auth_code` jika tersedia
   - `device_name`
4. Jalankan verifikasi manual:
   - Google login sukses.
   - Bearer token tersimpan di secure storage.
   - `/me` sukses.
   - Logout revoke token.
   - Login manual tetap sukses setelah logout atau kegagalan Google login.

## Acceptance Criteria

- `POST /api/mobile/v1/auth/google/token` tidak lagi return `501`.
- Endpoint menolak token Google yang tidak valid tanpa menerbitkan token aplikasi.
- Endpoint hanya menerbitkan bearer token untuk user existing yang aktif dan email Google verified.
- Response sukses sama bentuknya dengan login manual.
- Token hasil Google login kompatibel dengan `/me` dan `/auth/logout`.
- Flutter dapat mengaktifkan kembali native Google SSO tanpa perubahan parser response auth.
