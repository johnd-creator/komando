# Wireframe Aplikasi Anggota Koperasi

Dokumen ini merangkum hasil diskusi terkait struktur halaman, kebutuhan loading/splash screen, dan rancangan awal home screen aplikasi anggota koperasi berdasarkan API yang sudah dibaca.

## 1. Ringkasan Konsep

Aplikasi ini ditujukan sebagai aplikasi anggota koperasi dengan fokus utama pada akses cepat ke informasi keanggotaan, KTA digital, iuran/keuangan, aspirasi, pengumuman, surat, notifikasi, laporan, dan pengaturan akun.

Aplikasi tidak perlu memiliki banyak halaman onboarding untuk user anggota, karena alur registrasi atau pembuatan akun kemungkinan besar dilakukan oleh admin/pengurus. User anggota cukup login lalu langsung diarahkan ke halaman utama.

## 2. Struktur Halaman Utama

Total perkiraan halaman utama: **±14 halaman**.

### 2.1 Auth

#### 1. Login

**Kategori:** Auth  
**Tujuan:** User masuk ke aplikasi menggunakan akun yang sudah dibuat/admin onboarding.

Catatan:
- Register kemungkinan tidak diperlukan di sisi aplikasi anggota.
- Setelah login berhasil, user diarahkan ke Home/Dashboard.
- Login endpoint diperkirakan cepat, sehingga tidak membutuhkan loading screen khusus yang panjang.

---

### 2.2 Main Pages

#### 2. Home / Dashboard

**Kategori:** Main  
**Tujuan:** Menjadi halaman utama setelah login.

Isi utama:
- Header biru dengan sapaan.
- Nama anggota.
- Badge/status KTA.
- Shortcut fitur dalam bentuk grid icon.
- Pengumuman terbaru.
- Bottom navigation.

Endpoint terkait:
- `/dashboard`
- `/me`

#### 3. KTA Digital / Kartu Anggota

**Kategori:** Main  
**Tujuan:** Menampilkan identitas anggota dalam bentuk kartu digital.

Isi utama:
- Nama anggota.
- Nomor KTA.
- Status aktif/nonaktif.
- QR Code anggota.
- Informasi dasar keanggotaan.

#### 4. Profil Anggota

**Kategori:** Main  
**Tujuan:** Menampilkan dan mengelola data profil anggota.

Isi utama:
- Foto/avatar anggota.
- Nama lengkap.
- Nomor anggota.
- Data kontak.
- Unit/bagian.
- Status keanggotaan.
- Tombol edit profil jika API mendukung.

#### 5. Notifikasi

**Kategori:** Main  
**Tujuan:** Menampilkan daftar notifikasi untuk anggota.

Isi utama:
- List notifikasi.
- Status terbaca/belum terbaca.
- Detail notifikasi.
- Filter ringan jika dibutuhkan.

---

### 2.3 Fitur Anggota

#### 6. Aspirasi

**Kategori:** Fitur Anggota  
**Tujuan:** Anggota dapat melihat, membuat, dan memantau aspirasi.

Struktur halaman:
- List aspirasi.
- Buat aspirasi baru.
- Detail aspirasi.

Isi utama:
- Judul aspirasi.
- Kategori/topik.
- Status aspirasi.
- Tanggal dibuat.
- Deskripsi aspirasi.
- Respons/tindak lanjut dari pengurus jika ada.

#### 7. Pengumuman

**Kategori:** Fitur Anggota  
**Tujuan:** Menampilkan pengumuman resmi koperasi.

Struktur halaman:
- List pengumuman.
- Detail pengumuman.

Isi utama:
- Judul pengumuman.
- Tanggal publikasi.
- Ringkasan isi.
- Detail konten.

#### 8. Surat / Inbox & Outbox

**Kategori:** Fitur Anggota  
**Tujuan:** Mengelola surat masuk, surat keluar, dan pembuatan surat.

Struktur halaman:
- Inbox surat.
- Outbox surat.
- Buat surat.
- Detail surat.

Isi utama:
- Nomor surat jika ada.
- Judul/perihal.
- Status surat.
- Tanggal dibuat/dikirim.
- Isi surat.
- Lampiran jika API mendukung.

---

### 2.4 Finance

#### 9. Iuran

**Kategori:** Finance  
**Tujuan:** Menampilkan status dan riwayat iuran anggota.

Isi utama:
- Status iuran bulan berjalan.
- Nominal iuran.
- Riwayat pembayaran iuran.
- Status lunas/belum lunas.
- Tanggal pembayaran.

Catatan:
- Anggota biasa kemungkinan hanya dapat melihat riwayat iurannya sendiri.

#### 10. Keuangan / Ledger

**Kategori:** Finance  
**Tujuan:** Menampilkan ringkasan keuangan anggota.

Isi utama:
- Total simpanan.
- Riwayat transaksi anggota.
- Debit/kredit jika menggunakan ledger.
- Saldo atau nilai berjalan jika tersedia dari API.

#### 11. News/Berita

**Kategori:** Fitur Anggota  
**Tujuan:** Menampilkan berita dan artikel dari website PLN IP Services (https://sppips.org).

Isi utama:
- List berita terbaru.
- Detail berita dengan gambar.
- Kategori dan tag berita.
- Tanggal publikasi.
- Link ke berita lengkap di website.

Catatan:
- Mengambil data dari WordPress REST API publik (tanpa autentikasi).
- Mendukung pagination untuk load lebih banyak berita.
- Berita dapat dibuka di browser atau in-app webview.

---

### 2.5 Admin

#### 12. Admin Panel

**Kategori:** Admin  
**Tujuan:** Panel khusus untuk role admin/pengurus/bendahara.

Isi utama:
- Ringkasan data anggota.
- Ringkasan iuran.
- Akses pengelolaan data.
- Shortcut ke fungsi administratif.

Catatan:
- Halaman ini hanya muncul jika role user adalah admin, pengurus, atau bendahara.
- Untuk anggota biasa, menu ini disembunyikan.

---

### 2.6 Settings

#### 13. Pengaturan Akun

**Kategori:** Settings  
**Tujuan:** Mengelola preferensi dan keamanan akun.

Isi utama:
- Nama/user info.
- Ubah password.
- Sesi aktif.
- Pengaturan notifikasi.
- Logout.

#### 14. Feedback

**Kategori:** Settings  
**Tujuan:** User dapat memberikan masukan terhadap aplikasi atau layanan koperasi.

Isi utama:
- Form feedback.
- Kategori feedback.
- Pesan/komentar.
- Status feedback jika tersedia.

## 3. Wireframe Home Screen

Home screen menjadi halaman paling penting karena akan menjadi pusat akses user anggota.

### 3.1 Struktur Home Screen

```text
┌────────────────────────────────┐
│ Status bar                     │
├────────────────────────────────┤
│ Header Biru                    │
│ Selamat pagi,                  │
│ Nama Anggota              🔔   │
│                                │
│ ┌────────────────────────────┐ │
│ │ Status KTA                 │ │
│ │ Aktif · No. KTA 12345   >  │ │
│ └────────────────────────────┘ │
├────────────────────────────────┤
│ Akses fitur                    │
│                                │
│ [KTA] [Iuran] [Aspirasi] [Surat]│
│ [Peng.] [Keu.] [News]    [...] │
├────────────────────────────────┤
│ Pengumuman terbaru             │
│                                │
│ • Rapat Anggota Tahunan        │
│   dijadwalkan 15 Mei 2026      │
│                                │
│ • Pembayaran iuran bulan Mei   │
│   telah dibuka                 │
├────────────────────────────────┤
│ Bottom Navigation              │
│ Beranda | KTA | Notifikasi | Profil
└────────────────────────────────┘
```

### 3.2 Detail Komponen Home Screen

#### Header

Komponen:
- Background biru.
- Sapaan: `Selamat pagi,`.
- Nama anggota.
- Icon notifikasi.
- Card status KTA.

Fungsi:
- Memberikan konteks personal kepada user.
- Menampilkan status keanggotaan secara cepat.
- Card KTA dapat diarahkan ke halaman KTA Digital.

#### Grid Akses Fitur

Grid awal menggunakan format **4 x 2** agar compact dan mudah digunakan.

Menu yang direkomendasikan:
1. KTA Digital
2. Iuran
3. Aspirasi
4. Surat
5. Pengumuman
6. Keuangan
7. News/Berita
8. Lainnya

Catatan:
- Menu `Lainnya` dapat membuka halaman/menu tambahan seperti Feedback, Pengaturan, atau fitur role-based.
- Jika user adalah admin/pengurus, menu admin dapat ditampilkan di dalam `Lainnya` atau sebagai shortcut tersendiri.

#### Pengumuman Terbaru

Komponen:
- Judul section: `Pengumuman terbaru`.
- List 2–3 pengumuman terakhir.
- Setiap item berisi judul singkat dan tanggal.

Fungsi:
- Membuat informasi penting tetap terlihat tanpa harus membuka halaman pengumuman.
- Item dapat diarahkan ke detail pengumuman.

#### Bottom Navigation

Tab utama yang direkomendasikan:
1. Beranda
2. KTA
3. Notifikasi
4. Profil

Alasan:
- Hanya 4 tab agar tetap sederhana.
- Fitur lain cukup diakses melalui grid di Home.
- KTA dibuat tab utama karena merupakan identitas digital anggota.

## 4. Splash Screen dan Loading Screen

### 4.1 Rekomendasi Utama

Gunakan **Splash Screen Only**.

Aplikasi cukup memiliki splash screen singkat selama 2–3 detik saat aplikasi pertama dibuka, lalu langsung diarahkan ke Login atau Home sesuai status sesi user.

### 4.2 Alasan

Splash screen lebih cocok karena:
- Endpoint login diperkirakan cepat.
- Endpoint dashboard biasanya cepat dan dapat di-cache.
- Endpoint `/me` biasanya cepat dan ringan.
- User tidak perlu melihat loading screen panjang setiap berpindah halaman.
- UX terasa lebih praktis dan modern.

### 4.3 Alur Splash Screen

```text
Buka aplikasi
   ↓
Splash Screen 2–3 detik
   ↓
Cek token/session
   ↓
Jika belum login → Login
Jika sudah login → Home/Dashboard
```

### 4.4 Konten Splash Screen

Komponen:
- Logo aplikasi/koperasi.
- Nama aplikasi.
- Tagline singkat.
- Loading indicator kecil opsional.

Contoh teks:

```text
KOJAYAKU
Layanan Digital Anggota Koperasi
```

### 4.5 Loading di Dalam Aplikasi

Tidak perlu membuat halaman loading khusus untuk setiap fitur. Gunakan pendekatan ringan:

- Skeleton loading untuk list data.
- Shimmer placeholder untuk card dashboard.
- Pull-to-refresh untuk update data.
- Empty state jika data kosong.
- Error state jika API gagal.

Contoh:

```text
Home/Dashboard:
- Tampilkan layout utama lebih dulu.
- Card dan list menggunakan skeleton saat data belum selesai dimuat.

List Aspirasi/Pengumuman/Surat:
- Tampilkan skeleton list.
- Jika kosong, tampilkan empty state dengan tombol aksi.
```

## 5. Role-Based Navigation

Aplikasi perlu memperhatikan role user.

### 5.1 Anggota Biasa

Menu yang terlihat:
- Home
- KTA Digital
- Profil
- Notifikasi
- Iuran
- Keuangan pribadi
- Aspirasi
- Pengumuman
- Surat
- News/Berita
- Feedback
- Pengaturan akun

### 5.2 Pengurus / Bendahara / Admin

Menu tambahan:
- Admin Panel
- Pengelolaan iuran
- Data anggota
- Validasi/approval jika tersedia dari API

Catatan:
- Jangan tampilkan menu admin kepada anggota biasa.
- Gunakan response role dari API untuk mengatur visibilitas menu.

## 6. Rekomendasi UX

### 6.1 Prinsip Desain

- Gunakan desain mobile-first.
- Buat halaman Home compact dan mudah dipahami.
- Prioritaskan shortcut fitur yang paling sering digunakan anggota.
- Hindari terlalu banyak tab bawah.
- Gunakan card untuk informasi penting seperti status KTA dan iuran.
- Gunakan warna utama biru untuk header dan status utama.
- Gunakan icon grid agar fitur mudah dikenali.

### 6.2 Empty State

Setiap halaman list perlu empty state.

Contoh:

```text
Belum ada aspirasi
Silakan buat aspirasi pertama Anda.
[ Buat Aspirasi ]
```

### 6.3 Error State

Contoh:

```text
Data gagal dimuat
Periksa koneksi internet Anda, lalu coba lagi.
[ Coba Lagi ]
```

### 6.4 Offline / Cache Ringan

Untuk data penting seperti profil, status KTA, dan dashboard ringkas, sebaiknya gunakan cache agar aplikasi tetap terasa cepat.

Data yang cocok di-cache:
- Profil user.
- Status KTA.
- Ringkasan dashboard.
- Pengumuman terbaru.

## 7. Prioritas Implementasi

### Tahap 1 — Core Flow

1. Splash screen.
2. Login.
3. Home/Dashboard.
4. Profil anggota.
5. KTA Digital.
6. Notifikasi.

### Tahap 2 — Fitur Anggota

1. Pengumuman list/detail.
2. Aspirasi list/create/detail.
3. Surat inbox/outbox/create/detail.
4. Feedback.

### Tahap 3 — Finance

1. Iuran.
2. Keuangan/Ledger.
3. Laporan anggota.

### Tahap 4 — Role Admin

1. Admin Panel.
2. Laporan role-based.
3. Pengelolaan data jika API mendukung.

## 8. Catatan untuk Developer Flutter

### 8.1 Struktur Navigasi Sederhana

```text
SplashScreen
LoginScreen
MainShell
 ├─ HomeScreen
 ├─ KtaDigitalScreen
 ├─ NotificationScreen
 └─ ProfileScreen

Feature Screens
 ├─ IuranScreen
 ├─ KeuanganScreen
 ├─ NewsScreen
 ├─ AspirasiListScreen
 ├─ AspirasiCreateScreen
 ├─ AspirasiDetailScreen
 ├─ PengumumanListScreen
 ├─ PengumumanDetailScreen
 ├─ SuratInboxScreen
 ├─ SuratOutboxScreen
 ├─ SuratCreateScreen
 ├─ SuratDetailScreen
 ├─ AdminPanelScreen
 ├─ AccountSettingsScreen
 └─ FeedbackScreen
```

### 8.2 Komponen Reusable

Buat komponen reusable agar UI konsisten:

- `AppHeader`
- `StatusKtaCard`
- `FeatureGridItem`
- `AnnouncementListItem`
- `BottomNavShell`
- `SectionTitle`
- `SkeletonCard`
- `EmptyState`
- `ErrorState`
- `PrimaryButton`

## 9. Kesimpulan

Aplikasi sebaiknya dibuat sederhana, cepat, dan role-based. Untuk tahap awal, cukup gunakan splash screen singkat dan hindari loading page tambahan yang terlalu banyak. Home screen menjadi pusat navigasi dengan header personal, status KTA, grid fitur utama, pengumuman terbaru, dan bottom navigation 4 tab.

Struktur ±14 halaman sudah cukup lengkap untuk kebutuhan awal aplikasi anggota koperasi dan masih fleksibel untuk dikembangkan menjadi sistem yang lebih besar.
