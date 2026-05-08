import '../../../../core/api/api_client.dart';
import '../../../../core/api/json_read.dart';
import '../models/aspiration_model.dart';

class AspirationRepository {
  const AspirationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AspirationPageModel> getAspirations({
    int page = 1,
    int perPage = 10,
    String? category,
    String? status,
    String? sort,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (category != null && category.isNotEmpty) {
      queryParameters['category'] = category;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (sort != null && sort.isNotEmpty) {
      queryParameters['sort'] = sort;
    }

    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/aspirations',
      queryParameters: queryParameters,
    );
    return AspirationPageModel.fromJson(response.data ?? {});
  }

  Future<AspirationModel> getAspiration(int id) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/aspirations/$id',
    );
    final data = response.data ?? {};
    final aspirationJson = data['aspiration'] as Map<String, dynamic>? ?? data;
    return AspirationModel.fromJson(aspirationJson);
  }

  Future<AspirationModel> createAspiration({
    required int categoryId,
    required String title,
    required String body,
    List<String> tags = const [],
    bool isAnonymous = false,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/aspirations',
      data: {
        'category_id': categoryId,
        'title': title,
        'body': body,
        'tags': tags,
        'is_anonymous': isAnonymous,
      },
    );
    return AspirationModel.fromJson(
      response.data?['aspiration'] as Map<String, dynamic>? ??
          response.data ??
          {},
    );
  }

  Future<void> support(int id) async {
    await _apiClient.dio.post<void>('/aspirations/$id/support');
  }

  Future<void> unsupport(int id) async {
    await _apiClient.dio.delete<void>('/aspirations/$id/support');
  }

  Future<List<AspirationCategoryModel>> getCategories() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/aspiration-categories',
    );
    final data = readList(response.data ?? {}, 'items').isNotEmpty
        ? readList(response.data ?? {}, 'items')
        : readList(response.data ?? {}, 'data');
    return data.map(AspirationCategoryModel.fromJson).toList();
  }

  Future<List<AspirationTagModel>> getTags() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/aspiration-tags',
    );
    final rawItems = response.data?['items'];
    if (rawItems is List) {
      return rawItems
          .map(
            (item) => item is Map<String, dynamic>
                ? AspirationTagModel.fromJson(item)
                : AspirationTagModel(name: item.toString()),
          )
          .toList();
    }

    final data = readList(response.data ?? {}, 'data');
    return data.map(AspirationTagModel.fromJson).toList();
  }
}
