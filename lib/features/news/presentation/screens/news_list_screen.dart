import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/section_header.dart';
import '../../data/models/news_model.dart';
import '../bloc/news_bloc.dart';
import '../bloc/news_event.dart';
import '../bloc/news_state.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<NewsBloc>().add(const NewsFetched());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NewsBloc>().add(const NewsLoadMore());
    }
  }

  void _reload() {
    context.read<NewsBloc>().add(const NewsFetched(refresh: true));
  }

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocBuilder<NewsBloc, NewsState>(
        builder: (context, state) {
          if (state is NewsLoading || state is NewsInitial) {
            return const _LoadingView();
          }
          if (state is NewsFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          final loaded = state as NewsLoaded;

          if (loaded.items.isEmpty) {
            return const EmptyState(
              title: 'Belum ada berita',
              message: 'Berita terbaru akan tampil di sini.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                const FeaturePageHeader(
                  title: 'Berita & Info',
                  icon: Icons.newspaper_rounded,
                  subtitle: 'Informasi terkini seputar serikat',
                ),
                // Featured first article
                if (loaded.items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _FeaturedNewsCard(
                        item: loaded.items.first,
                        onTap: () => _openLink(loaded.items.first.link),
                      ),
                    ),
                  ),
                // Rest of articles
                if (loaded.items.length > 1)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    sliver: SliverList.builder(
                      itemCount:
                          (loaded.items.length - 1) + (loaded.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= loaded.items.length - 1) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = loaded.items[index + 1];
                        return _NewsListCard(
                          item: item,
                          onTap: () => _openLink(item.link),
                          isLast: index == loaded.items.length - 2,
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Featured Card (first article, large) ────────────────────────────────────

class _FeaturedNewsCard extends StatelessWidget {
  const _FeaturedNewsCard({required this.item, required this.onTap});

  final NewsModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (item.imageUrl.isNotEmpty)
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      height: 200,
                      color: const Color(0xFFE8EEF7),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      height: 200,
                      color: const Color(0xFFE8EEF7),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Terbaru',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 120,
                color: const Color(0xFFE8EEF7),
                child: const Center(
                  child: Icon(
                    Icons.newspaper_rounded,
                    size: 48,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.date,
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1565C0,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Baca selengkapnya',
                              style: TextStyle(
                                color: Color(0xFF1565C0),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Color(0xFF1565C0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact list card (subsequent articles) ─────────────────────────────────

class _NewsListCard extends StatelessWidget {
  const _NewsListCard({
    required this.item,
    required this.onTap,
    this.isLast = false,
  });

  final NewsModel item;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _placeholder(),
                          placeholder: (_, _) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (item.excerpt.isNotEmpty)
                        Text(
                          item.excerpt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.date,
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 80,
      height: 80,
      color: const Color(0xFFE8EEF7),
      child: const Icon(
        Icons.newspaper_rounded,
        color: Color(0xFF1565C0),
        size: 32,
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        FeaturePageHeader(
          title: 'Berita & Info',
          icon: Icons.newspaper_rounded,
        ),
        SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}
