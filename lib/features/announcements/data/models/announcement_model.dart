import '../../../../core/api/json_read.dart';

class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.scopeType,
    required this.isPinned,
    required this.unitName,
    required this.creatorName,
    required this.createdAt,
    required this.attachments,
  });

  final int id;
  final String title;
  final String body;
  final String scopeType;
  final bool isPinned;
  final String unitName;
  final String creatorName;
  final String createdAt;
  final List<AnnouncementAttachmentModel> attachments;

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    final unit = readMap(json, 'organization_unit');
    final creator = readMap(json, 'creator');

    return AnnouncementModel(
      id: readInt(json, const ['id']),
      title: readString(json, const ['title']),
      body: readString(json, const ['body'], fallback: ''),
      scopeType: readString(json, const ['scope_type'], fallback: '-'),
      isPinned: json['is_pinned'] == true,
      unitName: readString(unit, const ['name'], fallback: 'Semua unit'),
      creatorName: readString(creator, const ['name'], fallback: '-'),
      createdAt: readString(json, const ['created_at'], fallback: ''),
      attachments: readList(
        json,
        'attachments',
      ).map(AnnouncementAttachmentModel.fromJson).toList(),
    );
  }
}

class AnnouncementAttachmentModel {
  const AnnouncementAttachmentModel({
    required this.id,
    required this.originalName,
    required this.mime,
    required this.size,
  });

  final int id;
  final String originalName;
  final String mime;
  final int size;

  factory AnnouncementAttachmentModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementAttachmentModel(
      id: readInt(json, const ['id']),
      originalName: readString(json, const ['original_name']),
      mime: readString(json, const ['mime'], fallback: ''),
      size: readInt(json, const ['size']),
    );
  }
}

class AnnouncementPageModel {
  const AnnouncementPageModel({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AnnouncementModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory AnnouncementPageModel.fromJson(Map<String, dynamic> json) {
    final meta = readMap(json, 'meta');

    return AnnouncementPageModel(
      items: readList(json, 'items').map(AnnouncementModel.fromJson).toList(),
      currentPage: readInt(meta, const ['current_page'], fallback: 1),
      lastPage: readInt(meta, const ['last_page'], fallback: 1),
      total: readInt(meta, const ['total']),
    );
  }
}
