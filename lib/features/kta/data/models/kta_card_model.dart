import '../../../../core/api/json_read.dart';

class KtaCardModel {
  const KtaCardModel({
    required this.name,
    required this.number,
    required this.status,
    required this.unit,
    required this.validUntil,
    required this.hasQr,
    required this.canDownloadPdf,
  });

  final String name;
  final String number;
  final String status;
  final String unit;
  final String validUntil;
  final bool hasQr;
  final bool canDownloadPdf;

  factory KtaCardModel.fromCache(Map<String, dynamic> json) {
    return KtaCardModel(
      name: readString(json, const ['name'], fallback: 'Anggota'),
      number: readString(json, const ['number']),
      status: readString(json, const ['status']),
      unit: readString(json, const ['unit']),
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

    return KtaCardModel(
      name: readString(data, const [
        'name',
        'member_name',
      ], fallback: readString(member, const ['name'], fallback: 'Anggota')),
      number: readString(data, const [
        'number',
        'kta_number',
        'nomor_anggota',
        'nomor_kta',
      ], fallback: '-'),
      status: readString(data, const ['status'], fallback: '-'),
      unit: readString(unit.isNotEmpty ? unit : data, const [
        'name',
        'unit_name',
      ], fallback: '-'),
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
      'valid_until': validUntil,
      'has_qr': hasQr,
      'can_download_pdf': canDownloadPdf,
    };
  }
}
