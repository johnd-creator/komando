import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../features/news/data/models/news_model.dart';
import 'soft_panel.dart';

class LatestNewsCard extends StatelessWidget {
  const LatestNewsCard({
    super.key,
    required this.isLoading,
    required this.items,
    required this.onSeeAll,
    required this.onItemTap,
  });

  final bool isLoading;
  final List<NewsModel> items;
  final VoidCallback onSeeAll;
  final ValueChanged<NewsModel> onItemTap;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Berita terbaru',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onSeeAll,
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Memuat berita terbaru'),
            )
          else if (items.isEmpty)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.article_outlined),
              title: Text('Belum ada berita terbaru'),
              subtitle: Text('Tarik ke bawah untuk memuat ulang.'),
            )
          else
            for (final entry in items.take(3).indexed)
              _LatestNewsTile(
                item: entry.$2,
                showDivider: entry.$1 < items.take(3).length - 1,
                onTap: () => onItemTap(entry.$2),
              ),
        ],
      ),
    );
  }
}

class _LatestNewsTile extends StatelessWidget {
  const _LatestNewsTile({
    required this.item,
    required this.showDivider,
    required this.onTap,
  });

  final NewsModel item;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          width: 96,
                          height: 74,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              _NewsImageFallback(colorScheme: colorScheme),
                          placeholder: (context, url) =>
                              _NewsImageFallback(colorScheme: colorScheme),
                        )
                      : _NewsImageFallback(colorScheme: colorScheme),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                          height: 1.22,
                        ),
                      ),
                      if (item.excerpt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.excerpt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF4B5563),
                                height: 1.32,
                              ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: const Color(0xFF1168CF),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          Text(
                            'Baca',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: const Color(0xFF1168CF),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Color(0xFF1168CF),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF4B5563),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 108, color: Color(0xFFE5EAF1)),
      ],
    );
  }
}

class _NewsImageFallback extends StatelessWidget {
  const _NewsImageFallback({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 74,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.article_outlined, color: colorScheme.onSurfaceVariant),
    );
  }
}
