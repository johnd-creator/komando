# Plan Perbaikan Foto Profil - Mobile API & Flutter

- Date: `2026-05-13`
- Scope: `ux`, `backend`
- Status: Planning

---

## Masalah

Foto profil yang di-upload via web backend tidak tampil di aplikasi mobile Flutter. Yang muncul hanya inisial nama (huruf "F" untuk akun Fauzi).

## Penyebab

Setelah dicek, **backend API sudah benar** — semua endpoint mobile sudah mengembalikan `photo_url` dan `avatar`:

| Endpoint | Field Foto | Sumber |
|----------|-----------|--------|
| `POST /auth/login` | `user.avatar` + `user.member.photo_url` | `UserResource` + `MemberResource` |
| `POST /auth/google/token` | `user.avatar` + `user.member.photo_url` | `UserResource` + `MemberResource` |
| `GET /me` | `user.avatar` + `user.member.photo_url` | `UserResource` + `MemberResource` |
| `GET /profile` | `member.photo_url` | `MemberResource` |
| `POST /profile/photo` | `member.photo_url` (response) | `MemberResource` |
| `DELETE /profile/photo` | `member.photo_url` (response) | `MemberResource` |

Masalah ada di **sisi Flutter** yang belum memanfaatkan field tersebut.

---

## Struktur Response API (Referensi untuk Flutter)

### Login / Me Response

```json
{
  "user": {
    "id": 2,
    "name": "Fauzi Ardiyanto",
    "email": "fauzi.ardiyanto@gmail.com",
    "avatar": "https://lh3.googleusercontent.com/a/ACg8oc...=s96-c",
    "role": { "id": 3, "name": "admin_unit", "label": "Sekretaris" },
    "current_unit_id": 10,
    "member_context_unit_id": 10,
    "member": {
      "id": 1,
      "full_name": "Fauzi Dwi Ardiyanto",
      "photo_url": "https://anggota.plnipservices.or.id/storage/members/photos/xxx.jpg",
      "organization_unit": { "id": 10, "name": "UBP Banten 1 Suralaya", "code": "010" },
      "union_position": { "id": 2, "name": "Sekretaris" }
    }
  }
}
```

### GET /profile Response

```json
{
  "member": {
    "id": 1,
    "full_name": "Fauzi Dwi Ardiyanto",
    "photo_url": "https://anggota.plnipservices.or.id/storage/members/photos/xxx.jpg"
  },
  "update_requests": []
}
```

### POST /profile/photo Response

```json
{
  "status": "ok",
  "member": {
    "id": 1,
    "full_name": "Fauzi Dwi Ardiyanto",
    "photo_url": "https://anggota.plnipservices.or.id/storage/members/photos/xxx.jpg"
  }
}
```

---

## Prioritas Foto (Fallback Chain)

Flutter harus implementasi urutan prioritas berikut:

```
1. member.photo_url  → Foto profil yang di-upload via web/app (prioritas utama)
2. user.avatar       → Google/Microsoft OAuth avatar (fallback)
3. Inisial nama      → Huruf pertama dari nama (fallback terakhir)
```

---

## Saran Perbaikan Flutter

### 1. Update Model User

```dart
// user.dart
@JsonSerializable()
class User {
  final int id;
  final String name;
  final String email;
  final String? avatar;          // Google/Microsoft OAuth avatar URL
  @JsonKey(name: 'current_unit_id')
  final int? currentUnitId;
  final Role? role;
  final Member? member;          // linked member (berisi photo_url)

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.currentUnitId,
    this.role,
    this.member,
  });

  /// Prioritas: member.photo_url > avatar > null
  String? get photoUrl => member?.photoUrl ?? avatar;

  /// Inisial untuk fallback avatar
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

### 2. Update Model Member

```dart
// member.dart
@JsonSerializable()
class Member {
  final int id;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String? email;
  final String? phone;
  @JsonKey(name: 'photo_url')
  final String? photoUrl;        // Foto profil dari upload web/app
  final String? status;
  @JsonKey(name: 'kta_number')
  final String? ktaNumber;
  final String? nra;
  final OrganizationUnit? organizationUnit;
  final UnionPosition? unionPosition;

  Member({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.photoUrl,
    this.status,
    this.ktaNumber,
    this.nra,
    this.organizationUnit,
    this.unionPosition,
  });

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
  Map<String, dynamic> toJson() => _$MemberToJson(this);
}
```

### 3. Widget Profile Avatar (Rekomendasi)

```dart
// widgets/profile_avatar.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 24,
  });

  String get _initial =>
      name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
        onBackgroundImageError: (_, __) {}, // suppress error, fallback to initial
        child: null, // will show background image
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
```

### 4. Cara Penggunaan di Screen

```dart
// Di sidebar/drawer, profile page, header, dll:
ProfileAvatar(
  photoUrl: user.photoUrl,    // otomatis: member.photo_url ?? user.avatar
  name: user.name,
  radius: 24,
)

// Kalau langsung dari profile endpoint:
ProfileAvatar(
  photoUrl: profileMember.photoUrl,  // member.photo_url
  name: profileMember.fullName,
  radius: 40,
)
```

### 5. Refresh Avatar Setelah Upload Foto

```dart
// Setelah POST /profile/photo berhasil:
final response = await dio.post('/profile/photo', data: formData);

// Update state dengan member baru dari response
final updatedMember = Member.fromJson(response.data['member']);
emit(ProfileLoaded(member: updatedMember));

// Atau re-fetch profile:
final profileResponse = await dio.get('/profile');
```

### 6. Refresh Avatar Setelah Login

```dart
// Setelah login berhasil, pastikan user.member.photoUrl tersimpan di state
final user = User.fromJson(response.data['user']);

// Cek apakah foto tersedia
debugPrint('photo_url: ${user.member?.photoUrl}');
debugPrint('avatar: ${user.avatar}');
debugPrint('resolved photoUrl: ${user.photoUrl}');
```

---

## Catatan Backend (Sudah OK, Tidak Perlu Perubahan)

| Komponen | Status | Keterangan |
|----------|--------|------------|
| `MemberResource::photo_url` | OK | Di-generate dari `Storage::disk('public')->url($this->photo_path)` |
| `UserResource::avatar` | OK | Langsung dari DB column `users.avatar` |
| `UserResource::member` | OK | Nested `MemberResource` via `linkedMember` relationship |
| `linkedMember` eager loading | OK | Di-load di login, google-token, dan /me |
| `POST /profile/photo` | OK | Upload, compress, simpan ke `public` disk, return `MemberResource` |
| `DELETE /profile/photo` | OK | Hapus file + set `photo_path = null`, return `MemberResource` |
| Web ↔ Mobile sinkronisasi | OK | Web dan mobile baca/tulis ke `members.photo_path` yang sama |

## Satu Perbaikan Backend (Opsional)

Mobile Google SSO saat ini **tidak menyimpan** `avatar` dari Google. Di web, `LoginController` menyimpan `$googleUser->getAvatar()` ke `users.avatar`, tapi di mobile `AuthController::googleToken()` tidak melakukan hal yang sama. Perbaikan:

**File:** `app/Http/Controllers/Api/Mobile/AuthController.php`
**Lokasi:** Setelah `$user = $this->hydrateMobileAuthUser($user);` (sekitar line 90)

```php
// Update avatar dari Google jika tersedia
if (! empty($payload['picture']) && $user->avatar !== $payload['picture']) {
    $user->avatar = mb_substr(trim($payload['picture']), 0, 4096);
    $user->save();
}
```

Ini memastikan user yang login pertama kali via mobile Google SSO juga punya avatar URL tersimpan.

---

## Checklist Implementasi Flutter

- [ ] Update `User` model: tambah field `avatar` dan `member` (dengan nested `Member`)
- [ ] Update `Member` model: tambah field `photoUrl` (mapped dari `photo_url`)
- [ ] Buat `ProfileAvatar` widget dengan fallback chain
- [ ] Gunakan `ProfileAvatar` di semua tempat yang menampilkan avatar (sidebar, profile page, header, dll)
- [ ] Handle refresh avatar setelah upload foto via `POST /profile/photo`
- [ ] Handle refresh avatar setelah delete foto via `DELETE /profile/photo`
- [ ] Pastikan `cached_network_image` sudah di `pubspec.yaml`
