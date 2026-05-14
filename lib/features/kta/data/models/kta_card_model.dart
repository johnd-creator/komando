import '../../../../core/api/json_read.dart';
import '../../../../core/constants/api_constants.dart';

class KtaCardModel {
  const KtaCardModel({
    required this.name,
    required this.number,
    required this.status,
    required this.unit,
    required this.jobTitle,
    required this.photoUrl,
    required this.validUntil,
    required this.hasQr,
    required this.canDownloadPdf,
  });

  final String name;
  final String number;
  final String status;
  final String unit;
  final String jobTitle;
  final String? photoUrl;
  final String validUntil;
  final bool hasQr;
  final bool canDownloadPdf;

  KtaCardModel copyWith({
    String? name,
    String? number,
    String? status,
    String? unit,
    String? jobTitle,
    String? photoUrl,
    String? validUntil,
    bool? hasQr,
    bool? canDownloadPdf,
  }) {
    return KtaCardModel(
      name: name ?? this.name,
      number: number ?? this.number,
      status: status ?? this.status,
      unit: unit ?? this.unit,
      jobTitle: jobTitle ?? this.jobTitle,
      photoUrl: photoUrl ?? this.photoUrl,
      validUntil: validUntil ?? this.validUntil,
      hasQr: hasQr ?? this.hasQr,
      canDownloadPdf: canDownloadPdf ?? this.canDownloadPdf,
    );
  }

  factory KtaCardModel.fromCache(Map<String, dynamic> json) {
    return KtaCardModel(
      name: readString(json, const ['name'], fallback: 'Anggota'),
      number: readString(json, const ['number']),
      status: readString(json, const ['status']),
      unit: readString(json, const ['unit']),
      jobTitle: readString(json, const ['job_title'], fallback: '-'),
      photoUrl: json['photo_url'] as String?,
      validUntil: readString(json, const ['valid_until']),
      hasQr: json['has_qr'] == true,
      canDownloadPdf: json['can_download_pdf'] == true,
    );
  }

  factory KtaCardModel.fromJson(Map<String, dynamic> json) {
    final data = readMap(json, 'data').isNotEmpty
        ? readMap(json, 'data')
        : json;
    final member = readMap(data, 'member');
    final unit = readMap(data, 'unit').isNotEmpty
        ? readMap(data, 'unit')
        : readMap(member, 'unit');
    final organizationUnit = readMap(member, 'organization_unit');
    final unionPosition = readMap(member, 'union_position');
    final rawPhotoUrl = readString(
      member,
      const ['photo_url', 'profile_photo_url', 'avatar_url'],
      fallback: readString(data, const [
        'photo_url',
        'profile_photo_url',
        'avatar_url',
      ], fallback: ''),
    );

    return KtaCardModel(
      name: readString(
        data,
        const ['name', 'member_name'],
        fallback: readString(member, const [
          'full_name',
          'name',
        ], fallback: 'Anggota'),
      ),
      number: readString(
        data,
        const ['kta_number', 'nomor_kta', 'member_number', 'nomor_anggota'],
        fallback: readString(member, const [
          'kta_number',
          'nomor_kta',
          'member_number',
          'nomor_anggota',
        ], fallback: readString(data, const ['number'], fallback: '-')),
      ),
      status: readString(
        data,
        const ['status', 'membership_status'],
        fallback: readString(member, const [
          'status',
          'membership_status',
        ], fallback: '-'),
      ),
      unit: readString(
        organizationUnit.isNotEmpty
            ? organizationUnit
            : unit.isNotEmpty
            ? unit
            : data,
        const ['name', 'unit_name'],
        fallback: '-',
      ),
      jobTitle: readString(
        member,
        const ['job_title', 'position', 'jabatan'],
        fallback: readString(
          unionPosition.isNotEmpty ? unionPosition : member,
          const ['name', 'union_position'],
          fallback: '-',
        ),
      ),
      photoUrl: rawPhotoUrl.isNotEmpty
          ? ApiConstants.getAbsolutePhotoUrl(rawPhotoUrl)
          : null,
      validUntil: readString(data, const ['valid_until'], fallback: '-'),
      hasQr: data['has_qr'] == true,
      canDownloadPdf: data['can_download_pdf'] == true,
    );
  }

  Map<String, dynamic> toCache() {
    return {
      'name': name,
      'number': number,
      'status': status,
      'unit': unit,
      'job_title': jobTitle,
      'photo_url': photoUrl,
      'valid_until': validUntil,
      'has_qr': hasQr,
      'can_download_pdf': canDownloadPdf,
    };
  }
}
