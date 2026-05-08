import '../../../../core/api/json_read.dart';

class LetterModel {
  const LetterModel({
    required this.id,
    required this.number,
    required this.subject,
    required this.body,
    required this.status,
    required this.categoryName,
    required this.creatorName,
    required this.unitName,
    required this.createdAt,
    required this.hasAttachments,
  });

  final int id;
  final String number;
  final String subject;
  final String body;
  final String status;
  final String categoryName;
  final String creatorName;
  final String unitName;
  final String createdAt;
  final bool hasAttachments;

  factory LetterModel.fromJson(Map<String, dynamic> json) {
    final category = readMap(json, 'category');
    final creator = readMap(json, 'creator');
    final unit = readMap(json, 'from_unit').isNotEmpty
        ? readMap(json, 'from_unit')
        : readMap(json, 'organization_unit');

    return LetterModel(
      id: readInt(json, const ['id']),
      number: readString(json, const [
        'letter_number',
        'number',
      ], fallback: '-'),
      subject: readString(json, const ['subject', 'title']),
      body: readString(json, const ['body'], fallback: ''),
      status: readString(json, const ['status'], fallback: 'draft'),
      categoryName: readString(category, const ['name'], fallback: 'Umum'),
      creatorName: readString(creator, const ['name'], fallback: 'Anggota'),
      unitName: readString(unit, const ['name'], fallback: '-'),
      createdAt: readString(json, const ['created_at'], fallback: ''),
      hasAttachments: readList(json, 'attachments').isNotEmpty,
    );
  }
}

class LetterPageModel {
  const LetterPageModel({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<LetterModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory LetterPageModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final data = readList(json, 'letters').isNotEmpty
        ? readList(json, 'letters')
        : readList(json, 'data');

    return LetterPageModel(
      items: data.map(LetterModel.fromJson).toList(),
      currentPage: readInt(meta, const ['current_page'], fallback: 1),
      lastPage: readInt(meta, const ['last_page'], fallback: 1),
      total: readInt(meta, const ['total']),
    );
  }
}

class LetterCategoryModel {
  const LetterCategoryModel({required this.id, required this.name});

  final int id;
  final String name;

  factory LetterCategoryModel.fromJson(Map<String, dynamic> json) {
    return LetterCategoryModel(
      id: readInt(json, const ['id']),
      name: readString(json, const ['name']),
    );
  }
}
