String _stripHtml(String html) {
  if (html.isEmpty) return '';
  return html
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll(RegExp(r'&#?[a-zA-Z0-9]+;'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class NewsModel {
  const NewsModel({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.link,
    required this.imageUrl,
    required this.date,
  });

  final int id;
  final String title;
  final String excerpt;
  final String link;
  final String imageUrl;
  final String date;

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as Map<String, dynamic>?;
    final excerpt = json['excerpt'] as Map<String, dynamic>?;
    final embedded = json['_embedded'] as Map<String, dynamic>?;
    final media = embedded?['wp:featuredmedia'] as List<dynamic>?;

    return NewsModel(
      id: json['id'] as int? ?? 0,
      title: _stripHtml(title?['rendered'] as String? ?? ''),
      excerpt: _stripHtml(excerpt?['rendered'] as String? ?? ''),
      link: json['link'] as String? ?? '',
      imageUrl: _extractImage(media),
      date: _formatDate(json['date'] as String? ?? ''),
    );
  }

  static String _extractImage(List<dynamic>? media) {
    if (media == null || media.isEmpty) return '';
    final first = media.first as Map<String, dynamic>?;
    return first?['source_url'] as String? ?? '';
  }

  static String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return isoDate.substring(0, 10);
    }
  }
}
