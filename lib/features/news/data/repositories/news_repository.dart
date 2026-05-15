import '../../../../core/cache/app_cache.dart';
import '../models/news_model.dart';
import '../wordpress_client.dart';

class NewsRepository {
  NewsRepository(this._wpClient, {AppCache? cache})
    : _cache = cache ?? AppCache();

  final WordpressClient _wpClient;
  final AppCache _cache;

  Future<List<NewsModel>> getCachedPosts() async {
    // Return empty if cache is stale (>15 min)
    if (await _cache.isStale(
      AppCache.newsFirstPageKey,
      const Duration(minutes: 15),
    )) {
      return const [];
    }
    final cached = await _cache.readJson(AppCache.newsFirstPageKey);
    return _readCachedItems(cached);
  }

  Future<List<NewsModel>> getCachedLatestPosts() async {
    // Return empty if cache is stale (>15 min)
    if (await _cache.isStale(
      AppCache.newsLatestKey,
      const Duration(minutes: 15),
    )) {
      return const [];
    }
    final cached = await _cache.readJson(AppCache.newsLatestKey);
    return _readCachedItems(cached);
  }

  Future<List<NewsModel>> getLatestPosts({int limit = 3}) async {
    final posts = await getPosts(
      page: 1,
      perPage: limit,
      cacheFirstPage: false,
    );
    await _cache.writeJson(AppCache.newsLatestKey, {
      'items': posts.map((post) => post.toCache()).toList(),
      'cached_at': DateTime.now().toIso8601String(),
    });
    return posts;
  }

  List<NewsModel> _readCachedItems(Map<String, dynamic>? cached) {
    final items = cached?['items'];
    if (items is! List) return const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(NewsModel.fromCache)
        .toList();
  }

  Future<List<NewsModel>> getPosts({
    int page = 1,
    int perPage = 10,
    bool cacheFirstPage = true,
  }) async {
    final response = await _wpClient.dio.get<List<dynamic>>(
      '/posts',
      queryParameters: {'page': page, 'per_page': perPage, '_embed': ''},
    );
    final list = response.data ?? [];
    final posts = list
        .map((e) => NewsModel.fromJson(e as Map<String, dynamic>))
        .toList();
    if (cacheFirstPage && page == 1) {
      await _cache.writeJson(AppCache.newsFirstPageKey, {
        'items': posts.map((post) => post.toCache()).toList(),
        'cached_at': DateTime.now().toIso8601String(),
      });
    }
    return posts;
  }
}
