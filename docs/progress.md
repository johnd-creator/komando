# Progress — 1Komando

Tracker implementasi per deliverable dari grand_plan.md. Status: `⬜` pending, `🔄` in progress, `✅` done.

---

## Phase 1 — Foundation (Core Flow)

| # | Deliverable | Status |
|---|-------------|--------|
| 1 | Project setup + folder structure | ✅ |
| 2 | Dio client + interceptor | ✅ |
| 3 | Auth Bloc (Login/Logout) | ✅ |
| 4 | Splash screen + auto-login | ✅ |
| 5 | Secure token storage | ✅ |
| 6 | Bottom navigation shell | ✅ |
| 7 | Home/Dashboard screen | ✅ |
| 8 | Profil anggota | ✅ |
| 9 | KTA Digital + QR | ✅ |
| 10 | Notifikasi | ✅ |

---

## Phase 2 — Fitur Anggota

| # | Deliverable | Status |
|---|-------------|--------|
| 1 | Pengumuman (list + detail) | ✅ |
| 2 | Aspirasi (list + create + detail + support) | ✅ |
| 3 | Surat (inbox + outbox + create + detail) | ✅ |
| 4 | Feedback | ✅ |
| 5 | News/Berita (WordPress public) | ✅ |

---

## Phase 3 — Finance

| # | Deliverable | Status |
|---|-------------|--------|
| 1 | Iuran (riwayat + status) | ✅ |
| 2 | Finance dashboard | ✅ |
| 3 | Ledger list + filter | ✅ |
| 4 | Unit access dropdown | ✅ |

---

## Phase 4 — Role Admin

| # | Deliverable | Status |
|---|-------------|--------|
| 1 | Admin panel | ✅ |
| 2 | Member management | 🔄 |
| 3 | Finance ledger CRUD | ✅ |
| 4 | Approval workflows | 🔄 |
| 5 | Report exports | 🔄 |

---

## Catatan

- 2026-05-07: Fondasi Phase 1 mulai dibangun: dependency Flutter utama ditambahkan (`dio`, `flutter_bloc`, `equatable`, `flutter_secure_storage`, `go_router`, `json_annotation`, `build_runner`, `json_serializable`), struktur folder `core/`, `features/`, dan `shared/` dibuat, API client + auth interceptor + secure token storage tersedia, Auth Bloc login/logout/restore session tersedia, splash/login/main shell serta placeholder Home/KTA/Notifikasi/Profil dibuat.
- 2026-05-07: Integrasi awal Phase 1 selesai untuk layar inti: Home/Dashboard memakai `/dashboard`, Profil memakai `/profile`, KTA Digital memakai `/member/card` dan `/member/card/qr`, Notifikasi memakai `/notifications` dan mark-as-read. Semua layar punya loading/error/empty atau refresh state dasar.
- 2026-05-07: Path backend Laravel di `docs/mobile-v1.md` dicek. Path relatif `../var/www/html/anggota` tidak ada dari workspace Flutter, tetapi source tersedia di `/var/www/html/anggota`. Kontrak `AnnouncementController` dan `AnnouncementResource` dibaca dari backend, lalu Phase 2 Pengumuman list/detail diimplementasikan memakai `/announcements`, `/announcements/{id}`, dan dismiss dasar.
- 2026-05-07 (fix): Bug critical: 7 dari 8 grid item di HomeScreen tidak punya `onTap` — hanya Pengumuman yang bisa diklik. Semua item sekarang punya navigasi (KTA, Iuran, Aspirasi, Surat, Keuangan, News, Feedback, Settings). News/Berita: `LaunchMode.externalApplication` diganti ke `platformDefault` + `canLaunchUrl` check. Android manifest: tambah `<queries>` untuk browser intent.
- 2026-05-07 (test): 37 unit/widget test dibuat: `test/core/api/json_read_test.dart` (parse helper), `test/features/news/data/models/news_model_test.dart` (WordPress model), `test/features/auth/presentation/bloc/auth_bloc_test.dart` (auth bloc login/logout/restore), `test/shared/presentation/widgets/shared_widgets_test.dart` (EmptyState + ErrorState widget), `test/widget_test.dart` (10 FeatureGridItem tests). `flutter analyze` zero issues, `flutter test` 37/37 pass.
- 2026-05-08 (audit/fix): Audit pekerjaan Phase 1-4 terhadap `grand_plan.md`, `mobile-v1.md`, dan backend Laravel lokal `/var/www/html/anggota`. Ditemukan beberapa mismatch kontrak API: finance ledger list memakai key `ledgers` bukan `data`, create/update ledger mengembalikan `ledger`; admin member list memakai key `members`, detail/update memakai `member`; report export adalah `GET /reports/export` dan `export_id` string; aspiration list/categories/tags memakai key `items`; letter list/categories memakai key `letters`/`items` dan create membutuhkan field wajib tambahan. Mismatch tersebut sudah diperbaiki. Admin dashboard tidak lagi fetch berulang di `build`, member detail tidak lagi dispatch fetch di `build`, finance edit route ditambahkan.
- 2026-05-08 (status correction): Status Phase 4 dikoreksi: Member management masih 🔄 karena UI baru list/detail dan parsing update backend, belum form editing lengkap; Approval workflows masih 🔄 karena approval onboarding/update/mutasi belum ada UI lengkap; Report exports masih 🔄 karena request export sudah memakai endpoint benar, tetapi status/download hasil export belum dibuat.
- 2026-05-08 (iuran/home fix): Bug iuran kosong diperbaiki dengan membaca response `/dues` dari key `payments` sesuai backend Laravel, bukan `data`, serta menghitung ringkasan dari item bila field summary lama tidak ada. Kartu KTA di Home diperbaiki agar menampilkan `profile.kta_number` dan `profile.unit_name`, tidak lagi mencampur `dues.status` sebagai status KTA.
- 2026-05-08 (keuangan home fix): Menu Keuangan di Beranda dibuat sadar-role sesuai policy backend `FinanceLedger::viewAny`; akun non-finance tidak lagi masuk ke halaman ledger yang menghasilkan "Data tidak ditemukan", tetapi diarahkan lewat snackbar ke Iuran Saya. Halaman Keuangan juga punya fallback state khusus untuk response 403/404 dan tombol "Transaksi Baru" hanya muncul untuk role yang memang boleh membuat ledger.
- 2026-05-08 (auth convenience): Halaman login ditambah tombol Masuk dengan Google yang membuka SSO web Laravel (`/auth/google`), opsi Simpan akun untuk menyimpan email di secure storage, dan login biometrik memakai token bearer tersimpan. Jika biometrik aktif, auto-restore session ditahan sampai user unlock dengan fingerprint/Face ID. Mobile Google token exchange belum dibuat native karena endpoint `/auth/google/token` backend masih mengembalikan 501 sampai verifier `id_token` server-side diaktifkan.
- 2026-05-08 (login redesign): Tampilan login diperbarui mengikuti referensi visual: latar biru muda dengan ilustrasi serikat/gedung/pylon, logo dan headline 1Komando di hero, kartu form putih dengan field Email/NIP dan Password, tombol Masuk dominan navy, divider, tombol Masuk dengan Google, serta chip Simpan akun/Biometrik. Asset lampiran belum tersedia sebagai file lokal di workspace, jadi visual hero dibuat dengan Flutter `CustomPainter` agar build tetap mandiri.
- 2026-05-08 (login polish): Ilustrasi `bg-login.png` diperkecil dan ditempatkan sebagai blok hero di atas form sehingga form mulai setelah area tangan/badan bawah gambar. Tombol Google tidak lagi membuka web login Laravel, tetapi memakai native `google_sign_in` dan mengirim `id_token` ke endpoint mobile `/auth/google/token`. Jika endpoint backend masih 501, aplikasi menampilkan pesan bahwa login Google mobile belum aktif di server.
- Update status ke 🔄 saat mulai dikerjakan, dan ✅ saat selesai.
- Kerjakan berurutan per phase; dalam satu phase bisa paralel jika tidak ada dependency.
- Acuan utama: [grand_plan.md](./grand_plan.md).
