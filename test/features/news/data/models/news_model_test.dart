import 'package:flutter_test/flutter_test.dart';
import 'package:komando/features/news/data/models/news_model.dart';

void main() {
  group('NewsModel', () {
    test('fromJson parses WordPress response correctly', () {
      final json = {
        'id': 183,
        'date': '2026-05-07T01:20:28',
        'link': 'https://sppips.org/2026/05/07/test-post/',
        'title': {'rendered': 'Judul Berita'},
        'excerpt': {'rendered': '<p>Ringkasan berita test.</p>'},
        '_embedded': {
          'wp:featuredmedia': [
            {'source_url': 'https://sppips.org/image.jpg'},
          ],
        },
      };

      final model = NewsModel.fromJson(json);

      expect(model.id, 183);
      expect(model.title, 'Judul Berita');
      expect(model.excerpt, 'Ringkasan berita test.');
      expect(model.link, 'https://sppips.org/2026/05/07/test-post/');
      expect(model.imageUrl, 'https://sppips.org/image.jpg');
      expect(model.date, '7 Mei 2026');
    });

    test('fromJson strips HTML from title and excerpt', () {
      final json = {
        'id': 1,
        'date': '2026-01-15T00:00:00',
        'link': 'https://example.com',
        'title': {'rendered': '<strong>Judul</strong> <em>Berita</em>'},
        'excerpt': {
          'rendered': '<p>Ringkasan <a href="#">link</a> &amp; simbol.</p>',
        },
      };

      final model = NewsModel.fromJson(json);

      expect(model.title, 'Judul Berita');
      expect(model.excerpt, 'Ringkasan link simbol.');
    });

    test('fromJson handles missing fields gracefully', () {
      final json = <String, dynamic>{};

      final model = NewsModel.fromJson(json);

      expect(model.id, 0);
      expect(model.title, '');
      expect(model.excerpt, '');
      expect(model.link, '');
      expect(model.imageUrl, '');
      expect(model.date, '');
    });

    test('fromJson handles null nested fields', () {
      final json = {
        'id': 5,
        'date': '2026-03-01T12:00:00',
        'link': 'https://example.com',
      };

      final model = NewsModel.fromJson(json);

      expect(model.id, 5);
      expect(model.title, '');
      expect(model.excerpt, '');
    });

    test('_formatDate handles various ISO formats', () {
      final jan = NewsModel.fromJson({
        'id': 1,
        'date': '2026-01-01T00:00:00',
        'link': '',
      });
      final dec = NewsModel.fromJson({
        'id': 1,
        'date': '2026-12-25T23:59:59',
        'link': '',
      });
      final invalid = NewsModel.fromJson({
        'id': 1,
        'date': 'not-a-date',
        'link': '',
      });

      expect(jan.date, '1 Jan 2026');
      expect(dec.date, '25 Des 2026');
      expect(invalid.date, 'not-a-date'.substring(0, 10));
    });
  });
}
