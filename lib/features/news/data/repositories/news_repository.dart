import '../models/news_model.dart';
import '../wordpress_client.dart';

class NewsRepository {
  const NewsRepository(this._wpClient);

  final WordpressClient _wpClient;

  Future<List<NewsModel>> getPosts({int page = 1, int perPage = 10}) async {
    final response = await _wpClient.dio.get<List<dynamic>>(
      '/posts',
      queryParameters: {'page': page, 'per_page': perPage, '_embed': ''},
    );
    final list = response.data ?? [];
    return list
        .map((e) => NewsModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
