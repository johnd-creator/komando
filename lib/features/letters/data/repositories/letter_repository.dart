import '../../../../core/api/api_client.dart';
import '../../../../core/api/json_read.dart';
import '../models/letter_model.dart';

class LetterRepository {
  const LetterRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<LetterPageModel> getLetters({
    required String box,
    int page = 1,
    int perPage = 10,
  }) async {
    final endpoint = switch (box) {
      'inbox' => '/letters/inbox',
      'outbox' => '/letters/outbox',
      'approvals' => '/letters/approvals',
      _ => '/letters/inbox',
    };

    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return LetterPageModel.fromJson(response.data ?? {});
  }

  Future<LetterModel> getLetter(int id) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/letters/$id',
    );
    final data = response.data ?? {};
    final letterJson = Map<String, dynamic>.from(
      data['letter'] as Map<String, dynamic>? ?? data,
    );

    try {
      final preview = await _apiClient.dio.get<Map<String, dynamic>>(
        '/letters/$id/preview',
      );
      final previewData = preview.data ?? {};
      final previewLetter = previewData['letter'];
      if (previewLetter is Map<String, dynamic>) {
        letterJson.addAll(previewLetter);
      }
      final bodyHtml = readString(previewData, const [
        'body_html',
      ], fallback: '');
      if (bodyHtml.isNotEmpty) {
        letterJson['body_html'] = bodyHtml;
      }
    } catch (_) {
      // The detail endpoint remains useful even if preview is unavailable.
    }

    return LetterModel.fromJson(letterJson);
  }

  Future<LetterModel> createLetter({
    required int categoryId,
    required String subject,
    required String body,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/letters',
      data: {
        'letter_category_id': categoryId,
        'signer_type': 'ketua',
        'to_type': 'admin_pusat',
        'subject': subject,
        'body': body,
        'confidentiality': 'normal',
        'urgency': 'normal',
      },
    );
    return LetterModel.fromJson(
      response.data?['letter'] as Map<String, dynamic>? ?? response.data ?? {},
    );
  }

  Future<LetterModel> submitLetter(int id) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/letters/$id/submit',
    );
    return LetterModel.fromJson(
      response.data?['letter'] as Map<String, dynamic>? ?? response.data ?? {},
    );
  }

  Future<LetterModel> sendLetter(int id) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/letters/$id/send',
    );
    return LetterModel.fromJson(
      response.data?['letter'] as Map<String, dynamic>? ?? response.data ?? {},
    );
  }

  Future<void> archiveLetter(int id) async {
    await _apiClient.dio.post<void>('/letters/$id/archive');
  }

  Future<LetterModel> approveLetter(int id) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/letters/$id/approve',
    );
    return LetterModel.fromJson(
      response.data?['letter'] as Map<String, dynamic>? ?? response.data ?? {},
    );
  }

  Future<LetterModel> rejectLetter(int id) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/letters/$id/reject',
      data: {'note': 'Ditolak dari aplikasi mobile'},
    );
    return LetterModel.fromJson(
      response.data?['letter'] as Map<String, dynamic>? ?? response.data ?? {},
    );
  }

  Future<List<LetterCategoryModel>> getCategories() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/letters/categories',
    );
    final data = readList(response.data ?? {}, 'items').isNotEmpty
        ? readList(response.data ?? {}, 'items')
        : readList(response.data ?? {}, 'data');
    return data.map(LetterCategoryModel.fromJson).toList();
  }
}
