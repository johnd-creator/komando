class ExportRequest {
  const ExportRequest({
    required this.id,
    required this.type,
    required this.status,
    this.fileUrl,
  });

  final String id;
  final String type;
  final String status;
  final String? fileUrl;

  factory ExportRequest.fromJson(Map<String, dynamic> json) {
    final filters = json['filters'] as Map<String, dynamic>?;

    return ExportRequest(
      id: (json['export_id'] ?? json['id'] ?? '').toString(),
      type: json['type'] as String? ?? filters?['type'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      fileUrl: json['download_url'] as String? ?? json['file_url'] as String?,
    );
  }
}

class ReportsModel {
  const ReportsModel({
    required this.availableReports,
    required this.recentExports,
  });

  final List<String> availableReports;
  final List<ExportRequest> recentExports;
}
