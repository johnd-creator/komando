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
| 1 | Iuran (riwayat + status) | ⬜ |
| 2 | Finance dashboard | ⬜ |
| 3 | Ledger list + filter | ⬜ |
| 4 | Unit access dropdown | ⬜ |

---

## Phase 4 — Role Admin

| # | Deliverable | Status |
|---|-------------|--------|
| 1 | Admin panel | ⬜ |
| 2 | Member management | ⬜ |
| 3 | Finance ledger CRUD | ⬜ |
| 4 | Approval workflows | ⬜ |
| 5 | Report exports | ⬜ |

---

## Catatan

- 2026-05-07: Fondasi Phase 1 mulai dibangun: dependency Flutter utama ditambahkan (`dio`, `flutter_bloc`, `equatable`, `flutter_secure_storage`, `go_router`, `json_annotation`, `build_runner`, `json_serializable`), struktur folder `core/`, `features/`, dan `shared/` dibuat, API client + auth interceptor + secure token storage tersedia, Auth Bloc login/logout/restore session tersedia, splash/login/main shell serta placeholder Home/KTA/Notifikasi/Profil dibuat.
- 2026-05-07: Integrasi awal Phase 1 selesai untuk layar inti: Home/Dashboard memakai `/dashboard`, Profil memakai `/profile`, KTA Digital memakai `/member/card` dan `/member/card/qr`, Notifikasi memakai `/notifications` dan mark-as-read. Semua layar punya loading/error/empty atau refresh state dasar.
- 2026-05-07: Path backend Laravel di `docs/mobile-v1.md` dicek. Path relatif `../var/www/html/anggota` tidak ada dari workspace Flutter, tetapi source tersedia di `/var/www/html/anggota`. Kontrak `AnnouncementController` dan `AnnouncementResource` dibaca dari backend, lalu Phase 2 Pengumuman list/detail diimplementasikan memakai `/announcements`, `/announcements/{id}`, dan dismiss dasar.
- Update status ke 🔄 saat mulai dikerjakan, dan ✅ saat selesai.
- Kerjakan berurutan per phase; dalam satu phase bisa paralel jika tidak ada dependency.
- Acuan utama: [grand_plan.md](./grand_plan.md).
