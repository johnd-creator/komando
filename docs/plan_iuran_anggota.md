# Plan: Fitur Iuran Anggota — Mobile (Flutter)

Date: 2026-05-10
Source: Analisis backend `finance/dues` & API `docs/api/mobile-v1.md`
Status: **Draft — Phase 0 (Backend Auth) pending**

---

## Executive Summary

Fitur **Iuran Anggota Mobile** adalah implementasi Flutter dari fitur iuran (dues) yang sudah tersedia di web panel SIM-SP. Mayoritas API backend sudah siap, tapi ada **perubahan otorisasi backend** yang diperlukan: akses manajemen iuran anggota bulanan (view + checklist bayar/belum) **hanya untuk role `bendahara`**. Role `bendahara_pusat` tidak memiliki anggota yang iuran bulanan sehingga tidak boleh mengakses menu ini.

Target fitur iuran mencakup dua persona:

| Persona | Role | API Endpoint | Keterangan |
|---------|------|-------------|------------|
| **Anggota** (member biasa) | `anggota` | `GET /dues` | Melihat riwayat iuran 12 bulan terakhir + ringkasan |
| **Bendahara** (pengurus unit) | `bendahara` saja | `GET /finance/dues`, `PATCH /finance/dues/{id}`, `PATCH /finance/dues/mass-update`, `GET /finance/dues/dashboard`, `GET /reports/dues` | Mengelola & menceklist pembayaran iuran anggota |
| **Admin Pusat / Super Admin** | `admin_pusat`, `super_admin` | View-only (opsional) | Melihat laporan iuran, tidak bisa checklist |

**⚠️ Aturan Akses Iuran Bulanan (Collective Monthly Dues):**
- ✅ **`bendahara`**: BISA lihat daftar iuran + checklist anggota sudah/belum bayar (unit sendiri)
- ❌ **`bendahara_pusat`**: TIDAK BOLEH akses iuran anggota bulanan — tidak memiliki anggota yang iuran
- ✅ **`super_admin` / `admin_pusat`**: BISA lihat laporan (view), tapi checklist hanya oleh `bendahara`

Dashboard utama mobile (`GET /dashboard`) juga mengembalikan data `dues` untuk status iuran bulan ini — perlu ditampilkan di widget dashboard (anggota).

---

## Phase 0: Backend — Bersihkan Otorisasi Iuran ⚠️ PRIORITAS

### Masalah Saat Ini

| File | Masalah |
|------|---------|
| `app/Http/Controllers/Api/Mobile/FinanceController.php` line 399 | `authorizeDuesAdmin()` mengizinkan `bendahara_pusat` |
| `app/Policies/DuesPaymentPolicy.php` line 59 | `create()` mengizinkan `bendahara_pusat` |
| `app/Http/Controllers/Api/Mobile/ReportController.php` line 73 | `dues()` mengizinkan `bendahara_pusat` |
| `app/Http/Controllers/Finance/FinanceDuesController.php` | Tidak ada explicit role check — bergantung pada policy `viewAny()` yang return `true` untuk semua role |

### 0.1 `FinanceController::authorizeDuesAdmin()` — Hapus `bendahara_pusat`

**File:** `app/Http/Controllers/Api/Mobile/FinanceController.php` line 397-399

```php
// BEFORE
private function authorizeDuesAdmin(Request $request): void
{
    abort_unless($request->user()->hasRole(['super_admin', 'admin_pusat', 'bendahara', 'bendahara_pusat']), 403);
}

// AFTER — hanya bendahara yang bisa kelola iuran anggota bulanan
private function authorizeDuesAdmin(Request $request): void
{
    abort_unless($request->user()->hasRole(['super_admin', 'admin_pusat', 'bendahara']), 403);
}
```

### 0.2 `DuesPaymentPolicy::create()` — Hapus `bendahara_pusat`

**File:** `app/Policies/DuesPaymentPolicy.php` line 56-59

```php
// BEFORE
public function create(User $user): bool
{
    return $user->hasRole(['super_admin', 'admin_pusat', 'bendahara', 'bendahara_pusat']);
}

// AFTER
public function create(User $user): bool
{
    return $user->hasRole(['super_admin', 'admin_pusat', 'bendahara']);
}
```

### 0.3 `DuesPaymentPolicy::view()` — Blokir `bendahara_pusat` dari lihat iuran anggota

**File:** `app/Policies/DuesPaymentPolicy.php` line 22-45

Saat ini `bendahara_pusat` lolos lewat `canViewGlobalScope()` yang return `true`. Perlu ditambah explicit block:

```php
public function view(User $user, DuesPayment $duesPayment): bool
{
    // bendahara_pusat tidak memiliki anggota iuran bulanan
    if ($user->hasRole('bendahara_pusat')) {
        return false;
    }

    if ($user->canViewGlobalScope()) {
        return true;
    }

    // ... existing logic ...
}
```

### 0.4 `ReportController::dues()` — Hapus `bendahara_pusat`

**File:** `app/Http/Controllers/Api/Mobile/ReportController.php` line 73

```php
// BEFORE
abort_unless($request->user()->hasRole(['super_admin', 'admin_pusat', 'bendahara', 'bendahara_pusat']), 403);

// AFTER
abort_unless($request->user()->hasRole(['super_admin', 'admin_pusat', 'bendahara']), 403);
```

### 0.5 Web `FinanceDuesController` — Tambah explicit check

**File:** `app/Http/Controllers/Finance/FinanceDuesController.php` (di method `index`, `update`, `massUpdate`)

Meskipun route group membatasi akses lewat middleware role, lebih aman menambah explicit check di controller:

```php
// Di awal method index()
abort_if($user->hasRole('bendahara_pusat'), 403, 'bendahara_pusat tidak memiliki akses iuran anggota bulanan.');
```

### 0.6 Verifikasi Backend

```bash
php artisan test --filter=DuesAuthorizationTest
php artisan test --filter=MobileApiTest
php artisan test --filter=FinanceUnitScopeTest
```

### 0.7 Catatan: `bendahara` tetap bisa lihat unit pusat

`bendahara` tetap bisa melihat data unit pusat via `applyDuesUnitScope()` / `accessibleFinanceUnitIds()` — ini untuk transparansi ledger pusat. Tapi untuk iuran anggota, data yang muncul adalah data anggota di unit sendiri.

---

## API Contracts (Backend)

### 1. `GET /dues` — Anggota: Riwayat Iuran Saya

**Controller:** `app/Http/Controllers/Api/Mobile/DuesController.php`

**Response shape:**
```json
{
  "has_member": true,
  "payments": [
    {
      "period": "2026-05",
      "status": "paid",
      "amount": 30000.0,
      "paid_at": "2026-05-03",
      "notes": null
    }
  ],
  "summary": {
    "current_period": "2026-05",
    "current_status": "paid",
    "unpaid_count": 2,
    "unpaid_periods": ["2026-03", "2026-02", "2026-01"]
  },
  "default_amount": 30000
}
```

### 2. `GET /dashboard` — Status Iuran di Dashboard

**Controller:** `app/Http/Controllers/Api/Mobile/DashboardController.php`

Bagian `dues` dari response:
```json
{
  "dues": {
    "period": "2026-05",
    "status": "unpaid",
    "amount": 30000.0,
    "paid_at": null
  }
}
```

### 3. `GET /finance/dues` — Admin: Daftar Iuran (paginated, scoped)

**Controller:** `app/Http/Controllers/Api/Mobile/FinanceController.php`
**Akses:** `bendahara` (unit sendiri), `super_admin` / `admin_pusat` (view all)

Query params: `period`, `status`, `member_id`, `unit_id`, `page`, `per_page`

### 4. `PATCH /finance/dues/{id}` — Admin: Update Satu Pembayaran

**Akses:** `bendahara` saja (checklist bayar/belum)

Request body:
```json
{ "status": "paid", "amount": 30000.0, "paid_at": "2026-05-07", "notes": null }
```

### 5. `PATCH /finance/dues/mass-update` — Admin: Batch Pembayaran

**Akses:** `bendahara` saja

Request body:
```json
{
  "items": [
    { "member_id": 1, "period": "2026-05", "status": "paid", "amount": 50000, "paid_at": "2026-05-07", "notes": null }
  ]
}
```
Max 200 items.

### 6. `GET /finance/dues/dashboard` — Admin: Summary Iuran

**Akses:** `bendahara`, `super_admin`, `admin_pusat`

Query params: `period`, `unit_id`

Response:
```json
{
  "summary": {
    "paid": 120,
    "unpaid": 45,
    "waived": 3,
    "total_amount": 5040000.0
  }
}
```

### 7. `GET /reports/dues` — Laporan Statistik Iuran

**Akses:** `bendahara`, `super_admin`, `admin_pusat`

Query params: `unit_id`

### 8. `GET /meta/lookups` — Config Dues

**Controller:** `app/Http/Controllers/Api/Mobile/MetaController.php`

Returns `dues.default_amount` dan `dues.due_day`.

---

## Flutter Implementation Plan

### Arsitektur yang Direkomendasikan

State management: **flutter_bloc** (sesuai rekomendasi API docs)
HTTP client: **dio** (sudah ada interceptor token di setup guide)
JSON serialization: **json_serializable** + **build_runner**
Secure storage: **flutter_secure_storage** (token)

```
lib/
├── features/
│   └── dues/
│       ├── bloc/
│       │   ├── dues_bloc.dart              # Event/state untuk anggota view
│       │   ├── dues_event.dart
│       │   ├── dues_state.dart
│       │   ├── dues_admin_bloc.dart        # Event/state untuk admin view
│       │   ├── dues_admin_event.dart
│       │   └── dues_admin_state.dart
│       ├── models/
│       │   ├── dues_payment.dart           # JSON-serializable model
│       │   ├── dues_summary.dart
│       │   └── dues_mass_update_item.dart
│       ├── repository/
│       │   └── dues_repository.dart        # Dio calls ke semua endpoint iuran
│       ├── screens/
│       │   ├── my_dues_screen.dart         # Anggota: riwayat 12 bulan
│       │   ├── dues_admin_list_screen.dart # Bendahara: daftar iuran anggota
│       │   └── dues_admin_detail_screen.dart # Bendahara: update/lihat detail
│       └── widgets/
│           ├── dues_card.dart              # Card per bulan
│           ├── dues_summary_card.dart       # Ringkasan statistik
│           ├── dues_filter_bar.dart         # Filter period/status/unit
│           ├── dues_mass_pay_dialog.dart    # Dialog batch payment
│           └── dues_status_badge.dart       # Badge paid/unpaid/waived
├── core/
│   ├── network/
│   │   └── dio_client.dart                 # Dio instance + interceptor
│   └── theme/
│       └── app_colors.dart                 # Warna sesuai status
```

---

## Phase 1: Model & Repository Layer

### 1.1 Model `DuesPayment`

File: `lib/features/dues/models/dues_payment.dart`

```dart
@JsonSerializable()
class DuesPayment {
  final String period;
  final String status;       // 'paid' | 'unpaid' | 'waived'
  final double amount;
  final String? paidAt;
  final String? notes;

  bool get isPaid => status == 'paid';
  bool get isWaived => status == 'waived';
  String get formattedPeriod { /* 2026-05 → Mei 2026 */ }
}
```

### 1.2 Model `DuesSummary`

File: `lib/features/dues/models/dues_summary.dart`

```dart
@JsonSerializable()
class DuesSummary {
  final String currentPeriod;
  final String currentStatus;
  final int unpaidCount;
  final List<String> unpaidPeriods;
}
```

### 1.3 Model untuk Admin

```dart
@JsonSerializable()
class DuesAdminSummary {
  final int paid;
  final int unpaid;
  final int waived;
  final double totalAmount;
}

@JsonSerializable()
class DuesMassUpdateItem {
  final int memberId;
  final String period;
  final String status;
  final double amount;
  final String? paidAt;
  final String? notes;
}
```

### 1.4 `DuesRepository`

File: `lib/features/dues/repository/dues_repository.dart`

| Method | API | Return |
|--------|-----|--------|
| `getMyDues()` | `GET /dues` | `{hasMember, payments, summary}` |
| `getDashboardDues()` | `GET /dashboard` (field `dues`) | `DuesPayment?` |
| `getAdminDues({filters})` | `GET /finance/dues` | Paginated `List<DuesPayment>` |
| `getAdminDuesSummary({period, unitId})` | `GET /finance/dues/dashboard` | `DuesAdminSummary` |
| `updateDuesPayment(id, body)` | `PATCH /finance/dues/{id}` | `DuesPayment` |
| `massUpdateDues(items)` | `PATCH /finance/dues/mass-update` | `{updated: count}` |
| `getDuesReport({unitId})` | `GET /reports/dues` | Report summary |

Semua method throw `DioException` — error handling di Bloc layer.

---

## Phase 2: Bloc — Anggota (My Dues)

### 2.1 State

```dart
enum DuesStatus { initial, loading, success, error }

class DuesState {
  final DuesStatus status;
  final bool hasMember;
  final List<DuesPayment> payments;
  final DuesSummary? summary;
  final double defaultAmount;
  final String? errorMessage;
}
```

### 2.2 Event

```dart
class LoadMyDues extends DuesEvent {}
class RefreshMyDues extends DuesEvent {}  // pull-to-refresh
```

### 2.3 Bloc Logic

- `LoadMyDues` → panggil `repository.getMyDues()`
- Jika `hasMember == false`, state tetap `success` dengan empty payments & null summary
- Sort `payments` descending by period
- `RefreshMyDues` → re-fetch (pull-to-refresh)

---

## Phase 3: Bloc — Bendahara (Dues Management)

Hanya accessible oleh role: `bendahara`. Super admin & admin pusat bisa view tapi tidak bisa checklist.

### 3.1 State

```dart
class DuesAdminState {
  final DuesStatus status;
  final List<DuesPayment> payments;
  final DuesAdminSummary? summary;
  final Map<String, String> filters;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final bool canChecklist;         // true hanya untuk bendahara
  final String? errorMessage;
}
```

### 3.2 Event

```dart
class LoadAdminDues extends DuesAdminEvent {}
class LoadMoreAdminDues extends DuesAdminEvent {}
class UpdateFilter extends DuesAdminEvent { final Map<String, String> filters; }
class UpdateDuesPayment extends DuesAdminEvent { final int id; final Map body; }
class MassUpdateDues extends DuesAdminEvent { final List<DuesMassUpdateItem> items; }
```

### 3.3 Bloc Logic

- Unit scope otomatis di-handle backend (bendahara hanya lihat unit sendiri)
- Filter dikirim sebagai query params ke API
- Pagination: `LoadMoreAdminDues` → append ke existing list
- `UpdateDuesPayment` / `MassUpdateDues` → hanya jika `canChecklist == true` (bendahara)
- Setelah sukses → re-fetch list + summary
- Jika role `bendahara_pusat` → backend return 403, Flutter tangkap error & sembunyikan menu

---

## Phase 4: UI — Anggota: `MyDuesScreen`

### 4.1 Layout

```
┌──────────────────────────────┐
│  AppBar: "Iuran Saya"        │
├──────────────────────────────┤
│  ┌──────────────────────────┐│
│  │  Status Bulan Ini: PAID ││  ← DuesSummaryCard
│  │  2 bulan belum dibayar  ││
│  │  Rp 30.000/bulan         ││
│  └──────────────────────────┘│
├──────────────────────────────┤
│  ▼ Bulan                    │
│  ┌──────────────────────┐   │
│  │ Mei 2026  PAID 30K   │   │  ← DuesCard
│  │ Apr 2026  UNPAID 30K │   │
│  │ Mar 2026  UNPAID 30K │   │
│  └──────────────────────┘   │
└──────────────────────────────┘
```

### 4.2 States

| State | UI |
|-------|-----|
| Loading | Shimmer/Skeleton (12 placeholder cards) |
| No Member | Empty state: "Hubungkan profil anggota" + CTA ke profil |
| Error | Retry button + error message |
| Empty | "Belum ada data iuran" |
| Success | List 12 bulan |

### 4.3 Pull-to-Refresh

`RefreshIndicator` → dispatch `RefreshMyDues`.

---

## Phase 5: UI — Bendahara: `DuesAdminListScreen`

### 5.1 Layout

```
┌──────────────────────────────┐
│  AppBar: "Iuran Anggota"     │
├──────────────────────────────┤
│  Summary: 120 Lunas │ 45    │
│  Belum │ 3 Bebas            │
├──────────────────────────────┤
│  🔍 Cari │ 📅 Mei 2026      │
├──────────────────────────────┤
│  ☐ Nama Anggota   PAID      │
│     KTA-12345    30K         │
│  ☐ Nama Anggota   UNPAID    │
│     KTA-67890    30K         │  ← Swipe → Checklist Bayar
│                             │
│  [Pilih Semua] [Bayar Massal]│  ← FAB
└──────────────────────────────┘
```

### 5.2 Filter Bar

- **Period picker**: dropdown bulan (current ± 6 bulan)
- **Status tabs**: Semua / Paid / Unpaid / Waived
- **Search**: text field → dikirim sebagai `member_id` filter

### 5.3 Checklist Actions (Hanya `bendahara`)

- **Swipe kanan (unpaid → paid)**: Konfirmasi dialog → `PATCH /finance/dues/{id}`
- **Swipe kiri (paid → unpaid)**: Konfirmasi dialog → revert status
- **Waived**: tidak bisa di-swipe, hanya via tap → detail screen

### 5.4 Mass Payment

1. Checklist anggota via checkbox
2. FAB muncul: "Bayar X anggota"
3. Tap → `DuesMassPayDialog`: input amount, catatan opsional
4. Konfirmasi → dispatch `MassUpdateDues`
5. Success → snackbar "X iuran berhasil dicatat" + re-fetch

### 5.5 Infinite Scroll

- `LoadMoreAdminDues` saat scroll mencapai akhir
- Loading indicator di bottom list

---

## Phase 6: UI — Dashboard Widget

### 6.1 Widget Dues di Dashboard Anggota

Dashboard (`GET /dashboard`) sudah mengembalikan field `dues`:

```
┌──────────────────────────────┐
│  💰 Iuran Bulan Ini          │
│  Mei 2026                    │
│  Status: BELUM LUNAS         │
│  Rp 30.000                   │
│  [Bayar Sekarang]  ← CTA     │
└──────────────────────────────┘
```

- Jika `status == 'paid'`: badge hijau + centang
- Jika `status == 'unpaid'`: badge merah + CTA info
- Jika tidak ada `member`: sembunyikan widget

---

## Phase 7: Notifikasi & Reminder (opsional)

### 7.1 Backend

Backend belum punya scheduled notification untuk reminder iuran. Jika dibutuhkan:

- Tambah scheduled command: `dues:remind` — kirim push notification ke anggota `unpaid` setelah `due_day`
- Tambah notification category `dues` (sudah terdaftar di `NotificationService.php`)

### 7.2 Flutter

Di `GET /notifications` — filter by category `dues`.

---

## Testing

### Backend Tests

```bash
# Verifikasi otorisasi baru
php artisan test --filter=DuesAuthorizationTest

# Verifikasi mobile API
php artisan test --filter=MobileApiTest
php artisan test --filter=FinanceUnitScopeTest

# Verifikasi dues command
php artisan test --filter=DuesGenerateCommandTest
```

### Flutter Unit Tests

- `DuesPayment.fromJson()` / `toJson()`
- `DuesBloc` — state transitions
- `DuesAdminBloc` — filter, pagination, canChecklist flag

### Flutter Widget Tests

- `MyDuesScreen` — loading, empty, has-member, no-member, error
- `DuesCard` — paid/unpaid/waived display
- `DuesSummaryCard` — summary data

### Integration Tests

- Anggota: login → dashboard → tap iuran widget → `MyDuesScreen`
- Bendahara: login → daftar iuran → filter → checklist bayar → status berubah
- Bendahara pusat: login → menu iuran TIDAK MUNCUL (backend 403)
- Mass payment: checklist → bayar → summary berubah

---

## File yang Dimodifikasi (Backend — Laravel)

| # | File | Perubahan |
|---|------|-----------|
| 1 | `app/Http/Controllers/Api/Mobile/FinanceController.php` | `authorizeDuesAdmin()`: hapus `bendahara_pusat` |
| 2 | `app/Policies/DuesPaymentPolicy.php` | `create()`: hapus `bendahara_pusat`; `view()`: blokir `bendahara_pusat` |
| 3 | `app/Http/Controllers/Api/Mobile/ReportController.php` | `dues()`: hapus `bendahara_pusat` dari role check |
| 4 | `app/Http/Controllers/Finance/FinanceDuesController.php` | Tambah explicit check block `bendahara_pusat` |

## File yang Dibuat (Flutter)

| # | File | Deskripsi |
|---|------|-----------|
| 1 | `lib/features/dues/models/dues_payment.dart` | Model + JSON serialization |
| 2 | `lib/features/dues/models/dues_payment.g.dart` | Generated |
| 3 | `lib/features/dues/models/dues_summary.dart` | Summary model |
| 4 | `lib/features/dues/models/dues_summary.g.dart` | Generated |
| 5 | `lib/features/dues/models/dues_admin_summary.dart` | Admin summary model |
| 6 | `lib/features/dues/models/dues_mass_update_item.dart` | Mass update payload |
| 7 | `lib/features/dues/repository/dues_repository.dart` | Dio API calls |
| 8 | `lib/features/dues/bloc/dues_bloc.dart` | Anggota Bloc |
| 9 | `lib/features/dues/bloc/dues_event.dart` | Anggota events |
| 10 | `lib/features/dues/bloc/dues_state.dart` | Anggota states |
| 11 | `lib/features/dues/bloc/dues_admin_bloc.dart` | Bendahara Bloc |
| 12 | `lib/features/dues/bloc/dues_admin_event.dart` | Bendahara events |
| 13 | `lib/features/dues/bloc/dues_admin_state.dart` | Bendahara states |
| 14 | `lib/features/dues/screens/my_dues_screen.dart` | Anggota: riwayat iuran |
| 15 | `lib/features/dues/screens/dues_admin_list_screen.dart` | Bendahara: daftar iuran |
| 16 | `lib/features/dues/screens/dues_admin_detail_screen.dart` | Bendahara: detail/update |
| 17 | `lib/features/dues/widgets/dues_card.dart` | Card per bulan |
| 18 | `lib/features/dues/widgets/dues_summary_card.dart` | Ringkasan statistik |
| 19 | `lib/features/dues/widgets/dues_filter_bar.dart` | Filter bar |
| 20 | `lib/features/dues/widgets/dues_mass_pay_dialog.dart` | Dialog batch |
| 21 | `lib/features/dues/widgets/dues_status_badge.dart` | Badge status |
| 22 | `test/features/dues/models/dues_payment_test.dart` | Unit test model |
| 23 | `test/features/dues/bloc/dues_bloc_test.dart` | Unit test bloc |
| 24 | `test/features/dues/bloc/dues_admin_bloc_test.dart` | Unit test admin bloc |
| 25 | `test/features/dues/widgets/my_dues_screen_test.dart` | Widget test |

## File yang Dimodifikasi (Flutter)

| # | File | Perubahan |
|---|------|-----------|
| 1 | `lib/features/dashboard/...` | Tambah `DuesDashboardWidget` |
| 2 | `lib/app.dart` (atau router) | Register route `/dues` dan `/admin/dues` — guarded by role `bendahara` |
| 3 | `pubspec.yaml` | Pastikan `json_annotation`, `json_serializable`, `bloc`, `flutter_bloc`, `dio` |

---

## Dependency & Konfigurasi

| Config | Source | Digunakan di |
|--------|--------|-------------|
| `dues.default_amount` | `GET /meta/lookups` | Default amount di form bayar |
| `dues.due_day` | `GET /meta/lookups` | Informasi batas bayar |

---

## Execution Log

| Phase | Status | Started | Completed |
|-------|--------|---------|-----------|
| 0 — Backend Auth Cleanup | ⬜ Not started | — | — |
| 1 — Model & Repository | ⬜ Not started | — | — |
| 2 — Bloc Anggota | ⬜ Not started | — | — |
| 3 — Bloc Bendahara | ⬜ Not started | — | — |
| 4 — UI Anggota | ⬜ Not started | — | — |
| 5 — UI Bendahara | ⬜ Not started | — | — |
| 6 — Dashboard Widget | ⬜ Not started | — | — |
| 7 — Notifikasi (opsional) | ⬜ Not started | — | — |

---

## Verifikasi

- [ ] Backend: `authorizeDuesAdmin()` tidak lagi menerima `bendahara_pusat`
- [ ] Backend: `DuesPaymentPolicy::view()` memblokir `bendahara_pusat`
- [ ] Backend: `php artisan test --filter=DuesAuthorizationTest` — semua pass
- [ ] Backend: `php artisan test --filter=MobileApiTest` — semua pass
- [ ] Flutter: `flutter test` — unit & widget test pass
- [ ] Flutter: `flutter analyze` — zero issues
- [ ] Test bendahara: login → buka daftar iuran → checklist bayar → status berubah
- [ ] Test bendahara pusat: login → menu iuran TIDAK MUNCUL (403 dari backend)
- [ ] Test anggota: login → lihat dashboard → buka iuran → lihat 12 bulan
- [ ] Test anggota tanpa member: lihat empty state
- [ ] Test mass payment: checklist 5 anggota → bayar → summary berubah
- [ ] Test error handling: server mati → retry + error state
