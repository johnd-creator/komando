# Plan: Fitur Iuran Anggota — Mobile (Flutter)

Date: 2026-05-10
Source: Analisis backend `finance/dues` & API `docs/api/mobile-v1.md`
Status: **Draft — menunggu approval**

---

## Executive Summary

Fitur **Iuran Anggota Mobile** adalah implementasi Flutter dari fitur iuran (dues) yang sudah tersedia di web panel SIM-SP. Semua API backend sudah siap — tidak ada pekerjaan backend baru untuk fundamental fitur ini. Flutter app mengonsumsi API yang sama seperti yang didokumentasikan di `docs/api/mobile-v1.md`.

Target fitur iuran mencakup dua persona:

| Persona | API Endpoint | Keterangan |
|---------|-------------|------------|
| **Anggota** (member biasa) | `GET /dues` | Melihat riwayat iuran 12 bulan terakhir + ringkasan |
| **Pengurus** (bendahara/admin) | `GET /finance/dues`, `PATCH /finance/dues/{id}`, `PATCH /finance/dues/mass-update`, `GET /finance/dues/dashboard`, `GET /reports/dues` | Kelola pembayaran iuran anggota + summary |

Dashboard utama mobile (`GET /dashboard`) juga mengembalikan data `dues` untuk status iuran bulan ini — perlu ditampilkan di widget dashboard.

---

## API Contracts (Backend — sudah siap)

Semua endpoint berikut sudah production-ready. Tidak ada perubahan backend dalam plan ini.

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

Query params: `period`, `status`, `member_id`, `unit_id`, `page`, `per_page`

Response: paginated list `DuesPaymentResource` + member & unit info.

### 4. `PATCH /finance/dues/{id}` — Admin: Update Satu Pembayaran

Request body:
```json
{ "status": "paid", "amount": 30000.0, "paid_at": "2026-05-07", "notes": null }
```

### 5. `PATCH /finance/dues/mass-update` — Admin: Batch Pembayaran

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

Query params: `unit_id`

Response:
```json
{
  "summary": {
    "total": 168,
    "paid": 120,
    "unpaid": 45,
    "amount": 5040000.0
  }
}
```

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
│       │   ├── dues_admin_list_screen.dart # Admin: daftar iuran anggota
│       │   └── dues_admin_detail_screen.dart # Admin: update/lihat detail
│       └── widgets/
│           ├── dues_card.dart              # Card per bulan (digunakan di berbagai screen)
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

  // Computed
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
  final List<String> unpaidPeriods;   // max 3
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

Method coverage:

| Method | API | Return |
|--------|-----|--------|
| `getMyDues()` | `GET /dues` | `{hasMember, payments, summary}` |
| `getDashboardDues()` | Sudah ada di `GET /dashboard` response | `DuesPayment?` |
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
  final bool hasMember;             // false jika user tidak punya member linked
  final List<DuesPayment> payments; // 12 bulan
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
- `RefreshMyDues` → re-fetch (digunakan oleh pull-to-refresh)

---

## Phase 3: Bloc — Admin (Dues Management)

Hanya accessible oleh role: `super_admin`, `admin_pusat`, `bendahara`, `bendahara_pusat`.

### 3.1 State

```dart
class DuesAdminState {
  final DuesStatus status;
  final List<DuesPayment> payments;
  final DuesAdminSummary? summary;
  final Map<String, String> filters; // period, status, unitId, memberId
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final String? errorMessage;
}
```

### 3.2 Event

```dart
class LoadAdminDues extends DuesAdminEvent {}
class LoadMoreAdminDues extends DuesAdminEvent {}   // pagination
class UpdateFilter extends DuesAdminEvent { final Map<String, String> filters; }
class UpdateDuesPayment extends DuesAdminEvent { final int id; final Map body; }
class MassUpdateDues extends DuesAdminEvent { final List<DuesMassUpdateItem> items; }
```

### 3.3 Bloc Logic

- Unit scope otomatis di-handle backend (bendahara hanya lihat unit sendiri + pusat)
- Filter dikirim sebagai query params ke API
- Pagination: `LoadMoreAdminDues` → append ke existing list, check `hasMore`
- `UpdateDuesPayment` / `MassUpdateDues` → setelah sukses, re-fetch list + summary

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
│  ▼ Bulan                    │  ← urut descending
│  ┌──────────────────────┐   │
│  │ Mei 2026  PAID 30K   │   │  ← DuesCard
│  │ Apr 2026  UNPAID 30K │   │
│  │ Mar 2026  UNPAID 30K │   │
│  │ ...                  │   │
│  └──────────────────────┘   │
└──────────────────────────────┘
```

### 4.2 States

| State | UI |
|-------|-----|
| Loading | Shimmer/Skeleton (12 placeholder cards) |
| No Member | Empty state: "Hubungkan profil anggota terlebih dahulu" dengan CTA ke profil |
| Error | Retry button + error message |
| Empty (member ada tapi belum join) | "Belum ada data iuran" |
| Success | List 12 bulan |

### 4.3 Empty States

- **`has_member == false`**: Ilustrasi + teks "Profil anggota belum terhubung" + tombol "Hubungkan" (navigasi ke profile screen)
- **`payments == []`**: Ilustrasi + teks "Belum ada data iuran untuk periode ini"
- **`join_date` > 12 bulan lalu**: Tampilkan hanya bulan sejak `join_date`, bulan sebelumnya jangan ditampilkan (backend sudah filter `joinDate`)

### 4.4 Pull-to-Refresh

`RefreshIndicator` → dispatch `RefreshMyDues`.

---

## Phase 5: UI — Admin: `DuesAdminListScreen`

### 5.1 Layout

```
┌──────────────────────────────┐
│  AppBar: "Iuran Anggota"     │
│  Tab: [Semua] [Lunas] [Belum]│
├──────────────────────────────┤
│  Summary: 120 Lunas | 45    │
│  Belum | 3 Bebas            │
├──────────────────────────────┤
│  🔍 Cari anggota...          │
│  📅 Mei 2026  🏢 Unit       │
├──────────────────────────────┤
│  ┌──────────────────────┐   │
│  │ Nama Anggota   PAID  │   │
│  │ KTA-12345    30K     │   │  ← List item
│  │ 3 Mei 2026           │   │
│  ├──────────────────────┤   │
│  │ Nama Anggota UNPAID  │   │
│  │ KTA-67890    30K     │   │
│  │ Swipe → Bayar        │   │
│  └──────────────────────┘   │
│                             │
│  [Pilih Semua] [Bayar Massal]│  ← FAB / bottom bar
└──────────────────────────────┘
```

### 5.2 Filter Bar

- **Period picker**: dropdown bulan (current ± 6 bulan)
- **Unit selector**: dari `GET /finance/units` (hanya unit yang diizinkan)
- **Status tabs**: Semua / Paid / Unpaid / Waived
- **Search**: text field → dikirim sebagai `member_id` filter (bisa juga search by name via parameter `search`)

### 5.3 Swipe Actions

- **Swipe kanan (unpaid → paid)**: Konfirmasi dialog → `PATCH /finance/dues/{id}`
- **Swipe kiri (paid → unpaid)**: Konfirmasi dialog → revert status
- **Waived**: tidak bisa di-swipe, hanya via tap → detail screen

### 5.4 Mass Payment

1. User tap "Pilih Semua" atau select checkbox individual
2. FAB/Bottom bar muncul: "Bayar X anggota"
3. Tap → `DuesMassPayDialog`: input amount default config, pilih kategori ledger, catatan opsional
4. Konfirmasi → dispatch `MassUpdateDues`
5. Success → snackbar "X iuran berhasil dicatat" + re-fetch

### 5.5 Infinite Scroll

- `LoadMoreAdminDues` saat scroll mencapai akhir
- Loading indicator di bottom list

---

## Phase 6: UI — Dashboard Widget

### 6.1 Widget Dues di Dashboard Anggota

Dashboard (`GET /dashboard`) sudah mengembalikan field `dues`. Widget iuran di dashboard:

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
- Jika `status == 'unpaid'`: badge merah + CTA (belum ada payment gateway, CTA info)
- Jika tidak ada `member`: sembunyikan widget

### 6.2 Widget Dues di Dashboard Admin

Dashboard finance (`GET /finance/dashboard`) belum mengembalikan data iuran — tapi dashboard admin bisa menggunakan `GET /reports/dues` untuk menampilkan quick stats di widget terpisah.

---

## Phase 7: Notifikasi & Reminder

### 7.1 Backend (opsional — phase terpisah)

Backend belum punya scheduled notification untuk reminder iuran. Jika dibutuhkan:

- Tambah scheduled command: `dues:remind` — kirim push notification ke anggota yang `unpaid` setelah `due_day`
- Tambah notification category `dues` (sudah ada di `NotificationService.php` line 68)
- Register di mobile device token system

### 7.2 Flutter: Notifikasi Screen

Di `GET /notifications` — filter by category `dues` atau tampilkan semua.

---

## Testing

### 7.1 Unit Tests (Flutter)

- `DuesPayment.fromJson()` / `toJson()` — parsing API response
- `DuesSummary.fromJson()`
- `DuesBloc` — state transitions untuk semua event
- `DuesAdminBloc` — filter updates, pagination, mass update

### 7.2 Widget Tests

- `MyDuesScreen` — loading, empty, has-member, no-member, error states
- `DuesCard` — paid/unpaid/waived display
- `DuesSummaryCard` — summary data rendering

### 7.3 Integration Tests (Flutter)

- Login → lihat dashboard → tap iuran widget → masuk `MyDuesScreen`
- Admin: filter → swipe bayar → lihat status berubah
- Mass payment: pilih → bayar → cek summary berubah

### 7.4 Backend Tests (Laravel — sudah ada)

Hanya untuk verifikasi, tidak ada penambahan:

```bash
php artisan test --filter=DuesPaymentTest
php artisan test --filter=DuesAuthorizationTest
php artisan test --filter=MobileApiTest
```

---

## File yang Dibuat (Flutter)

| # | File | Deskripsi |
|---|------|-----------|
| 1 | `lib/features/dues/models/dues_payment.dart` | Model + JSON serialization |
| 2 | `lib/features/dues/models/dues_payment.g.dart` | Generated (build_runner) |
| 3 | `lib/features/dues/models/dues_summary.dart` | Summary model |
| 4 | `lib/features/dues/models/dues_summary.g.dart` | Generated |
| 5 | `lib/features/dues/models/dues_admin_summary.dart` | Admin summary model |
| 6 | `lib/features/dues/models/dues_mass_update_item.dart` | Mass update payload model |
| 7 | `lib/features/dues/repository/dues_repository.dart` | Dio API calls |
| 8 | `lib/features/dues/bloc/dues_bloc.dart` | Anggota Bloc |
| 9 | `lib/features/dues/bloc/dues_event.dart` | Anggota events |
| 10 | `lib/features/dues/bloc/dues_state.dart` | Anggota states |
| 11 | `lib/features/dues/bloc/dues_admin_bloc.dart` | Admin Bloc |
| 12 | `lib/features/dues/bloc/dues_admin_event.dart` | Admin events |
| 13 | `lib/features/dues/bloc/dues_admin_state.dart` | Admin states |
| 14 | `lib/features/dues/screens/my_dues_screen.dart` | Anggota: riwayat iuran |
| 15 | `lib/features/dues/screens/dues_admin_list_screen.dart` | Admin: daftar iuran |
| 16 | `lib/features/dues/screens/dues_admin_detail_screen.dart` | Admin: detail/update |
| 17 | `lib/features/dues/widgets/dues_card.dart` | Card per bulan |
| 18 | `lib/features/dues/widgets/dues_summary_card.dart` | Ringkasan statistik |
| 19 | `lib/features/dues/widgets/dues_filter_bar.dart` | Filter bar |
| 20 | `lib/features/dues/widgets/dues_mass_pay_dialog.dart` | Dialog batch |
| 21 | `lib/features/dues/widgets/dues_status_badge.dart` | Badge status |
| 22 | `test/features/dues/models/dues_payment_test.dart` | Unit test model |
| 23 | `test/features/dues/bloc/dues_bloc_test.dart` | Unit test bloc |
| 24 | `test/features/dues/bloc/dues_admin_bloc_test.dart` | Unit test admin bloc |
| 25 | `test/features/dues/widgets/my_dues_screen_test.dart` | Widget test |

---

## File yang Dimodifikasi (Flutter — existing project)

| # | File | Perubahan |
|---|------|-----------|
| 1 | `lib/features/dashboard/...` | Tambah `DuesDashboardWidget` |
| 2 | `lib/app.dart` (atau router) | Register route `/dues` dan `/admin/dues` |
| 3 | `pubspec.yaml` | Pastikan `json_annotation`, `json_serializable`, `bloc`, `flutter_bloc`, `dio` sudah ada |

---

## Dependency & Konfigurasi

### Konfigurasi dari Backend

| Config | Source | Digunakan di |
|--------|--------|-------------|
| `dues.default_amount` | `GET /meta/lookups` | Default amount di form bayar |
| `dues.due_day` | `GET /meta/lookups` | Informasi batas bayar |
| Accessible units | `GET /finance/units` | Filter dropdown admin |

### Fitur Flag

- `config('features.finance')` — jika `false`, backend return 503. Flutter harus handle error ini dengan graceful degradation (sembunyikan menu iuran/finance jika `GET /features` return `finance: false`).

---

## Execution Log

| Phase | Status | Started | Completed |
|-------|--------|---------|-----------|
| 1 — Model & Repository | ⬜ Not started | — | — |
| 2 — Bloc Anggota | ⬜ Not started | — | — |
| 3 — Bloc Admin | ⬜ Not started | — | — |
| 4 — UI Anggota | ⬜ Not started | — | — |
| 5 — UI Admin | ⬜ Not started | — | — |
| 6 — Dashboard Widget | ⬜ Not started | — | — |
| 7 — Notifikasi (opsional) | ⬜ Not started | — | — |

---

## Verifikasi

- [ ] Flutter: `flutter test` — semua unit & widget test pass
- [ ] Flutter: `flutter analyze` — zero issues
- [ ] Flutter: build APK/iOS dan test di device
- [ ] Test anggota biasa: login → lihat dashboard → buka iuran → lihat 12 bulan
- [ ] Test anggota tanpa member linked: lihat empty state
- [ ] Test bendahara: login → buka daftar iuran → filter unit → swipe bayar
- [ ] Test bendahara: tidak bisa akses unit lain (backend enforced)
- [ ] Test mass payment: pilih 5 anggota → bayar → cek summary berubah
- [ ] Test error handling: matikan server → lihat error state + retry
