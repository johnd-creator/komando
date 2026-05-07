# Grand Plan — 1Komando

Dokumen induk yang menyatukan arsitektur, API, wireframe UI/UX, dan roadmap fitur aplikasi **1Komando** — aplikasi mobile anggota Serikat Pekerja PLN IP Services berbasis Flutter.

---

## 1. Visi & Tujuan

**1Komando** adalah aplikasi mobile untuk anggota koperasi/serikat pekerja yang menyediakan akses cepat ke:

- Identitas keanggotaan digital (KTA Digital + QR)
- Informasi iuran dan keuangan
- Aspirasi, pengumuman, dan surat-menyurat
- Notifikasi real-time
- Panel admin berbasis peran (role-based)

Aplikasi dirancang **mobile-first**, ringan, dan tidak memerlukan onboarding mandiri — akun dibuat oleh admin/pengurus, anggota cukup login.

---

## 2. Arsitektur Sistem

### 2.1 Layer Architecture

```
┌──────────────────────────────────────────────┐
│              Presentation Layer               │
│   Screens  │  Widgets  │  Blocs (State Mgmt) │
├──────────────────────────────────────────────┤
│            Business Logic Layer               │
│   Repositories  │  Use Cases  │  Entities    │
├──────────────────────────────────────────────┤
│                Data Layer                     │
│   Dio Client  │  Secure Storage  │  Cache    │
└──────────────────────────────────────────────┘
```

### 2.2 Tech Stack

| Layer            | Teknologi                          |
| ---------------- | ---------------------------------- |
| Framework        | Flutter ^3.10.4 / Dart ^3.10.4    |
| State Management | flutter_bloc ^8.1.0 + Equatable   |
| HTTP Client      | Dio ^5.4.0 + Interceptors         |
| Secure Storage   | flutter_secure_storage ^9.0.0     |
| Code Generation  | json_serializable + build_runner  |
| Navigation       | GoRouter / Navigator 2.0          |

### 2.3 Struktur Folder

```
lib/
├── main.dart
├── core/                    # Cross-cutting: API, theme, utils
│   ├── api/
│   ├── constants/
│   ├── error/
│   ├── security/
│   └── theme/
├── features/                # Feature-first organization
│   ├── auth/
│   │   ├── data/            # Models, Repo Impl, DataSources
│   │   ├── domain/          # Entities, Repo Interface, UseCases
│   │   └── presentation/    # Bloc, Screens, Widgets
│   ├── profile/
│   ├── finance/
│   ├── notifications/
│   ├── letters/
│   ├── aspirations/
│   ├── announcements/
│   └── admin/
└── l10n/                    # Internationalization
```

---

## 3. Role-Based Access Control (RBAC)

### 3.1 Hierarki Peran

```
super_admin              → Full access semua unit
  ├── admin_pusat        → Read-only semua unit
  ├── pengurus_pusat     → Read-only semua unit
  ├── bendahara_pusat    → Finance access semua unit
  ├── bendahara          → Finance: unit sendiri + pusat saja
  ├── admin_unit         → Read-only unit sendiri
  ├── pengurus           → Read-only unit sendiri
  └── anggota            → Basic member access
```

### 3.2 Aturan Kunci Finance

| Peran              | Akses Unit            | CRUD Ledger |
| ------------------ | --------------------- | ----------- |
| `bendahara`        | Unit sendiri + Pusat  | Unit sendiri + Pusat |
| `bendahara_pusat`  | Semua unit            | Semua unit  |
| `admin_pusat`      | Semua unit            | Read-only   |
| `admin_unit`       | Unit sendiri          | Read-only   |
| `super_admin`      | Semua unit            | Full        |

### 3.3 Visibilitas Menu per Peran

**Anggota biasa:**
Beranda · KTA Digital · Profil · Notifikasi · Iuran · Keuangan Pribadi · Aspirasi · Pengumuman · Surat · News/Berita · Feedback · Pengaturan

**Admin/Pengurus/Bendahara (tambahan):**
Admin Panel · Pengelolaan iuran · Data anggota · Approval workflow

---

## 4. Struktur Halaman & Wireframe

Total: **±14 halaman** utama.

### 4.1 Auth

| # | Halaman     | Endpoint         |
|---|-------------|------------------|
| 1 | Login       | `POST /auth/login` |

### 4.2 Main Pages (Bottom Nav)

| # | Halaman         | Endpoint              |
|---|-----------------|-----------------------|
| 2 | Home/Dashboard  | `GET /dashboard`, `GET /me` |
| 3 | KTA Digital     | `GET /member/card`, `GET /member/card/qr` |
| 4 | Notifikasi      | `GET /notifications`  |
| 5 | Profil Anggota  | `GET /profile`        |

### 4.3 Fitur Anggota

| #  | Halaman              | Endpoint                          |
|----|----------------------|-----------------------------------|
| 6  | Aspirasi (List/Create/Detail) | `GET/POST /aspirations` |
| 7  | Pengumuman (List/Detail)      | `GET /announcements`    |
| 8  | Surat (Inbox/Outbox/Create/Detail) | `GET /letters/*`  |

### 4.4 Finance

| #  | Halaman    | Endpoint                  |
|----|------------|---------------------------|
| 9  | Iuran      | `GET /dues`               |
| 10 | Keuangan   | `GET /finance/dashboard`, `GET /finance/ledgers` |
| 11 | News/Berita | `GET https://sppips.org/wp-json/wp/v2/posts` |

### 4.5 Admin & Settings

| #  | Halaman           | Endpoint              |
|----|-------------------|-----------------------|
| 12 | Admin Panel       | `GET /admin/*`        |
| 13 | Pengaturan Akun   | `PATCH /settings/*`   |
| 14 | Feedback          | `POST /feedback`      |

### 4.6 Wireframe Home Screen

```text
┌────────────────────────────────┐
│ Header Biru                    │
│ Selamat pagi, Nama Anggota  🔔 │
│ ┌────────────────────────────┐ │
│ │ Status KTA · Aktif      >  │ │
│ └────────────────────────────┘ │
├────────────────────────────────┤
│ Grid Fitur (4×2)               │
│ [KTA] [Iuran] [Aspirasi] [Surat]│
│ [Peng.] [Keu.] [News]    [Lain]│
├────────────────────────────────┤
│ Pengumuman terbaru             │
│ • Rapat Anggota Tahunan ...    │
│ • Pembayaran iuran ...         │
├────────────────────────────────┤
│ Bottom Nav: Beranda | KTA | Notifikasi | Profil
└────────────────────────────────┘
```

---

## 5. API Integration Strategy

### 5.1 Base Configuration

```
Base URL  : https://anggota.plnipservices.or.id/api/mobile/v1
Auth      : Bearer <access_token>
Accept    : application/json
```

### 5.2 Dio Interceptor Pipeline

```
Request → AuthInterceptor (attach token)
       → LoggingInterceptor (debug)
       → Send

Response ← ErrorInterceptor (401→logout, 403→denied, 422→validation)
         ← LoggingInterceptor
         ← Receive
```

### 5.3 Essential Endpoints (MVP)

| Kategori        | Endpoint                        | Fungsi                      |
| --------------- | ------------------------------- | --------------------------- |
| Auth            | `POST /auth/login`              | Login anggota               |
| Auth            | `POST /auth/logout`             | Logout + revoke token       |
| Auth            | `GET /me`                       | Data user + role            |
| Dashboard       | `GET /dashboard`                | Ringkasan dashboard         |
| KTA             | `GET /member/card`              | Data kartu anggota          |
| KTA             | `GET /member/card/qr`           | QR code PNG/SVG             |
| Profil          | `GET /profile`                  | Profil anggota              |
| Notifikasi      | `GET /notifications`            | List notifikasi (paginated) |
| Iuran           | `GET /dues`                     | Riwayat iuran 12 bulan      |
| Keuangan        | `GET /finance/dashboard`        | Ringkasan keuangan          |
| Keuangan        | `GET /finance/ledgers`          | Transaksi (filterable)      |
| Keuangan        | `GET /finance/units`            | Unit yang dapat diakses     |
| Pengumuman      | `GET /announcements`            | List pengumuman             |
| Aspirasi        | `GET /aspirations`              | List aspirasi               |
| Aspirasi        | `POST /aspirations`             | Buat aspirasi baru          |
| Surat           | `GET /letters/inbox`            | Kotak masuk surat           |
| News (Public)   | `GET https://sppips.org/wp-json/wp/v2/posts` | Berita publik |

### 5.4 Error Code Mapping

| HTTP | Arti              | Aksi Flutter                  |
|------|-------------------|-------------------------------|
| 200  | Sukses            | Tampilkan data                |
| 401  | Token invalid     | Hapus token → navigasi login  |
| 403  | Forbidden         | Tampilkan pesan akses ditolak |
| 404  | Not Found         | Tampilkan empty state         |
| 422  | Validation Error  | Tampilkan error validasi      |
| 429  | Rate Limited      | Tampilkan "coba lagi nanti"   |
| 500  | Server Error      | Tampilkan retry button        |

---

## 6. UI/UX Principles

### 6.1 Prinsip Desain

- **Mobile-first** — semua halaman dioptimasi untuk layar kecil
- **Sederhana** — bottom nav 4 tab, grid fitur 4×2
- **Cepat** — splash screen 2–3 detik, skeleton loading, cache ringan
- **Role-aware** — menu admin hanya muncul untuk role yang berwenang
- **Offline-resilient** — cache profil, status KTA, dashboard ringkas

### 6.2 State Handling

| State   | Implementasi                            |
|---------|-----------------------------------------|
| Loading | Skeleton card / shimmer placeholder     |
| Empty   | Ilustrasi + pesan + CTA button          |
| Error   | Ikon error + pesan + "Coba Lagi"        |
| Success | Data normal                             |

### 6.3 Reusable Components

```
AppHeader          → Header biru dengan sapaan
StatusKtaCard      → Card status KTA (Aktif/Nonaktif)
FeatureGridItem    → Icon + label di grid 4×2
AnnouncementItem   → Item pengumuman (judul + tanggal)
BottomNavShell     → Shell 4 tab (Beranda, KTA, Notifikasi, Profil)
SectionTitle       → Judul section dengan optional "Lihat Semua"
SkeletonCard       → Placeholder loading
EmptyState         → Ilustrasi + teks + tombol aksi
ErrorState         → Ilustrasi error + retry
PrimaryButton      → Tombol utama aplikasi
```

### 6.4 Splash Screen Flow

```text
Buka aplikasi
   ↓
Splash Screen (2–3 detik)
   ↓
Cek token di secure storage
   ↓
Token ada? ──Ya──→ Home/Dashboard
   │
   Tidak
   ↓
Login Screen
```

---

## 7. Implementation Phases

### Phase 1 — Foundation (Core Flow)

| # | Deliverable                    | Endpoint                  |
|---|--------------------------------|---------------------------|
| 1 | Project setup + folder structure | —                      |
| 2 | Dio client + interceptor       | Base config               |
| 3 | Auth Bloc (Login/Logout)       | `/auth/login`, `/auth/logout` |
| 4 | Splash screen + auto-login     | `/me`                     |
| 5 | Secure token storage           | flutter_secure_storage    |
| 6 | Bottom navigation shell        | —                         |
| 7 | Home/Dashboard screen          | `/dashboard`, `/me`       |
| 8 | Profil anggota                 | `/profile`                |
| 9 | KTA Digital + QR               | `/member/card`, `/member/card/qr` |
| 10 | Notifikasi                     | `/notifications`          |

### Phase 2 — Fitur Anggota

| # | Deliverable                    | Endpoint                  |
|---|--------------------------------|---------------------------|
| 1 | Pengumuman (list + detail)     | `/announcements`          |
| 2 | Aspirasi (list + create + detail + support) | `/aspirations` |
| 3 | Surat (inbox + outbox + create + detail)    | `/letters/*`  |
| 4 | Feedback                       | `/feedback`               |
| 5 | News/Berita (WordPress public) | `wp/v2/posts`             |

### Phase 3 — Finance

| # | Deliverable                    | Endpoint                  |
|---|--------------------------------|---------------------------|
| 1 | Iuran (riwayat + status)       | `/dues`                   |
| 2 | Finance dashboard              | `/finance/dashboard`      |
| 3 | Ledger list + filter           | `/finance/ledgers`        |
| 4 | Unit access dropdown           | `/finance/units`          |
| 5 | News/Berita (WordPress public) | `wp/v2/posts`             |

### Phase 4 — Role Admin

| # | Deliverable                    | Endpoint                  |
|---|--------------------------------|---------------------------|
| 1 | Admin panel                    | `/admin/*`                |
| 2 | Member management              | `/admin/members`          |
| 3 | Finance ledger CRUD            | `/finance/ledgers`        |
| 4 | Approval workflows             | `/finance/ledgers/{id}/approve` |
| 5 | Report exports                 | `/reports/export`         |

---

## 8. Navigasi Aplikasi

```text
SplashScreen
    │
LoginScreen ──────────────────────┐
    │                              │
MainShell (BottomNav)              │
 ├─ HomeScreen                     │
 ├─ KtaDigitalScreen               │
 ├─ NotificationScreen             │
 └─ ProfileScreen                  │
    │                              │
Feature Screens (push dari grid)   │
 ├─ IuranScreen                    │
 ├─ KeuanganScreen                 │
 ├─ NewsScreen (Berita)            │
 ├─ AspirasiListScreen             │
 │   ├─ AspirasiCreateScreen       │
 │   └─ AspirasiDetailScreen       │
 ├─ PengumumanListScreen           │
 │   └─ PengumumanDetailScreen     │
 ├─ SuratInboxScreen               │
 ├─ SuratOutboxScreen              │
 ├─ SuratCreateScreen              │
 ├─ SuratDetailScreen              │
 ├─ AdminPanelScreen               │
 ├─ AccountSettingsScreen          │
 └─ FeedbackScreen                 │
```

---

## 9. Data Flow & State Management

### 9.1 Bloc Pattern (Unidirectional)

```
UI (Screen/Widget)
  │  dispatch Event
  ▼
Bloc
  │  validate + call Repository
  ▼
Repository
  │  call DataSource
  ▼
DataSource (Remote/Local)
  │  HTTP / DB
  ▼
Response → Model → Entity → emit State → UI rebuild
```

### 9.2 Bloc per Feature

| Bloc              | Event                   | State                          |
| ----------------- | ----------------------- | ------------------------------ |
| `AuthBloc`        | `AuthLoginRequested`    | `AuthAuthenticated`, `AuthError` |
| `DashboardBloc`   | `DashboardRequested`    | `DashboardLoaded`              |
| `ProfileBloc`     | `ProfileRequested`      | `ProfileLoaded`                |
| `KtaBloc`         | `KtaCardRequested`      | `KtaCardLoaded`                |
| `NotificationBloc`| `NotificationsFetched`  | `NotificationsLoaded`          |
| `FinanceBloc`     | `FinanceDashboardRequested` | `FinanceDashboardLoaded`   |
| `AspirationBloc`  | `AspirationsFetched`    | `AspirationsLoaded`            |
| `LetterBloc`      | `LettersFetched`        | `LettersLoaded`                |
| `NewsBloc`        | `NewsFetched`           | `NewsLoaded`                   |

---

## 10. Keamanan

| Area              | Implementasi                              |
| ----------------- | ----------------------------------------- |
| Token storage     | `flutter_secure_storage` (Keychain/Keystore) |
| Transport         | HTTPS only                               |
| Credential        | Tidak disimpan; hanya saat login          |
| Session           | Token di-revoke saat logout              |
| 401 handling      | Auto-redirect ke login                   |
| RBAC              | Role check di Bloc + UI visibility        |

---

## 11. Testing Strategy

| Level         | Fokus                                         |
| ------------- | --------------------------------------------- |
| Unit Test     | Bloc logic, use cases, model serialization    |
| Widget Test   | UI rendering, state changes, user interaction |
| Integration   | API mocking, auth flow, critical scenarios    |

**Target coverage**: >80% untuk fitur critical (auth, finance RBAC, file upload).

---

## 12. Dependency Map

```
Auth ───────────────► semua fitur (prerequisite)
  │
Profile ────────────► Dashboard, KTA, Iuran
  │
Dashboard ──────────► Home screen
  │
Finance RBAC ───────► Keuangan, Laporan, Admin Panel
  │
Notifications ──────► independen (parallel dengan Dashboard)
  │
Aspirations ────────► independen
  │
Announcements ──────► independen
  │
Letters ────────────► independen
```

---

## 13. Catatan Implementasi

1. **WordPress news** menggunakan Dio instance terpisah — tanpa auth header.
2. **bendahara** TIDAK BOLEH melihat unit selain unit sendiri + pusat. Cek strict di Bloc.
3. **Empty state** wajib ada di setiap list — jangan tampilkan blank screen.
4. **Splash screen** cukup 2–3 detik, tanpa loading screen tambahan.
5. **Grid fitur Home** menggunakan format 4×2 (8 item), item ke-8 adalah "Lainnya" untuk menu tambahan/role-based.
6. **Bottom nav** hanya 4 tab: Beranda, KTA, Notifikasi, Profil.
7. **Admin menu** disembunyikan total dari anggota biasa — cek `user.role.name`.
8. **Pull-to-refresh** untuk semua list; skeleton loading saat first load.
9. **Cache** profil, status KTA, dashboard ringkas, dan pengumuman terbaru.

---

## 14. Referensi

| Dokumen                                              | Isi                                     |
| ---------------------------------------------------- | --------------------------------------- |
| [ARCHITECTURE.md](./ARCHITECTURE.md)                 | Arsitektur teknis + pola desain         |
| [FEATURE_ROADMAP.md](./FEATURE_ROADMAP.md)           | Prioritas fitur + status implementasi   |
| [mobile-v1.md](./mobile-v1.md)                       | API reference + Flutter implementation  |
| [wireframe.md](./wireframe.md)                       | Wireframe UI/UX + struktur halaman      |
| [DEVELOPMENT_WORKFLOW.md](./DEVELOPMENT_WORKFLOW.md) | Workflow pengembangan + coding standard |
| [ENVIRONMENT_SETUP.md](./ENVIRONMENT_SETUP.md)       | Setup environment + prerequisites       |
