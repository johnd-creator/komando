# Mobile API v1
Development local path source : /var/www/html/anggota
Production base URL: `https://anggota.plnipservices.or.id/api/mobile/v1`

Base path: `/api/mobile/v1`

For Flutter development against production, set the API client base URL to:

```dart
const mobileApiBaseUrl = 'https://anggota.plnipservices.or.id/api/mobile/v1';
```

Flutter clients should send:

```http
Accept: application/json
Authorization: Bearer <access_token>
```

Store `access_token` in secure storage on the device. Do not use the legacy `X-API-Token` endpoints from the public Android app.

Example production request:

```bash
curl -X GET 'https://anggota.plnipservices.or.id/api/mobile/v1/me' \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer <access_token>'
```

Example Flutter/Dio setup:

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://anggota.plnipservices.or.id/api/mobile/v1',
  headers: {'Accept': 'application/json'},
));

dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final token = await secureStorage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  },
));
```

## Auth

### `POST /auth/login`

Production URL: `https://anggota.plnipservices.or.id/api/mobile/v1/auth/login`

Request:

```json
{
  "email": "anggota@example.com",
  "password": "password",
  "device_name": "android"
}
```

Response:

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

### `POST /auth/google/token`

Production URL: `https://anggota.plnipservices.or.id/api/mobile/v1/auth/google/token`

Request:

```json
{
  "id_token": "google-id-token",
  "device_name": "android",
  "server_auth_code": "optional-server-auth-code"
}
```

Rules:

- `id_token` wajib diverifikasi server-side terhadap signature Google, issuer, expiry, audience, dan `email_verified`.
- `device_name` wajib diisi dan dipakai sebagai nama personal access token Sanctum.
- `server_auth_code` opsional untuk kebutuhan lanjutan; belum diwajibkan untuk login bearer token v1.
- Hanya user existing yang sudah terdaftar lokal dan diizinkan mengakses mobile app yang bisa login.

Response sukses sama seperti `POST /auth/login`:

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

### `POST /auth/logout`

Revokes the current bearer token.

Production URL: `https://anggota.plnipservices.or.id/api/mobile/v1/auth/logout`

### `GET /me`

Returns the authenticated user, role, unit context, and linked member summary.

Production URL: `https://anggota.plnipservices.or.id/api/mobile/v1/me`

## Utility

### `GET /config`

Returns mobile API metadata, upload limits, and dues defaults.

### `GET /features`

Returns enabled server feature flags for announcements, letters, finance, and reports.

### `GET /meta/lookups`

Returns scoped lookup data for organization units, union positions, aspiration categories, letter categories, supported statuses, document types, and notification categories. Non-global users only receive their current unit.

### `GET /dashboard`

Returns the authenticated user's mobile dashboard summary: member profile summary, current dues status, unread notification count, latest scoped aspirations, latest visible letters, and pinned announcements.

## Member Features

### `GET /profile`

Returns the authenticated user's own member profile and latest update requests. Users without a linked member receive `member: null`.

### `PATCH /profile/update-request`

Allowed fields:

```json
{
  "address": "Alamat baru",
  "phone": "081234567890",
  "emergency_contact": "081298765432",
  "company_join_date": "2025-01-01",
  "notes": "Catatan opsional"
}
```

The API creates or replaces the user's pending update request.

### `POST /profile/photo`

Multipart form fields:

- `photo`: `jpg`, `jpeg`, `png`, or `webp`, max 5 MB.

### `DELETE /profile/photo`

Deletes the authenticated member's current profile photo if one exists.

### `POST /profile/documents`

Multipart form fields:

- `type`: `surat_pernyataan` or `ktp`
- `file`: `pdf`, max 2 MB.

### `GET /member/card`

Returns the authenticated member's card payload, including KTA, status, unit, QR token, verification URLs, `download_url`, `has_qr`, and `can_download_pdf`.

If `qr_token` or `valid_until` is empty, the API issues them automatically when the member has a KTA and the member unit can issue KTA.

Production URL: `https://anggota.plnipservices.or.id/api/mobile/v1/member/card`

### `GET /member/card/qr`

Returns the authenticated member card QR image as `image/png` or `image/svg+xml`.

Production URL: `https://anggota.plnipservices.or.id/api/mobile/v1/member/card/qr`

### `GET /member/card/pdf`

Downloads the authenticated member's KTA Digital as an A6 PDF. Flutter should call this endpoint with the same bearer token and save the binary response locally.

Production URL: `https://anggota.plnipservices.or.id/api/mobile/v1/member/card/pdf`

Flutter/Dio download example:

```dart
await dio.download(
  '/member/card/pdf',
  savePath,
  options: Options(responseType: ResponseType.bytes),
);
```

### `GET /member/card/verify/{token}`

Public JSON verification endpoint for QR scan. Returns only safe card verification fields: member name, unit, status, validity date, and scan timestamp.

Production URL: `https://anggota.plnipservices.or.id/api/mobile/v1/member/card/verify/{token}`

### `POST /member/data/export-request`

Records a mobile data export request for the authenticated user.

### `POST /member/data/delete-request`

Records a mobile data deletion request for the authenticated user.

### `GET /dues`

Returns the authenticated member's last 12 dues periods plus a summary.

## Settings

### `PATCH /settings/profile`

Request:

```json
{ "name": "Nama Baru" }
```

Updates the authenticated user's display name and linked member name.

### `PATCH /settings/password`

Request:

```json
{
  "current_password": "old-password",
  "password": "new-password",
  "password_confirmation": "new-password"
}
```

Updates the password and revokes other mobile bearer tokens.

### `GET /settings/sessions`

Returns the authenticated user's active mobile bearer tokens.

### `POST /settings/sessions/revoke-others`

Revokes all mobile bearer tokens except the current request token.

### `PATCH /settings/notifications`

Updates notification channel preferences and daily digest preference.

## Notifications

### `GET /notifications`

Returns paginated notifications for the authenticated user only.

Optional query:

- `per_page`: default `15`.

### `POST /notifications/{id}/read`

Marks one owned notification as read.

### `POST /notifications/read-all`

Marks all authenticated-user notifications as read.

### `POST /notifications/{id}/unread`

Marks one owned notification as unread.

### `POST /notifications/read-batch`

Request:

```json
{ "ids": ["uuid-1", "uuid-2"] }
```

Marks owned notifications from the request list as read.

### `GET /notifications/recent`

Returns the latest five authenticated-user notifications.

## Aspirations

### `GET /aspirations`

Returns aspirations scoped to the authenticated user's member-context unit.

Optional query:

- `category`
- `status`
- `sort`: `latest` or `popular`
- `per_page`: default `10`

### `POST /aspirations`

Request:

```json
{
  "category_id": 1,
  "title": "Lampu ruang rapat",
  "body": "Mohon lampu ruang rapat unit diganti karena redup.",
  "tags": ["fasilitas", "rapat"],
  "is_anonymous": false
}
```

### `GET /aspirations/{id}`

Returns one visible aspiration with category, tags, support status, ownership status, and creator visibility based on policy.

### `POST /aspirations/{id}/support`

Adds authenticated member support to one visible aspiration.

### `DELETE /aspirations/{id}/support`

Removes authenticated member support from one visible aspiration.

### `GET /aspiration-categories`

Returns available aspiration categories.

### `GET /aspiration-tags`

Returns available aspiration tag names.

## Announcements

### `GET /announcements`

Returns active announcements visible to the authenticated user and not dismissed by that user.

### `GET /announcements/{id}`

Returns one visible announcement.

### `POST /announcements/{id}/dismiss`

Dismisses one visible announcement for the authenticated user.

### `GET /announcements/attachments/{id}/download`

Downloads an attachment if the authenticated user can view the parent announcement.

## Feedback

### `POST /feedback`

Request:

```json
{
  "rating": 5,
  "message": "Catatan opsional"
}
```

Records mobile app feedback in the activity log.

## Letters

Mobile letters use the existing `LetterPolicy` and authenticated user scope.

- `GET /letters/inbox`
- `GET /letters/outbox`
- `GET /letters/approvals`
- `GET /letters/{id}`
- `GET /letters/{id}/preview`
- `GET /letters/{id}/pdf`
- `GET /letters/{id}/qr`
- `POST /letters`
- `PUT /letters/{id}`
- `DELETE /letters/{id}`
- `POST /letters/{id}/submit`
- `POST /letters/{id}/send`
- `POST /letters/{id}/archive`
- `POST /letters/{id}/approve`
- `POST /letters/{id}/revise`
- `POST /letters/{id}/reject`
- `POST /letters/{id}/attachments`
- `GET /letters/{id}/attachments/{attachment_id}/download`
- `GET /letters/categories`
- `GET /letters/approvers`
- `GET /members/search`
- `GET /letters/template-render`

## Admin Workflows

All endpoints are role/policy gated and non-global users are scoped to their active unit.

- `GET /admin/members`
- `POST /admin/members`
- `GET /admin/members/search`
- `POST /admin/members/export-request`
- `GET /admin/members/{id}`
- `PUT /admin/members/{id}`
- `GET /admin/onboarding`
- `POST /admin/onboarding/{id}/approve`
- `POST /admin/onboarding/{id}/reject`
- `GET /admin/updates`
- `POST /admin/updates/{id}/approve`
- `POST /admin/updates/{id}/reject`
- `GET /admin/mutations`
- `POST /admin/mutations`
- `GET /admin/mutations/{id}`
- `POST /admin/mutations/{id}/approve`
- `POST /admin/mutations/{id}/reject`
- `POST /admin/mutations/{id}/cancel`

## Finance And Reports

### Role-Based Access Control

**IMPORTANT:** Finance endpoints use hierarchical visibility rules based on user roles:

| Role | Can Access Units | Notes |
|------|------------------|-------|
| `bendahara` | Own unit + Pusat unit only | Full control for own unit, read-only for Pusat |
| `bendahara_pusat` | All units | Full control for Pusat, read-only for other units |
| `admin_pusat`, `pengurus_pusat` | All units | Read-only access |
| `admin_unit`, `pengurus` | Own unit only | Read-only access |
| `super_admin` | All units | Full access |

**Security Constraint:** `bendahara` role is **strictly limited** to own unit + pusat unit. Access to other units will return `403 Forbidden`.

### `GET /finance/dashboard`

Returns financial dashboard summary for the authenticated user, scoped to accessible units.

**Production URL:** `https://anggota.plnipservices.or.id/api/mobile/v1/finance/dashboard`

**Response:**

```json
{
  "summary": {
    "balance": 15000000.00,
    "income_this_month": 25000000.00,
    "expense_this_month": 10000000.00,
    "pending_count": 5
  },
  "recent_transactions": [
    {
      "id": 1,
      "date": "2026-05-07",
      "type": "income",
      "amount": 5000000.00,
      "description": "Iuran bulan Mei",
      "status": "approved",
      "category": { "id": 1, "name": "Iuran Anggota" },
      "organization_unit": { "id": 1, "name": "Unit Jakarta", "code": "JKT" }
    }
  ],
  "user_role": {
    "role": "bendahara",
    "unit_id": 1,
    "can_view_global": false
  }
}
```

**Field Descriptions:**
- `balance`: Current balance (income - expense) for scoped units
- `income_this_month`: Total approved income from current month start
- `expense_this_month`: Total approved expense from current month start
- `pending_count`: Number of transactions awaiting approval (admin roles only)
- `recent_transactions`: Last 5 transactions for accessible units
- `user_role`: Context information about current user's access level

### `GET /finance/units`

Returns list of organization units accessible to the authenticated user for finance operations.

**Production URL:** `https://anggota.plnipservices.or.id/api/mobile/v1/finance/units`

**Response for bendahara:**

```json
{
  "units": [
    { "id": 1, "name": "Unit Jakarta", "code": "JKT", "is_pusat": false },
    { "id": 99, "name": "DPP Pusat", "code": "DPP", "is_pusat": true }
  ],
  "accessible_count": 2,
  "role": "bendahara"
}
```

**Response for bendahara_pusat:**

```json
{
  "units": [
    { "id": 99, "name": "DPP Pusat", "code": "DPP", "is_pusat": true },
    { "id": 1, "name": "Unit Jakarta", "code": "JKT", "is_pusat": false },
    { "id": 2, "name": "Unit Surabaya", "code": "SBY", "is_pusat": false },
    { "id": 3, "name": "Unit Medan", "code": "MDN", "is_pusat": false }
  ],
  "accessible_count": 4,
  "role": "bendahara_pusat"
}
```

**Flutter Usage Example:**

```dart
// Fetch accessible units for filter dropdown
final response = await dio.get('/finance/units');
final data = response.data;

final units = (data['units'] as List)
    .map((unit) => Unit.fromJson(unit))
    .toList();

// Show in dropdown filter
// For bendahara: only shows 2 units (own + pusat)
// For bendahara_pusat: shows all units
```

### `GET /finance/categories`

Returns finance categories scoped to user's accessible units.

**Optional Query:**
- `type`: Filter by `income` or `expense`

**Response:**

```json
{
  "categories": [
    {
      "id": 1,
      "name": "Iuran Anggota",
      "type": "income",
      "organization_unit_id": null,
      "is_recurring": true,
      "default_amount": 50000.00
    }
  ]
}
```

### `GET /finance/ledgers`

Returns paginated finance ledgers scoped to user's accessible units.

**Optional Query:**
- `type`: Filter by `income` or `expense`
- `status`: Filter by `draft`, `submitted`, `approved`, or `rejected`
- `finance_category_id`: Filter by category ID
- `unit_id`: Filter by organization unit ID (must be accessible unit)
- `from`: Start date (YYYY-MM-DD)
- `to`: End date (YYYY-MM-DD)
- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 20, max: 100)

**Response:**

```json
{
  "data": [
    {
      "id": 1,
      "date": "2026-05-07",
      "type": "income",
      "amount": 5000000.00,
      "description": "Iuran bulan Mei",
      "status": "approved",
      "approved_at": "2026-05-07T10:30:00Z",
      "approved_by": { "id": 5, "name": "Admin Unit" },
      "category": { "id": 1, "name": "Iuran Anggota" },
      "organization_unit": { "id": 1, "name": "Unit Jakarta", "code": "JKT" },
      "created_by": { "id": 10, "name": "Bendahara Unit" },
      "attachment_path": null
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 45,
    "last_page": 3
  }
}
```

**Unit Filtering Example:**

```dart
// bendahara filtering by pusat unit
final response = await dio.get(
  '/finance/ledgers',
  queryParameters: {
    'unit_id': 99, // DPP Pusat
    'status': 'approved',
  },
);
// Returns 403 if unit_id is not in accessible units
```

### `POST /finance/ledgers`

Creates a new finance ledger entry.

**Request:**

```json
{
  "date": "2026-05-07",
  "finance_category_id": 1,
  "type": "income",
  "amount": 50000.00,
  "description": "Iuran dari anggota",
  "organization_unit_id": 1
}
```

**Rules:**
- `organization_unit_id` is required for global roles
- Non-global roles can only create for their own unit
- `bendahara` can create for own unit or pusat unit
- If `FINANCE_WORKFLOW_ENABLED` is true, status defaults to `submitted`, otherwise `approved`

### `PUT /finance/ledgers/{id}`

Updates an existing finance ledger.

**Request:** Same as create

**Rules:**
- Can only edit ledgers in `draft` or `submitted` status (when workflow enabled)
- `bendahara` can only edit own created ledgers
- Global roles can edit any ledger

### `DELETE /finance/ledgers/{id}`

Deletes a finance ledger.

**Rules:**
- Same edit restrictions apply
- Cannot delete approved/rejected ledgers (when workflow enabled)

### `POST /finance/ledgers/{id}/approve`

Approves a submitted ledger entry.

**Allowed Roles:** `admin_unit`, `admin_pusat`, `pengurus_pusat`, `super_admin`

### `POST /finance/ledgers/{id}/reject`

Rejects a submitted ledger entry.

**Allowed Roles:** `admin_unit`, `admin_pusat`, `pengurus_pusat`, `super_admin`

**Request:**

```json
{
  "reason": "Dokumen tidak lengkap"
}
```

### `POST /finance/ledgers/export`

Requests a finance ledger export (CSV format).

**Query:** Same as `GET /finance/ledgers`

**Response:**

```json
{
  "status": "queued",
  "export_id": "uuid-here",
  "filters": {
    "type": "income",
    "status": "approved",
    "unit_id": 1
  }
}
```

Flutter should poll `GET /reports/export/status/{id}` to check when export is ready.

### Dues Management

- `GET /finance/dues` - List dues payments (scoped)
- `PATCH /finance/dues/{id}` - Update single dues payment
- `PATCH /finance/dues/mass-update` - Bulk update dues payments
- `GET /finance/dues/dashboard` - Dues summary and statistics

`GET /finance/dues` mirrors the web admin dues page: it returns active members
in the scoped unit with the selected period's payment status joined in. Members
without a payment record are returned as `unpaid`.

**Optional query:**
- `period`: Month in `YYYY-MM` format. Defaults to current month.
- `status`: `paid`, `unpaid`, or `waived`.
- `member_id`: Filter a specific member.
- `unit_id`: Filter an accessible organization unit.
- `q`: Search by member name, KTA.
- `page`, `per_page`: Pagination.

**Response:**

```json
{
  "dues": [
    {
      "id": 10,
      "member_id": 1,
      "member_name": "Nama Anggota",
      "kta_number": "KTA-001",
      "organization_unit_id": 2,
      "period": "2026-05",
      "status": "paid",
      "amount": 50000.0,
      "paid_at": "2026-05-07T00:00:00.000000Z",
      "notes": null
    },
    {
      "id": null,
      "member_id": 2,
      "member_name": "Anggota Belum Bayar",
      "kta_number": "KTA-002",
      "organization_unit_id": 2,
      "period": "2026-05",
      "status": "unpaid",
      "amount": 0,
      "paid_at": null,
      "notes": null
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 9,
    "per_page": 15,
    "total": 135
  }
}
```

**Mass Update Request:**

```json
{
  "items": [
    {
      "member_id": 1,
      "period": "2026-05",
      "status": "paid",
      "amount": 50000.00,
      "paid_at": "2026-05-07",
      "notes": null
    }
  ]
}
```

### Reports

- `GET /reports/growth` - Member growth statistics
- `GET /reports/mutations` - Mutation request statistics
- `GET /reports/members` - Member demographics and statistics
- `GET /reports/aspirations` - Aspiration statistics
- `GET /reports/dues` - Dues payment statistics
- `GET /reports/finance` - Financial summary and trends
- `GET /reports/export` - Request generic report export
- `GET /reports/export/status/{id}` - Check export job status

All report endpoints are scoped to user's accessible units.

---

**Note:** `/reports/export` and finance export currently return queued JSON metadata for Flutter polling; binary export generation remains server-side worker work.

## Master Data And Admin Ops

- `GET /master/units`
- `GET /master/union-positions`
- `GET /master/aspiration-categories`
- `GET /master/letter-categories`
- `GET /master/letter-approvers`
- `GET /admin/roles`
- `POST /admin/roles/{id}/assign`
- `GET /admin/users`
- `GET /admin/users/{id}`
- `PATCH /admin/users/{id}`
- `GET /admin/sessions`
- `DELETE /admin/sessions/{id}`
- `GET /admin/audit-logs`
- `GET /admin/activity-logs`
- `GET /admin/ops`

## Platform

### `POST /devices`

Registers or updates the authenticated user's mobile device token for future push notifications.

```json
{
  "platform": "android",
  "device_token": "fcm-token",
  "device_name": "Pixel",
  "app_version": "1.0.0"
}
```

### `DELETE /devices/{id}`

Deletes one device token owned by the authenticated user.

### `POST /auth/google/token` and `POST /auth/microsoft/token`

`POST /auth/google/token` sudah aktif dengan verifikasi `id_token` server-side.

`POST /auth/microsoft/token` masih berupa stub `501` sampai verifier Microsoft server-side tersedia. Jangan menerima token provider native tanpa validasi signature dan audience.

## Error Codes

- `401`: missing, invalid, or revoked bearer token.
- `403`: authenticated but not authorized by current role/policy.
- `404`: owned resource or linked member profile not found.
- `501`: endpoint contract exists but provider verifier/worker is not configured yet, saat ini masih berlaku untuk Microsoft mobile token exchange.
- `422`: validation error, wrong credentials, no actual profile changes, or missing unit context.
- `429`: rate limit exceeded.

---

## Flutter Development Guide

### Project Setup

**Recommended Packages:**

```yaml
dependencies:
  dio: ^5.4.0          # HTTP client
  flutter_secure_storage: ^9.0.0  # Secure token storage
  json_annotation: ^4.8.0  # JSON serialization
  equatable: ^2.0.5     # Value equality
  bloc: ^8.1.0          # State management (recommended)
  flutter_bloc: ^8.1.0  # Bloc integration
  cached_network_image: ^3.3.0  # Image caching
  file_picker: ^6.1.0   # File upload
  permission_handler: ^11.0.0  # Device permissions
  qr_code_scanner: ^1.0.1  # QR code scanning
  pdf: ^3.10.0          # PDF rendering
  open_file: ^3.3.0     # Open PDF/files
  connectivity_plus: ^5.0.0  # Network connectivity

dev_dependencies:
  build_runner: ^2.4.0  # Code generation
  json_serializable: ^6.7.0  # JSON codegen
  flutter_lints: ^3.0.0
```

### Authentication Flow

**Login Sequence:**

```dart
// 1. User enters credentials
final loginData = {
  'email': email,
  'password': password,
  'device_name': 'flutter', // or Platform.isAndroid ? 'android' : 'ios'
};

// 2. Call login endpoint
try {
  final response = await dio.post('/auth/login', data: loginData);

  final accessToken = response.data['access_token'];
  final user = User.fromJson(response.data['user']);

  // 3. Store token securely
  await secureStorage.write(key: 'access_token', value: accessToken);

  // 4. Update Dio interceptor with token
  dio.options.headers['Authorization'] = 'Bearer $accessToken';

  // 5. Emit authenticated state
  authBloc.add(AuthLoggedIn(user: user));

} on DioException catch (e) {
  if (e.response?.statusCode == 422) {
    // Invalid credentials
    throw AuthException('Email atau password salah');
  }
  rethrow;
}
```

**Logout Sequence:**

```dart
Future<void> logout() async {
  try {
    // 1. Call logout endpoint (revokes token server-side)
    await dio.post('/auth/logout');

    // 2. Clear local storage
    await secureStorage.delete(key: 'access_token');

    // 3. Clear Dio headers
    dio.options.headers.remove('Authorization');

    // 4. Emit unauthenticated state
    authBloc.add(AuthLoggedOut());
  } catch (e) {
    // Logout locally even if server call fails
    await secureStorage.delete(key: 'access_token');
    authBloc.add(AuthLoggedOut());
  }
}
```

### Dio Interceptor Setup

**Recommended Interceptor Pattern:**

```dart
class ApiInterceptor extends Interceptor {
  final FlutterSecureStorage secureStorage;

  ApiInterceptor(this.secureStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add bearer token if available
    final token = await secureStorage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Add accept header
    options.headers['Accept'] = 'application/json';

    return handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - token expired or revoked
    if (err.response?.statusCode == 401) {
      // Clear invalid token
      await secureStorage.delete(key: 'access_token');

      // Navigate to login
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );

      return handler.resolve(Response(
        requestOptions: err.requestOptions,
        data: {'error': 'Session expired. Please login again.'},
      ));
    }

    // Handle 403 Forbidden - insufficient permissions
    if (err.response?.statusCode == 403) {
      return handler.resolve(Response(
        requestOptions: err.requestOptions,
        data: {'error': 'Anda tidak memiliki akses ke fitur ini'},
      ));
    }

    // Handle 422 Validation errors
    if (err.response?.statusCode == 422) {
      final errors = err.response?.data['errors'] ?? {};
      final message = err.response?.data['message'] ??
          'Data yang dikirim tidak valid';

      return handler.resolve(Response(
        requestOptions: err.requestOptions,
        data: {'error': message, 'validation_errors': errors},
      ));
    }

    return handler.next(err);
  }
}

// Setup in main.dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://anggota.plnipservices.or.id/api/mobile/v1',
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
));

dio.interceptors.add(ApiInterceptor(secureStorage));
```

### State Management with Bloc

**Auth Bloc Example:**

```dart
// auth_event.dart
abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  AuthLoginRequested({required this.email, required this.password});
}

class AuthLogoutRequested extends AuthEvent {}

// auth_state.dart
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;

  AuthAuthenticated(this.user);
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}

// auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  AuthBloc(this.dio, this.secureStorage) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await dio.post('/auth/login', data: {
        'email': event.email,
        'password': event.password,
        'device_name': 'flutter',
      });

      final token = response.data['access_token'];
      await secureStorage.write(key: 'access_token', value: token);

      final user = User.fromJson(response.data['user']);
      emit(AuthAuthenticated(user));
    } on DioException catch (e) {
      final message = e.response?.data['message'] ??
          'Terjadi kesalahan saat login';
      emit(AuthError(message));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await dio.post('/auth/logout');
    } catch (_) {}

    await secureStorage.delete(key: 'access_token');
    emit(AuthUnauthenticated());
  }
}
```

**Finance Bloc Example (with Role-Based Scoping):**

```dart
// finance_event.dart
abstract class FinanceEvent {}

class FinanceDashboardRequested extends FinanceEvent {}
class FinanceLedgersRequested extends FinanceEvent {
  final Map<String, dynamic> filters;

  FinanceLedgersRequested({this.filters = const {}});
}
class FinanceUnitsRequested extends FinanceEvent {}

// finance_state.dart
abstract class FinanceState {}

class FinanceInitial extends FinanceState {}
class FinanceLoading extends FinanceState {}
class FinanceDashboardLoaded extends FinanceState {
  final FinanceDashboard dashboard;

  FinanceDashboardLoaded(this.dashboard);
}
class FinanceLedgersLoaded extends FinanceState {
  final List<FinanceLedger> ledgers;
  final Meta meta;

  FinanceLedgersLoaded(this.ledgers, this.meta);
}
class FinanceUnitsLoaded extends FinanceState {
  final List<FinanceUnit> units;
  final int accessibleCount;

  FinanceUnitsLoaded(this.units, this.accessibleCount);
}
class FinanceError extends FinanceState {
  final String message;

  FinanceError(this.message);
}

// finance_bloc.dart
class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final Dio dio;

  FinanceBloc(this.dio) : super(FinanceInitial()) {
    on<FinanceDashboardRequested>(_onDashboardRequested);
    on<FinanceLedgersRequested>(_onLedgersRequested);
    on<FinanceUnitsRequested>(_onUnitsRequested);
  }

  Future<void> _onDashboardRequested(
    FinanceDashboardRequested event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoading());

    try {
      final response = await dio.get('/finance/dashboard');

      final dashboard = FinanceDashboard.fromJson(response.data);

      // Check user role for UI decisions
      final userRole = UserRole.fromJson(response.data['user_role']);

      emit(FinanceDashboardLoaded(dashboard));
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        emit(FinanceError('Anda tidak memiliki akses ke data keuangan'));
      } else {
        emit(FinanceError('Gagal memuat dashboard keuangan'));
      }
    }
  }

  Future<void> _onLedgersRequested(
    FinanceLedgersRequested event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoading());

    try {
      final response = await dio.get(
        '/finance/ledgers',
        queryParameters: event.filters,
      );

      final ledgers = (response.data['data'] as List)
          .map((json) => FinanceLedger.fromJson(json))
          .toList();

      final meta = Meta.fromJson(response.data['meta']);

      emit(FinanceLedgersLoaded(ledgers, meta));
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        emit(FinanceError('Unit yang dipilih tidak dapat diakses'));
      } else {
        emit(FinanceError('Gagal memuat transaksi'));
      }
    }
  }

  Future<void> _onUnitsRequested(
    FinanceUnitsRequested event,
    Emitter<FinanceState> emit,
  ) async {
    try {
      final response = await dio.get('/finance/units');

      final units = (response.data['units'] as List)
          .map((json) => FinanceUnit.fromJson(json))
          .toList();

      final accessibleCount = response.data['accessible_count'] as int;

      emit(FinanceUnitsLoaded(units, accessibleCount));
    } catch (e) {
      // Units loading should not fail the entire screen
      emit(FinanceUnitsLoaded([], 0));
    }
  }
}
```

### JSON Serialization

**User Model Example:**

```dart
// user.dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String name;
  final String email;
  @JsonKey(name: 'current_unit_id')
  final int? currentUnitId;
  final Role? role;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.currentUnitId,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  bool get isBendahara => role?.name == 'bendahara';
  bool get isBendaharaPusat => role?.name == 'bendahara_pusat';
  bool get canViewGlobal => isBendaharaPusat || role?.name == 'super_admin';
}

@JsonSerializable()
class Role {
  final int id;
  final String name;
  final String label;

  Role({required this.id, required this.name, required this.label});

  factory Role.fromJson(Map<String, dynamic> json) =>
      _$RoleFromJson(json);

  Map<String, dynamic> toJson() => _$RoleToJson(this);
}

// Run: flutter pub run build_runner build
```

**Finance Models Example:**

```dart
// finance_dashboard.dart
@JsonSerializable()
class FinanceDashboard {
  final DashboardSummary summary;
  final List<FinanceLedger> recentTransactions;
  @JsonKey(name: 'user_role')
  final UserRole userRole;

  FinanceDashboard({
    required this.summary,
    required this.recentTransactions,
    required this.userRole,
  });

  factory FinanceDashboard.fromJson(Map<String, dynamic> json) =>
      _$FinanceDashboardFromJson(json);

  Map<String, dynamic> toJson() => _$FinanceDashboardToJson(this);
}

@JsonSerializable()
class DashboardSummary {
  final double balance;
  @JsonKey(name: 'income_this_month')
  final double incomeThisMonth;
  @JsonKey(name: 'expense_this_month')
  final double expenseThisMonth;
  @JsonKey(name: 'pending_count')
  final int pendingCount;

  DashboardSummary({
    required this.balance,
    required this.incomeThisMonth,
    required this.expenseThisMonth,
    required this.pendingCount,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardSummaryToJson(this);
}

// finance_unit.dart
@JsonSerializable()
class FinanceUnit {
  final int id;
  final String name;
  final String code;
  @JsonKey(name: 'is_pusat')
  final bool isPusat;

  FinanceUnit({
    required this.id,
    required this.name,
    required this.code,
    required this.isPusat,
  });

  factory FinanceUnit.fromJson(Map<String, dynamic> json) =>
      _$FinanceUnitFromJson(json);

  Map<String, dynamic> toJson() => _$FinanceUnitToJson(this);

  String get displayName => isPusat ? '$name (Pusat)' : name;
}
```

### Common UI Patterns

**Loading States:**

```dart
Widget build(BuildContext context) {
  return BlocBuilder<FinanceBloc, FinanceState>(
    builder: (context, state) {
      if (state is FinanceLoading) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data keuangan...'),
            ],
          ),
        );
      }

      if (state is FinanceError) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(state.message),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<FinanceBloc>().add(
                  FinanceDashboardRequested(),
                ),
                child: Text('Coba Lagi'),
              ),
            ],
          ),
        );
      }

      if (state is FinanceDashboardLoaded) {
        return FinanceDashboardView(dashboard: state.dashboard);
      }

      return SizedBox.shrink();
    },
  );
}
```

**Role-Based UI:**

```dart
Widget buildFinanceActions(BuildContext context, User user) {
  if (user.isBendahara) {
    // Show only own unit + pusat unit filter
    return UnitFilterDropdown(
      units: [user.currentUnit!, pusatUnit],
      onChanged: (unit) {
        context.read<FinanceBloc>().add(
          FinanceLedgersRequested(filters: {'unit_id': unit.id}),
        );
      },
    );
  }

  if (user.isBendaharaPusat) {
    // Show all units filter
    return UnitFilterDropdown(
      units: allUnits,
      showAllOption: true,
      onChanged: (unit) {
        context.read<FinanceBloc>().add(
          FinanceLedgersRequested(filters: {'unit_id': unit?.id}),
        );
      },
    );
  }

  // Read-only view for other roles
  return SizedBox.shrink();
}
```

**Unit Filter Dropdown:**

```dart
class UnitFilterDropdown extends StatelessWidget {
  final List<FinanceUnit> units;
  final FinanceUnit? selectedUnit;
  final bool showAllOption;
  final ValueChanged<FinanceUnit?> onChanged;

  const UnitFilterDropdown({
    super.key,
    required this.units,
    this.selectedUnit,
    this.showAllOption = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<FinanceUnit>(
      value: selectedUnit,
      decoration: InputDecoration(
        labelText: 'Unit',
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(),
      ),
      items: [
        if (showAllOption)
          DropdownMenuItem(
            value: null,
            child: Text('Semua Unit'),
          ),
        ...units.map((unit) {
          return DropdownMenuItem(
            value: unit,
            child: Row(
              children: [
                Text(unit.displayName),
                if (unit.isPusat) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Pusat',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }
}
```

### File Upload Pattern

**Photo Upload Example:**

```dart
Future<void> uploadProfilePhoto(File photoFile) async {
  try {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        photoFile.path,
        filename: photoFile.path.split('/').last,
      ),
    });

    final response = await dio.post(
      '/profile/photo',
      data: formData,
    );

    // Success
    final updatedMember = Member.fromJson(response.data);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Foto berhasil diupload')),
    );
  } on DioException catch (e) {
    if (e.response?.statusCode == 422) {
      final errors = e.response?.data['errors'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errors['photo']?.first ?? 'File tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengupload foto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### QR Code Handling

**Generate Member QR:**

```dart
Future<void> generateMemberQR() async {
  try {
    final response = await dio.get(
      '/member/card/qr',
      options: Options(responseType: ResponseType.bytes),
    );

    // Display QR code image
    final image = Image.memory(
      response.data,
      width: 300,
      height: 300,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('KTA Digital'),
        content: image,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal memuat QR code')),
    );
  }
}
```

**Scan QR Code:**

```dart
Future<void> scanQRCode() async {
  try {
    final result = await BarcodeScanner.scan();

    // Verify with API
    final response = await dio.get('/member/card/verify/${result.rawContent}');

    final verifiedData = CardVerificationData.fromJson(response.data);

    // Show verification result
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verifikasi KTA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${verifiedData.memberName}'),
            Text('Unit: ${verifiedData.unitName}'),
            Text('Status: ${verifiedData.status}'),
            if (verifiedData.isValid)
              Text(
                'Valid',
                style: TextStyle(color: Colors.green),
              )
            else
              Text(
                'Tidak Valid',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal memindai QR code')),
    );
  }
}
```

### Error Handling Best Practices

**Centralized Error Handler:**

```dart
class ApiErrorHandler {
  static String getMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa koneksi internet Anda.';

      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 401:
            return 'Sesi telah berakhir. Silakan login kembali.';
          case 403:
            return 'Anda tidak memiliki akses ke fitur ini.';
          case 404:
            return 'Data tidak ditemukan.';
          case 422:
            return error.response?.data['message'] ?? 'Data tidak valid.';
          case 429:
            return 'Terlalu banyak permintaan. Coba lagi nanti.';
          case 500:
            return 'Terjadi kesalahan server. Coba lagi nanti.';
          default:
            return 'Terjadi kesalahan tidak terduga.';
        }

      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';

      case DioExceptionType.unknown:
        return 'Terjadi kesalahan tidak dikenal.';

      default:
        return 'Terjadi kesalahan.';
    }
  }

  static void showError(BuildContext context, DioException error) {
    final message = getMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
```

### Testing Strategy

**Mock Dio for Testing:**

```dart
// test/helpers/mock_dio.dart
class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late FinanceBloc financeBloc;

  setUp(() {
    mockDio = MockDio();
    financeBloc = FinanceBloc(mockDio);
  });

  test('emits FinanceDashboardLoaded when dashboard is fetched successfully', () async {
    // Arrange
    final dashboardData = {
      'summary': {
        'balance': 15000000.0,
        'income_this_month': 25000000.0,
        'expense_this_month': 10000000.0,
        'pending_count': 5,
      },
      'recent_transactions': [],
      'user_role': {
        'role': 'bendahara',
        'unit_id': 1,
        'can_view_global': false,
      },
    };

    when(() => mockDio.get('/finance/dashboard'))
        .thenAnswer((_) async => Response(data: dashboardData, statusCode: 200));

    // Act
    financeBloc.add(FinanceDashboardRequested());

    // Assert
    await expectLater(
      financeBloc.stream,
      emitsInOrder([
        FinanceLoading(),
        isA<FinanceDashboardLoaded>(),
      ]),
    );
  });
}
```

---

## Quick Reference for Flutter 1Komando

### Essential Endpoints for MVP

| Feature | Endpoint | Purpose |
|---------|----------|---------|
| **Auth** | `POST /auth/login` | User login |
| | `POST /auth/logout` | User logout |
| | `GET /me` | Get current user info |
| **Profile** | `GET /profile` | Get member profile |
| | `GET /member/card` | Get KTA card data |
| | `GET /member/card/qr` | Get QR code image |
| **Finance** | `GET /finance/dashboard` | Finance summary |
| | `GET /finance/ledgers` | List transactions |
| | `GET /finance/units` | Get accessible units |
| **Dues** | `GET /dues` | Get member dues |
| **Notifications** | `GET /notifications` | List notifications |
| **Letters** | `GET /letters/inbox` | Inbox letters |

### Common Response Wrapper

Most list endpoints return:

```json
{
  "data": [...],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 100,
    "last_page": 5
  }
}
```

### Status Codes Quick Reference

| Code | Meaning | Flutter Action |
|------|---------|----------------|
| 200 | Success | Update UI with data |
| 201 | Created | Navigate to detail/confirmation |
| 401 | Unauthorized | Navigate to login |
| 403 | Forbidden | Show access denied message |
| 404 | Not Found | Show not found message |
| 422 | Validation Error | Show validation errors |
| 429 | Rate Limited | Show "try again later" |
| 500 | Server Error | Show error message + retry button |

---

**Flutter 1Komando Development Status:** ✅ Ready for development

All essential endpoints are available and tested. Follow the patterns above for consistent implementation across the app.
