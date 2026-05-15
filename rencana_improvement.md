# Rencana Improvement — Eksekusi per Batch

> Dokumen eksekusi konkret berbasis [`docs/masukan.md`](docs/masukan.md).
> Setiap batch dirancang **atomik** (1 sesi Claude), **independen sebisa mungkin**, dan **selalu meninggalkan codebase dalam keadaan buildable + tests passing**.

---

## Cara Pakai Dokumen Ini

1. Pilih batch yang ingin dieksekusi (urutan default: Phase 1 → 5).
2. Copy bagian **Prompt untuk Claude** di akhir batch.
3. Paste ke Claude (Kiro), tunggu eksekusi selesai.
4. Verifikasi dengan **Definition of Done**.
5. Centang checkbox di [Status Tracking](#status-tracking) di bawah.
6. Lanjut ke batch berikutnya.

**Aturan main**:
- Jangan kerjakan dua batch sekaligus dalam satu sesi (bisa saling konflik).
- Sebelum batch, pastikan branch git bersih (`git status`).
- Setiap batch harus pass `flutter analyze` & `flutter test` sebelum di-merge.

---

## Status Tracking

### Phase 1 — Foundation & Safety
- [x] **Batch 1.1** — Logger Terpusat & Gate `debugPrint`
- [x] **Batch 1.2** — API Client Hardening
- [x] **Batch 1.3** — Standardisasi `DuesBloc` & `DuesRepository`

### Phase 2 — Quick Performance Wins
- [x] **Batch 2.1** — Migrasi `Image.network` → `CachedNetworkImage`
- [x] **Batch 2.2** — Animation Lifecycle Cleanup
- [x] **Batch 2.3** — Paralelisasi API Calls & Cache `defaultAmount`

### Phase 3 — Stability & Resource
- [x] **Batch 3.1** — Resource Leak Fixes
- [x] **Batch 3.2** — Pindah Eager Bloc dari `main.dart`
- [x] **Batch 3.3** — Cache TTL & Invalidation

### Phase 4 — Code Quality
- [x] **Batch 4.1** — `AppColors` Token System
- [x] **Batch 4.2** — Util `Currency` & `DateFormat` Terpusat
- [x] **Batch 4.3** — Split File `my_dues_screen.dart`
- [x] **Batch 4.4** — Lint Rules Lebih Ketat

### Phase 5 — Observability
- [x] **Batch 5.1** — Crash Reporter Setup
- [x] **Batch 5.2** — Performance Monitoring & Cleanup Akhir

---

## Phase 1 — Foundation & Safety

> **Tujuan phase**: Pasang fondasi yang dibutuhkan oleh batch-batch berikutnya: logging yang aman, networking yang tahan banting, dan pattern bloc standar.

### Batch 1.1 — Logger Terpusat & Gate `debugPrint`

**Konteks**: Saat ini `debugPrint` mencetak PII (nama, photoUrl) dan flooding log per image load. Profile mode tetap mencetak.

**Files affected**:
- ✏️ Buat baru: `lib/core/logging/app_logger.dart`
- 🔧 Edit: `lib/features/profile/data/repositories/profile_repository.dart` (line 25, 27, 41, 43)
- 🔧 Edit: `lib/features/auth/data/repositories/auth_repository_impl.dart` (line 41-44, 55, 103-106, 116)
- 🔧 Edit: `lib/core/network/authenticated_image_provider.dart` (line 51, 58, 65, 73, 83)
- 🔧 Edit: `lib/features/dues/repository/dues_repository.dart` (line 107, 118)
- 🔧 Edit: `lib/features/dues/bloc/dues_admin_bloc.dart` (line 122, 127, 142, 167-170)

**Tugas**:
1. Buat `AppLogger` class dengan method `d/i/w/e` yang otomatis mati di non-debug build
2. Replace semua `debugPrint(...)` di file-file di atas dengan `AppLogger.d(...)` (atau `e` untuk error)
3. Untuk PII: gunakan tag `[Profile]`, `[Auth]` dan **jangan print full payload** — hanya status code atau key non-sensitif
4. Tambahkan helper `AppLogger.api(method, path, statusCode)` untuk logging API yang konsisten

**Definition of Done**:
- ✅ `flutter analyze` — 0 issue
- ✅ Tidak ada lagi `debugPrint(` di 5 file di atas (kecuali wrapping di logger sendiri)
- ✅ Build di release mode tidak mencetak log API/profile (verify manual: `flutter run --release`)
- ✅ Tidak ada response body lengkap yang di-print

**Prompt untuk Claude**:
```
Eksekusi Batch 1.1 dari rencana_improvement.md:

1. Buat lib/core/logging/app_logger.dart dengan class AppLogger yang punya:
   - static d(String message, {String tag = 'App'}) — debug, hanya jalan di kDebugMode
   - static i(String message, {String tag = 'App'})
   - static w(String message, {String tag = 'App'})
   - static e(String message, {Object? error, StackTrace? stack, String tag = 'App'})
   - static api(String method, String path, {int? statusCode}) — untuk API logging
   Semua method gunakan kDebugMode guard agar mati di release & profile build.

2. Replace semua debugPrint di file-file berikut dengan AppLogger:
   - lib/features/profile/data/repositories/profile_repository.dart
   - lib/features/auth/data/repositories/auth_repository_impl.dart
   - lib/core/network/authenticated_image_provider.dart
   - lib/features/dues/repository/dues_repository.dart
   - lib/features/dues/bloc/dues_admin_bloc.dart

3. PENTING: Untuk PII (nama, email, photoUrl, response body) — jangan cetak ke log.
   Cukup tag + status code + ID yang non-sensitif.

Setelah selesai jalankan `flutter analyze` dan pastikan tidak ada error.
```

---

### Batch 1.2 — API Client Hardening

**Konteks**: `ApiClient` tidak punya `sendTimeout` (upload bisa hang), tidak ada retry untuk transient error, tidak ada response cache.

**Files affected**:
- 🔧 Edit: `lib/core/api/api_client.dart`
- 🔧 Edit: `pubspec.yaml`
- 🔧 Edit: `lib/features/news/data/wordpress_client.dart` (tambah `sendTimeout` juga)

**Tugas**:
1. Tambah dependency:
   ```yaml
   dio_smart_retry: ^7.0.1
   ```
2. Di `api_client.dart`:
   - Tambah `sendTimeout: const Duration(seconds: 60)` ke `BaseOptions`
   - Tambah `RetryInterceptor` dengan default config (retry 502/503/504 + network error, max 3x)
3. Di `wordpress_client.dart`: tambah `sendTimeout` (opsional, baca-only client)
4. Pastikan urutan interceptor: **AuthInterceptor dulu, Retry setelahnya**

**Definition of Done**:
- ✅ `flutter pub get` sukses
- ✅ `flutter analyze` — 0 issue
- ✅ `flutter test test/core/api/` masih pass
- ✅ Manual test: matikan WiFi → buka aspirasi → muncul "Tidak ada koneksi" tanpa hang lama

**Prompt untuk Claude**:
```
Eksekusi Batch 1.2 dari rencana_improvement.md:

1. Tambahkan dependency `dio_smart_retry: ^7.0.1` ke pubspec.yaml dependencies, lalu jalankan flutter pub get.

2. Edit lib/core/api/api_client.dart:
   - Tambah sendTimeout: Duration(seconds: 60) ke BaseOptions
   - Tambah RetryInterceptor setelah auth interceptor dengan config default:
     - retries: 3
     - retryDelays: [Duration(seconds: 1), Duration(seconds: 2), Duration(seconds: 3)]
   - Pastikan urutan: auth interceptor dulu, retry interceptor kedua

3. Edit lib/features/news/data/wordpress_client.dart:
   - Tambah sendTimeout: Duration(seconds: 30)

Verifikasi: flutter analyze + flutter test test/core/api/

JANGAN tambahkan dio_cache_interceptor di batch ini — itu untuk batch lain.
```

---

### Batch 1.3 — Standardisasi `DuesBloc` & `DuesRepository`

**Konteks**: `DuesBloc` pakai parsing error manual (berisiko crash), tidak ada timeout, repository return `Map<String, dynamic>` (untyped).

**Files affected**:
- 🔧 Edit: `lib/features/dues/bloc/dues_bloc.dart`
- 🔧 Edit: `lib/features/dues/repository/dues_repository.dart`
- ✏️ Buat baru: `lib/features/dues/models/my_dues_result.dart`
- 🔧 Edit (jika ada test): `test/features/dues/...`

**Tugas**:
1. Buat `MyDuesResult` value object:
   ```dart
   class MyDuesResult {
     final bool hasMember;
     final List<DuesPayment> payments;
     final DuesSummary? summary;
     final double defaultAmount;
   }
   ```
2. `DuesRepository.getMyDues()` return `MyDuesResult` (bukan `Map`)
3. `DuesBloc._onLoadMyDues` & `_onRefreshMyDues`:
   - Pakai `ApiErrorHandler.getMessage(e)` (bukan parse manual)
   - Tambah `.timeout(const Duration(seconds: 20))`
   - Pakai `MyDuesResult` typed
4. Update test yang terimbas (jika ada)

**Definition of Done**:
- ✅ `flutter analyze` — 0 issue
- ✅ `flutter test test/features/dues/` pass
- ✅ Manual test: buka "Iuran Saya" → data muncul normal
- ✅ Manual test: matikan WiFi → buka "Iuran Saya" → muncul pesan ID yang ramah dari `ApiErrorHandler`

**Prompt untuk Claude**:
```
Eksekusi Batch 1.3 dari rencana_improvement.md:

1. Buat lib/features/dues/models/my_dues_result.dart dengan class MyDuesResult yang berisi:
   - bool hasMember
   - List<DuesPayment> payments
   - DuesSummary? summary
   - double defaultAmount
   Tambahkan const constructor dan copyWith.

2. Refactor lib/features/dues/repository/dues_repository.dart:
   - getMyDues() return Future<MyDuesResult> (bukan Map<String, dynamic>)
   - Logika parsing tetap sama, hanya wrapping ke MyDuesResult

3. Refactor lib/features/dues/bloc/dues_bloc.dart:
   - Import ApiErrorHandler dari core/api/api_error_handler.dart
   - _onLoadMyDues dan _onRefreshMyDues:
     * Tambah .timeout(const Duration(seconds: 20))
     * Replace parsing error manual dengan ApiErrorHandler.getMessage(e)
     * Pakai MyDuesResult typed
   - Hapus import dio:DioException jika tidak dipakai lagi

4. Update test test/features/dues/ jika ada yang terimbas perubahan API.

Verifikasi: flutter analyze + flutter test test/features/dues/
```

---

## Phase 2 — Quick Performance Wins

> **Tujuan phase**: Optimasi yang langsung terasa di mata user — image loading lebih cepat, scroll lebih halus, page load lebih cepat.

### Batch 2.1 — Migrasi `Image.network` → `CachedNetworkImage`

**Konteks**: Package `cached_network_image: ^3.4.1` sudah di pubspec tapi tidak dipakai sama sekali. Setiap rebuild widget gambar memicu request ulang.

**Files affected**:
- 🔧 Edit: `lib/features/home/presentation/screens/home_screen.dart` (line 962-967)
- 🔧 Edit: `lib/features/news/presentation/screens/news_list_screen.dart` (line 162, 354)
- 🔍 Cari & ganti: semua `Image.network` di seluruh `lib/`

**Tugas**:
1. Cari semua `Image.network(` dengan grep
2. Ganti ke `CachedNetworkImage` dengan placeholder + errorWidget
3. Jika belum ada, buat shared widget `lib/shared/presentation/widgets/cached_image.dart` agar pola placeholder/error konsisten
4. Pastikan `fit`, `width`, `height` ter-preserve

**Definition of Done**:
- ✅ `grep -r "Image.network(" lib/` → 0 hasil
- ✅ `flutter analyze` — 0 issue
- ✅ Manual test: scroll Home → gambar berita load dari cache di scroll kedua (cek dengan disconnect WiFi setelah scroll pertama)

**Prompt untuk Claude**:
```
Eksekusi Batch 2.1 dari rencana_improvement.md:

1. Buat lib/shared/presentation/widgets/cached_image.dart — wrapper widget CachedNetworkImage
   dengan placeholder shimmer/skeleton sederhana dan errorWidget icon broken_image.
   Props: imageUrl, fit, width, height, borderRadius (opsional).

2. Cari semua penggunaan Image.network( di seluruh lib/ dengan grep_search.

3. Ganti satu per satu dengan CachedImage atau CachedNetworkImage langsung,
   pertahankan fit/width/height yang sudah ada.
   Lokasi yang sudah teridentifikasi:
   - lib/features/home/presentation/screens/home_screen.dart
   - lib/features/news/presentation/screens/news_list_screen.dart

4. Jangan sentuh AuthenticatedImageProvider (KTA digital) — itu butuh auth header,
   akan dihandle di Batch 3.x lain.

Verifikasi: 
- grep -r "Image.network(" lib/ harus 0 hasil
- flutter analyze 0 issue
```

---

### Batch 2.2 — Animation Lifecycle Cleanup

**Konteks**:
- `_animationController.forward()` dipanggil di dalam `BlocBuilder.builder` (anti-pattern)
- `AnimatedOpacity` dengan opacity hardcoded 1.0 (overhead murni)
- Animasi per-item di list panjang membebani fps

**Files affected**:
- 🔧 Edit: `lib/features/dues/screens/my_dues_screen.dart` (line 59, 102-145)
- 🔧 Edit: `lib/features/letters/presentation/screens/letter_detail_screen.dart` (line 79)
- 🔧 Edit: `lib/features/letters/presentation/screens/letter_list_screen.dart` (line 187-198)

**Tugas**:
1. Di `my_dues_screen.dart`:
   - Pindah `_animationController.forward()` dari `BlocBuilder.builder` ke `BlocListener` (atau gabung jadi `BlocConsumer`)
   - Cap animasi list ke 10 item pertama: kalau `index >= 10`, return `_DuesPaymentCard` tanpa wrapper animasi
2. Di `letter_detail_screen.dart`:
   - Pindah `_animationController.forward()` ke `BlocListener`
3. Di `letter_list_screen.dart`:
   - Hapus seluruh `AnimatedOpacity(opacity: 1.0, ...)` wrapper di line 187-198, kembalikan langsung `_LetterCard`

**Definition of Done**:
- ✅ `flutter analyze` — 0 issue
- ✅ Manual test: buka "Iuran Saya" dengan 50+ payment → scroll mulus 60fps
- ✅ Manual test: navigasi list ↔ detail surat → animasi tidak loop atau kacau

**Prompt untuk Claude**:
```
Eksekusi Batch 2.2 dari rencana_improvement.md:

1. lib/features/dues/screens/my_dues_screen.dart:
   - Convert BlocBuilder ke BlocConsumer
   - Pindah _animationController.forward() dari builder ke listener (trigger ketika status == DuesStatus.success)
   - Di SliverList.builder itemBuilder: kalau index >= 10, return _DuesPaymentCard langsung tanpa FadeTransition+SlideTransition

2. lib/features/letters/presentation/screens/letter_detail_screen.dart:
   - Pindah _animationController.forward() (line 79) dari builder ke BlocListener

3. lib/features/letters/presentation/screens/letter_list_screen.dart:
   - Hapus AnimatedOpacity wrapper di line 187-198, return _LetterCard langsung

Verifikasi: flutter analyze, lalu manual test scroll my_dues dengan banyak payment.
```

---

### Batch 2.3 — Paralelisasi API Calls & Cache `defaultAmount`

**Konteks**:
- `DuesRepository.getMyDues()` 3 sequential async (3-5s di 3G)
- `DuesAdminBloc._fetchData` panggil `getDefaultDuesAmount()` setiap fetch
- `setState(() {})` kosong di admin search

**Files affected**:
- 🔧 Edit: `lib/features/dues/repository/dues_repository.dart` (line 19-37)
- 🔧 Edit: `lib/features/dues/bloc/dues_admin_bloc.dart` (line 145-146)
- 🔧 Edit: `lib/features/dues/screens/dues_admin_list_screen.dart` (line 117)

**Tugas**:
1. `getMyDues()` pakai `Future.wait` untuk paralelkan:
   ```dart
   final results = await Future.wait([
     _dio.get<Map<String, dynamic>>('/dues'),
     _readConfigDuesDefaultAmount(),
     getDefaultDuesAmount(),
   ]);
   ```
   Pertahankan logika fallback `[fallback, apiDefault, configDefault, categoryDefault].reduce(max)`.
2. `DuesAdminBloc._fetchData`: panggil `getDefaultDuesAmount()` hanya jika `state.defaultAmount == 0`:
   ```dart
   final defaultAmount = state.defaultAmount > 0
       ? state.defaultAmount
       : (await repository.getDefaultDuesAmount() ?? DuesRepository.fallbackDuesAmount);
   ```
3. Hapus `setState(() {})` kosong di line 117 `dues_admin_list_screen.dart`. Jika icon clear search butuh rebuild, pakai `ValueListenableBuilder` pada `_searchController`.

**Definition of Done**:
- ✅ `flutter analyze` — 0 issue
- ✅ `flutter test test/features/dues/` pass
- ✅ Manual test: buka "Iuran Saya" pertama kali → loading lebih cepat ~30%
- ✅ Manual test: ganti filter di admin → tidak terlihat extra request `/finance/categories` di Network panel

**Prompt untuk Claude**:
```
Eksekusi Batch 2.3 dari rencana_improvement.md:

1. lib/features/dues/repository/dues_repository.dart:
   - Refactor getMyDues() agar 3 async calls paralel dengan Future.wait:
     a. _dio.get<Map<String, dynamic>>('/dues')
     b. _readConfigDuesDefaultAmount()
     c. getDefaultDuesAmount()
   - Pertahankan logika reduce max untuk resolvedDefaultAmount.

2. lib/features/dues/bloc/dues_admin_bloc.dart line 145-146:
   - Cache defaultAmount: hanya panggil repository.getDefaultDuesAmount() kalau state.defaultAmount == 0
   - Else, pakai state.defaultAmount yang sudah ada

3. lib/features/dues/screens/dues_admin_list_screen.dart line 117:
   - Hapus setState(() {}) kosong di _onSearchChanged
   - Jika perlu rebuild icon clear search, gunakan ValueListenableBuilder pada _searchController

Verifikasi: flutter analyze + flutter test test/features/dues/
```

---

## Phase 3 — Stability & Resource

> **Tujuan phase**: Eliminasi memory leak, optimalkan lifecycle, dan tambah caching strategi untuk reduce network call.

### Batch 3.1 — Resource Leak Fixes

**Konteks**: Beberapa controller tidak di-dispose, `context.watch` di build menyebabkan rebuild berlebihan.

**Files affected**:
- 🔧 Edit: `lib/features/finance/presentation/screens/ledger_detail_screen.dart` (line 243-247)
- 🔧 Edit: `lib/features/home/presentation/screens/home_screen.dart` (line 188-191)

**Tugas**:
1. `ledger_detail_screen.dart` `_showRejectDialog`: convert ke method dengan `try/finally` agar `TextEditingController` selalu di-dispose:
   ```dart
   Future<void> _showRejectDialog() async {
     final ctrl = TextEditingController();
     try {
       final reason = await showDialog<String>(...);
       // gunakan reason
     } finally {
       ctrl.dispose();
     }
   }
   ```
2. `home_screen.dart` line 188-191: ganti `context.watch<AuthBloc>().state` dengan `context.select<AuthBloc, bool>` yang hanya rebuild saat role berubah.

**Definition of Done**:
- ✅ `flutter analyze` — 0 issue
- ✅ Manual test: buka reject dialog 10x lalu close → tidak ada warning controller leak di console
- ✅ Manual test: home screen rebuild count lebih jarang (cek dengan Flutter Inspector → Performance Overlay)

**Prompt untuk Claude**:
```
Eksekusi Batch 3.1 dari rencana_improvement.md:

1. lib/features/finance/presentation/screens/ledger_detail_screen.dart line 243-247:
   - Refactor _showRejectDialog agar TextEditingController di-dispose via try/finally
   - Pastikan controller dispose terjadi setelah dialog ditutup, baik user submit atau cancel

2. lib/features/home/presentation/screens/home_screen.dart line 188-191:
   - Ganti context.watch<AuthBloc>().state dengan context.select<AuthBloc, bool>
   - Selector return hanya boolean showBendahara, sehingga rebuild hanya terjadi saat role berubah

Verifikasi: flutter analyze + manual test buka tutup reject dialog beberapa kali.
```

---

### Batch 3.2 — Pindah Eager Bloc dari `main.dart`

**Konteks**: 4 bloc (Dashboard, Kta, Notification, Profile) di-instantiate di root `MultiBlocProvider` walau hanya dipakai di tab `MainShell`. Tambah cold start time.

**Files affected**:
- 🔧 Edit: `lib/main.dart` (line 79-95)
- 🔧 Edit: `lib/shared/presentation/screens/main_shell.dart`

**Tugas**:
1. Pindah `DashboardBloc`, `KtaBloc`, `NotificationBloc`, `ProfileBloc` dari `main.dart` ke `MainShell`. `AuthBloc` tetap di root.
2. Repository (`DashboardRepository`, `KtaRepository`, dll) tetap di-construct di `main.dart` lalu di-pass ke `MainShell` via constructor atau `RepositoryProvider`.
3. `MainShell` jadi widget yang membuat `MultiBlocProvider` dengan 4 bloc tersebut sebagai parent dari body.
4. Pastikan tidak ada screen yang pernah `read<DashboardBloc>` di luar tree `MainShell`.

**Definition of Done**:
- ✅ `flutter analyze` — 0 issue
- ✅ App tetap berjalan: tab Beranda/KTA/Notifikasi/Profil semua functional
- ✅ Manual test: buka app di low-end device → cold start lebih cepat (subjektif tapi terasa)

**Prompt untuk Claude**:
```
Eksekusi Batch 3.2 dari rencana_improvement.md:

1. Edit lib/main.dart line 79-95:
   - Hapus 4 BlocProvider berikut dari MultiBlocProvider root:
     * DashboardBloc, KtaBloc, NotificationBloc, ProfileBloc
   - Sisakan hanya AuthBloc.value di root.
   - Repository tetap di-construct di main() (biarkan).
   - Pass repository ke MainShell via RepositoryProvider atau constructor parameter.

2. Edit lib/shared/presentation/screens/main_shell.dart:
   - Convert ke widget yang wrap body dengan MultiBlocProvider berisi 4 bloc tersebut
   - Pastikan IndexedStack body tetap ter-wrap dengan provider

3. Cek dengan grep: cari semua context.read<DashboardBloc>(), context.read<KtaBloc>(), 
   context.read<NotificationBloc>(), context.read<ProfileBloc>() — pastikan semua dipanggil 
   di dalam subtree MainShell.

Verifikasi: flutter analyze + manual test semua tab di MainShell berfungsi normal.
```

---

### Batch 3.3 — Cache TTL & Invalidation

**Konteks**: `AppCache` tidak punya TTL. Profile cached selamanya. News pakai `cached_at` tapi tidak pernah di-check.

**Files affected**:
- 🔧 Edit: `lib/core/cache/app_cache.dart`
- 🔧 Edit: `lib/features/profile/data/repositories/profile_repository.dart`
- 🔧 Edit: `lib/features/news/data/repositories/news_repository.dart`

**Tugas**:
1. Tambah method di `AppCache`:
   ```dart
   Future<bool> isStale(String key, Duration maxAge) async {
     final raw = await readJson(key);
     final cachedAt = DateTime.tryParse(raw?['_cached_at'] as String? ?? '');
     if (cachedAt == null) return true;
     return DateTime.now().difference(cachedAt) > maxAge;
   }
   ```
2. Modifikasi `writeJson` agar otomatis tambah `_cached_at` (atau buat method `writeJsonWithMeta`).
3. `ProfileRepository.getCachedProfile()` return `null` kalau stale (>30 menit).
4. `NewsRepository.getCachedPosts()` return empty kalau stale (>15 menit).
5. Update call site (mis. `home_screen.dart` `_loadLatestNews`) — kalau cached stale, anggap kosong.

**Definition of Done**:
- ✅ `flutter analyze` — 0 issue
- ✅ Manual test: ubah jam device maju 1 jam → relaunch app → profile re-fetch dari API
- ✅ News list refresh dari API setelah TTL lewat

**Prompt untuk Claude**:
```
Eksekusi Batch 3.3 dari rencana_improvement.md:

1. lib/core/cache/app_cache.dart:
   - Tambah method `Future<bool> isStale(String key, Duration maxAge)` 
     yang baca '_cached_at' dari JSON dan compare dengan DateTime.now().
   - Modifikasi writeJson agar otomatis menambahkan _cached_at: DateTime.now().toIso8601String()
     sebelum encode (clone map dulu, jangan mutate input).

2. lib/features/profile/data/repositories/profile_repository.dart:
   - getCachedProfile() return null kalau isStale(profileKey, Duration(minutes: 30))

3. lib/features/news/data/repositories/news_repository.dart:
   - getCachedPosts() & getCachedLatestPosts() return [] kalau isStale dengan TTL 15 menit

4. Update call site yang relevan di home_screen.dart (_loadLatestNews) jika perlu
   handle case cached null/empty.

Verifikasi: flutter analyze + manual test cache expiry behavior.
```

---

## Phase 4 — Code Quality

> **Tujuan phase**: Maintainability jangka panjang. File besar dipecah, magic numbers diberi nama, lint diperketat.

### Batch 4.1 — `AppColors` Token System

**Konteks**: 475+ literal `Color(0xFF...)` tersebar. Tidak konsisten antar screen.

**Files affected**:
- ✏️ Buat baru: `lib/core/theme/app_colors.dart`
- 🔧 Edit (migrasi awal — 1 modul saja): `lib/features/dues/screens/my_dues_screen.dart` + sub-widget

**Tugas**:
1. Buat `AppColors` class dengan token:
   - Primary: `primary`, `primaryLight`, `primaryDark`
   - Status: `success`, `warning`, `error`, `info`
   - Surface: `surface`, `surfaceAlt`, `border`, `divider`
   - Text: `textPrimary`, `textSecondary`, `textMuted`
   - Common gradients via static method
2. Migrasi **hanya modul Dues** (file `my_dues_screen.dart` + child widget) sebagai POC. Modul lain di batch terpisah jika perlu.
3. Pastikan visual TIDAK BERUBAH — token mereplikasi warna yang sudah ada.

**Definition of Done**:
- ✅ `flutter analyze` — 0 issue
- ✅ `lib/features/dues/screens/my_dues_screen.dart` tidak ada lagi `Color(0xFF...)` literal (semua via `AppColors.x`)
- ✅ Manual test: tampilan "Iuran Saya" identik dengan sebelum migrasi

**Prompt untuk Claude**:
```
Eksekusi Batch 4.1 dari rencana_improvement.md:

1. Buat lib/core/theme/app_colors.dart dengan class AppColors (private constructor) berisi static const:
   - primary: 0xFF1565C0
   - primaryLight: 0xFF1E88E5
   - primaryDark: 0xFF0D47A1
   - success: 0xFF22C55E
   - warning: 0xFFF97316
   - error: 0xFFEF4444
   - info: 0xFF3B82F6
   - surface: 0xFFF5F7FA
   - surfaceAlt: 0xFFF7F9FC
   - border: 0xFFE1E8F2
   - divider: 0xFFE3EBF8
   - textPrimary: 0xFF1A1A2E
   - textSecondary: 0xFF536683
   - textMuted: 0xFF64748B
   Tambah komentar untuk masing-masing token.

2. Migrasi lib/features/dues/screens/my_dues_screen.dart:
   - Replace semua Color(0xFF...) literal dengan AppColors.xxx yang setara
   - PENTING: tampilan visual tidak boleh berubah. Kalau warna tidak ada di token, tambahkan ke AppColors dulu.

Verifikasi: flutter analyze + manual test buka "Iuran Saya" dan bandingkan dengan screenshot sebelumnya.
Migrasi modul lain bukan scope batch ini.
```

---

### Batch 4.2 — Util `Currency` & `DateFormat` Terpusat

**Konteks**: Method `_formatAmount` dengan regex `(\d{1,3})(?=(\d{3})+(?!\d))` diduplikasi di 4+ file. `_formatPeriod` & `_monthNames` juga.

**Files affected**:
- 🔧 Edit: `pubspec.yaml`
- ✏️ Buat baru: `lib/core/utils/currency.dart`
- ✏️ Buat baru: `lib/core/utils/date_period.dart`
- 🔧 Edit (migrasi): 4 file dengan `_formatAmount` (lihat di bawah)

**Tugas**:
1. Tambah dependency `intl: ^0.20.2` (versi sesuaikan dengan Flutter SDK)
2. Buat `lib/core/utils/currency.dart`:
   ```dart
   String formatRupiah(double amount, {bool showPrefix = true}) {
     final formatter = NumberFormat.currency(
       locale: 'id_ID',
       symbol: showPrefix ? 'Rp ' : '',
       decimalDigits: 0,
     );
     return formatter.format(amount);
   }
   ```
3. Buat `lib/core/utils/date_period.dart`:
   - `formatPeriod(String yyyyMM)` → "Jan 2026"
   - `formatPeriodLong(DateTime)` → "Januari 2026"
   - `parsePeriod(String)` → `DateTime?`
4. Migrasi 4 file:
   - `lib/features/dues/screens/my_dues_screen.dart` (line 198-201, 805-810)
   - `lib/features/finance/presentation/screens/keuangan_screen.dart` (line 797)
   - `lib/features/dues/screens/dues_admin_list_screen.dart` (line 303-306)
   - `lib/features/admin/presentation/screens/admin_dashboard_screen.dart` (line 732)

**Definition of Done**:
- ✅ `flutter analyze` — 0 issue
- ✅ `flutter test` pass
- ✅ Manual test: format Rupiah & periode tampil sama persis seperti sebelumnya

**Prompt untuk Claude**:
```
Eksekusi Batch 4.2 dari rencana_improvement.md:

1. Tambah dependency intl ke pubspec.yaml (versi cek yang kompatibel dengan Flutter SDK 3.10.4),
   lalu flutter pub get.

2. Buat lib/core/utils/currency.dart dengan top-level function:
   - formatRupiah(double amount, {bool showPrefix = true}) → String
   Pakai NumberFormat.currency dari intl dengan locale id_ID.

3. Buat lib/core/utils/date_period.dart dengan top-level function:
   - formatPeriod(String yyyyMM) → "Jan 2026" (3 huruf bulan ID + tahun)
   - formatPeriodLong(DateTime date) → "Januari 2026"
   - parsePeriod(String yyyyMM) → DateTime?

4. Migrasi 4 file berikut: ganti _formatAmount lokal dengan formatRupiah,
   dan _formatPeriod lokal dengan formatPeriod:
   - lib/features/dues/screens/my_dues_screen.dart
   - lib/features/finance/presentation/screens/keuangan_screen.dart
   - lib/features/dues/screens/dues_admin_list_screen.dart (juga _monthNames → formatPeriodLong)
   - lib/features/admin/presentation/screens/admin_dashboard_screen.dart

Verifikasi: flutter analyze + flutter test + manual cek tampilan Rupiah/periode tidak berubah.
```

---

### Batch 4.3 — Split File `my_dues_screen.dart`

**Konteks**: File 1013 baris berisi banyak private widget. Sulit di-test dan di-maintain.

**Files affected**:
- 🔧 Edit: `lib/features/dues/screens/my_dues_screen.dart`
- ✏️ Buat baru: `lib/features/dues/widgets/dues_summary_section.dart`
- ✏️ Buat baru: `lib/features/dues/widgets/dues_payment_card.dart`
- ✏️ Buat baru: `lib/features/dues/widgets/dues_empty_view.dart`
- ✏️ Buat baru: `lib/features/dues/widgets/dues_loading_view.dart`
- ✏️ Buat baru: `lib/features/dues/widgets/dues_error_view.dart`
- ✏️ Buat baru: `lib/features/dues/widgets/dues_no_member_view.dart`
- ✏️ Buat baru: `lib/features/dues/widgets/dues_stat_card.dart`

**Tugas**:
1. Pindahkan `_SummarySection` → `widgets/dues_summary_section.dart` sebagai `DuesSummarySection`
2. Pindahkan `_DuesPaymentCard` → `widgets/dues_payment_card.dart`
3. Pindahkan `_StatCard` → `widgets/dues_stat_card.dart`
4. Pindahkan `_LoadingView`, `_ErrorView`, `_NoMemberView`, `_EmptyPaymentsView` ke masing-masing file widget
5. `my_dues_screen.dart` jadi <200 baris, hanya orchestrator

**Definition of Done**:
- ✅ `flutter analyze` — 0 issue
- ✅ `my_dues_screen.dart` < 200 baris
- ✅ `flutter test test/features/dues/` pass
- ✅ Manual test: tampilan & behavior identik dengan sebelumnya

**Prompt untuk Claude**:
```
Eksekusi Batch 4.3 dari rencana_improvement.md:

Refactor lib/features/dues/screens/my_dues_screen.dart yang saat ini >1000 baris.

Pisahkan widget-widget private menjadi file terpisah di lib/features/dues/widgets/:
1. _SummarySection → dues_summary_section.dart (DuesSummarySection — public)
2. _StatCard → dues_stat_card.dart (DuesStatCard — public)
3. _DuesPaymentCard → dues_payment_card.dart (DuesPaymentCard — public)
4. _LoadingView → dues_loading_view.dart (DuesLoadingView — public)
5. _ErrorView → dues_error_view.dart (DuesErrorView — public)
6. _NoMemberView → dues_no_member_view.dart (DuesNoMemberView — public)
7. _EmptyPaymentsView → dues_empty_view.dart (DuesEmptyView — public)

Aturan:
- Tampilan dan behavior tidak boleh berubah
- Public widget di-prefix dengan `Dues` agar mudah dikenali
- Import di my_dues_screen.dart pakai relative path
- Pertahankan semua animasi & state hookup yang sudah ada
- File my_dues_screen.dart jadi <200 baris

Verifikasi: flutter analyze + flutter test + manual buka "Iuran Saya" → identik.
```

---

### Batch 4.4 — Lint Rules Lebih Ketat

**Konteks**: `analysis_options.yaml` hanya extends `flutter_lints`. Tambah rule untuk konsistensi.

**Files affected**:
- 🔧 Edit: `analysis_options.yaml`

**Tugas**:
1. Tambah rules ke `analysis_options.yaml`:
   ```yaml
   linter:
     rules:
       prefer_const_constructors: true
       prefer_const_constructors_in_immutables: true
       prefer_const_declarations: true
       prefer_const_literals_to_create_immutables: true
       avoid_print: true
       unawaited_futures: true
       require_trailing_commas: true
   ```
2. Jalankan `dart fix --apply` untuk auto-fix
3. Manual fix issue yang tidak otomatis (kemungkinan ratusan, fokus auto-fix saja dulu)

**Definition of Done**:
- ✅ `flutter analyze` — issue count terdokumentasi (kemungkinan masih ada warning)
- ✅ `dart fix --apply` sudah dijalankan
- ✅ Hasilnya tidak break build

**Prompt untuk Claude**:
```
Eksekusi Batch 4.4 dari rencana_improvement.md:

1. Edit analysis_options.yaml untuk menambah rules:
   - prefer_const_constructors: true
   - prefer_const_constructors_in_immutables: true
   - prefer_const_declarations: true
   - prefer_const_literals_to_create_immutables: true
   - avoid_print: true
   - unawaited_futures: true
   - require_trailing_commas: true

2. Jalankan dart fix --apply untuk auto-fix issue yang otomatis bisa di-resolve.

3. Jalankan flutter analyze dan tampilkan jumlah warning/error yang tersisa.
   Tidak perlu fix manual semua — laporkan saja statistik:
   - Berapa total warning
   - Top 3 rule yang paling sering trigger
   Saya akan tentukan apakah perlu fix manual di batch lain.

PENTING: kalau ada error (bukan warning) yang muncul setelah dart fix, kembalikan ke state semula.
```

---

## Phase 5 — Observability

> **Tujuan phase**: Capability untuk melacak masalah di production. Ini krusial sebelum app dirilis ke pengguna luas.

### Batch 5.1 — Crash Reporter Setup

**⚠️ Batch ini perlu input user** — pilih Sentry atau Firebase Crashlytics, dan setup project di provider tersebut.

**Konteks**: Saat ini crash di production tidak terlacak sama sekali. Tidak ada `FlutterError.onError` atau `runZonedGuarded`.

**Files affected**:
- 🔧 Edit: `pubspec.yaml`
- 🔧 Edit: `lib/main.dart`
- 🔧 Edit: `lib/core/logging/app_logger.dart` (hook ke crash reporter)
- 🔧 Edit: `android/app/build.gradle` (jika Firebase)
- 🔧 Edit: `ios/Runner/Info.plist` (jika Firebase)
- ✏️ Buat baru: `lib/core/observability/crash_reporter.dart`

**Tugas (jalankan SETELAH user setup project)**:
1. Tambah dependency:
   - **Opsi A — Sentry**: `sentry_flutter: ^8.x.x`
   - **Opsi B — Crashlytics**: `firebase_core` + `firebase_crashlytics`
2. Bungkus `main()` dengan `runZonedGuarded`:
   ```dart
   void main() {
     runZonedGuarded(() async {
       WidgetsFlutterBinding.ensureInitialized();
       await CrashReporter.init(); // setup Sentry/Crashlytics
       FlutterError.onError = CrashReporter.recordFlutterError;
       runApp(...);
     }, CrashReporter.recordError);
   }
   ```
3. Hook `AppLogger.e` ke `CrashReporter.recordError` di non-debug build
4. Test dengan force-throw exception

**Definition of Done**:
- ✅ `flutter analyze` — 0 issue
- ✅ Crash test (mis. tombol di debug menu yang `throw Exception('test')`) muncul di dashboard Sentry/Crashlytics dalam 5 menit

**Prompt untuk Claude**:
```
Eksekusi Batch 5.1 dari rencana_improvement.md.

PRASYARAT — sebelum mulai, tanya saya:
1. Pilih Sentry atau Firebase Crashlytics?
2. Untuk Sentry: minta DSN
3. Untuk Crashlytics: pastikan google-services.json sudah ada di android/app/

Setelah dapat input:

1. Tambah dependency yang sesuai ke pubspec.yaml.

2. Buat lib/core/observability/crash_reporter.dart dengan class CrashReporter:
   - static Future<void> init({required String? dsn})
   - static void recordFlutterError(FlutterErrorDetails details)
   - static void recordError(Object error, StackTrace stack, {bool fatal = false})
   - static void setUserId(String? id) — untuk attach user context

3. Edit lib/main.dart:
   - Bungkus dengan runZonedGuarded
   - Init CrashReporter sebelum runApp
   - Set FlutterError.onError = CrashReporter.recordFlutterError

4. Hook AppLogger.e ke CrashReporter.recordError di non-debug build.

5. Tambahkan helper di main_shell atau profile_screen untuk identifyUser saat login,
   panggil CrashReporter.setUserId.

Verifikasi: flutter analyze + manual force throw lalu cek dashboard provider.
```

---

### Batch 5.2 — Performance Monitoring & Cleanup Akhir

**Konteks**: Final pass untuk pasang monitoring dan finishing touches.

**Files affected**:
- 🔧 Edit: `pubspec.yaml` (hapus `package:http` jika sudah tidak dipakai)
- 🔧 Edit: `lib/core/observability/crash_reporter.dart` (tambah performance API)
- 🔧 Edit: `lib/core/api/api_client.dart` (tambah interceptor untuk traces)

**Tugas**:
1. Audit dependency `http` — kalau sudah tidak ada `import 'package:http/http.dart'` di seluruh `lib/`, hapus dari pubspec
2. Tambah performance API di `CrashReporter`:
   - `startTransaction(String name)` → return handle
   - `finishTransaction(handle)`
3. Wrap kritikal Dio request dengan transaction (mis. login, dashboard load)
4. Final `flutter analyze` & `flutter test` — pastikan semua hijau

**Definition of Done**:
- ✅ `flutter analyze` — 0 issue
- ✅ `flutter test` semua pass
- ✅ Performance dashboard menerima trace untuk endpoint kritikal
- ✅ Jika `package:http` sudah tidak dipakai, dependency dihapus

**Prompt untuk Claude**:
```
Eksekusi Batch 5.2 dari rencana_improvement.md:

1. Audit penggunaan package:http di seluruh lib/:
   - grep_search untuk import 'package:http/http.dart'
   - Kalau sudah 0 hasil, hapus http dari pubspec.yaml dependencies dan flutter pub get
   - Kalau masih ada (mis. di authenticated_image_provider.dart), 
     refactor pakai Dio dari ApiClient yang sudah ada

2. Tambah performance API di lib/core/observability/crash_reporter.dart:
   - static dynamic startTransaction(String name, {String operation = 'http'})
   - static void finishTransaction(dynamic handle)

3. Wrap pemanggilan API kritikal dengan transaction (login, dashboard initial load).
   Tambah di setidaknya 3 endpoint paling sering dipanggil.

4. Jalankan flutter analyze + flutter test final.

Verifikasi: semua test pass, dependency http hilang dari pubspec (jika applicable).
```

---

## Verification Gates

Sebelum batch berikutnya, **selalu**:

```bash
# 1. Static analysis
flutter analyze

# 2. Tests
flutter test

# 3. Build check (sekali per phase)
flutter build apk --debug

# 4. Git status — pastikan tidak ada untracked file penting yang lupa di-commit
git status
```

Jika ada salah satu yang gagal: **stop**, fix dulu, baru lanjut.

---

## Catatan Penting

### Yang TIDAK Termasuk Dalam Rencana Ini

Beberapa item di `masukan.md` **sengaja tidak** dibuat batch karena butuh diskusi tim:

- **Standardisasi struktur folder `dues/`** (masukan §7.4) — refactor besar, lebih baik diskusi struktur dulu
- **ShellRoute untuk list-detail** (masukan §4.2) — perubahan navigasi besar
- **Build flavors** (masukan §8.3) — butuh keputusan environment di tingkat tim
- **Custom font** (masukan §8.1) — butuh keputusan branding
- **Migrasi News ke Bloc** (masukan §3.5) — mid-size refactor

Item-item ini cocok dijadikan task terpisah setelah Phase 1-5 selesai.

### Aturan Saat Batch Gagal

Kalau Claude gagal di tengah batch:

1. **Cek `flutter analyze`** — kalau ada error compile, prioritas fix dulu
2. **`git diff`** — review apa yang sudah berubah
3. **`git restore .`** — kalau perubahan tidak bisa di-recover, rollback dan retry
4. **Mulai batch dari awal** — jangan coba lanjut dari tengah

### Estimasi Total Effort

- **Phase 1**: 3-4 jam (3 batch)
- **Phase 2**: 3-5 jam (3 batch)
- **Phase 3**: 4-6 jam (3 batch)
- **Phase 4**: 6-10 jam (4 batch)
- **Phase 5**: 3-5 jam (2 batch, tergantung setup external service)

**Total**: ~20-30 jam Claude execution + manual verification.

---

## Update Log

| Tanggal | Batch | Status | Catatan |
|---|---|---|---|
| _(diisi saat eksekusi)_ | | | |

