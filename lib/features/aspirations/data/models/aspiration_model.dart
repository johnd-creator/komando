import '../../../../core/api/json_read.dart';

class AspirationModel {
  const AspirationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isAnonymous,
    required this.status,
    required this.supportCount,
    required this.isSupported,
    required this.isOwner,
    required this.categoryName,
    required this.creatorName,
    required this.createdAt,
    required this.tags,
  });

  final int id;
  final String title;
  final String body;
  final bool isAnonymous;
  final String status;
  final int supportCount;
  final bool isSupported;
  final bool isOwner;
  final String categoryName;
  final String creatorName;
  final String createdAt;
  final List<String> tags;

  factory AspirationModel.fromJson(Map<String, dynamic> json) {
    final category = readMap(json, 'category');
    final creator = readMap(json, 'creator');

    return AspirationModel(
      id: readInt(json, const ['id']),
      title: readString(json, const ['title']),
      body: readString(json, const ['body'], fallback: ''),
      isAnonymous: json['is_anonymous'] == true,
      status: readString(json, const ['status'], fallback: 'belum_diproses'),
      supportCount: readInt(json, const ['support_count']),
      isSupported: json['is_supported'] == true,
      isOwner: json['is_owner'] == true,
      categoryName: readString(category, const ['name'], fallback: 'Umum'),
      creatorName: json['is_anonymous'] == true
          ? 'Anonim'
          : readString(creator.isNotEmpty ? creator : json, const [
              'member_name',
              'user_name',
              'creator_name',
            ], fallback: 'Anggota'),
      createdAt: readString(json, const ['created_at'], fallback: ''),
      tags:
          (json['tags'] as List<dynamic>?)?.whereType<String>().toList() ??
          const [],
    );
  }
}

class AspirationPageModel {
  const AspirationPageModel({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AspirationModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory AspirationPageModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final data = readList(json, 'items').isNotEmpty
        ? readList(json, 'items')
        : readList(json, 'data');

    return AspirationPageModel(
      items: data.map(AspirationModel.fromJson).toList(),
      currentPage: readInt(meta, const ['current_page'], fallback: 1),
      lastPage: readInt(meta, const ['last_page'], fallback: 1),
      total: readInt(meta, const ['total']),
    );
  }
}

class AspirationCategoryModel {
  const AspirationCategoryModel({required this.id, required this.name});

  final int id;
  final String name;

  factory AspirationCategoryModel.fromJson(Map<String, dynamic> json) {
    return AspirationCategoryModel(
      id: readInt(json, const ['id']),
      name: readString(json, const ['name']),
    );
  }
}

class AspirationTagModel {
  const AspirationTagModel({required this.name});

  final String name;

  factory AspirationTagModel.fromJson(Map<String, dynamic> json) {
    return AspirationTagModel(name: readString(json, const ['name', 'tag']));
  }
}
