import 'package:flutter_test/flutter_test.dart';
import 'package:komando/core/api/json_read.dart';

void main() {
  group('readString', () {
    test('returns value when key exists', () {
      final json = {'name': 'John'};
      expect(readString(json, ['name']), 'John');
    });

    test('returns fallback when key is missing', () {
      final json = <String, dynamic>{};
      expect(readString(json, ['name'], fallback: '-'), '-');
    });

    test('tries multiple keys', () {
      final json = {'b': 'found'};
      expect(readString(json, ['a', 'b', 'c']), 'found');
    });

    test('returns first found key', () {
      final json = {'a': 'first', 'b': 'second'};
      expect(readString(json, ['a', 'b']), 'first');
    });

    test('converts num to string', () {
      final json = {'n': 42};
      expect(readString(json, ['n']), '42');
    });

    test('skips empty strings', () {
      final json = {'a': '', 'b': 'value'};
      expect(readString(json, ['a', 'b']), 'value');
    });
  });

  group('readInt', () {
    test('returns int value', () {
      final json = {'id': 5};
      expect(readInt(json, ['id']), 5);
    });

    test('returns fallback when key missing', () {
      final json = <String, dynamic>{};
      expect(readInt(json, ['id'], fallback: -1), -1);
    });

    test('converts num to int', () {
      final json = {'id': 3.0};
      expect(readInt(json, ['id']), 3);
    });

    test('parses string to int', () {
      final json = {'id': '10'};
      expect(readInt(json, ['id']), 10);
    });
  });

  group('readMap', () {
    test('returns map value', () {
      final json = {'data': {'key': 'value'}};
      final result = readMap(json, 'data');
      expect(result, {'key': 'value'});
    });

    test('returns empty map for null/non-map values', () {
      expect(readMap({}, 'missing'), {});
      expect(readMap({'n': 1}, 'n'), {});
    });
  });

  group('readList', () {
    test('returns list of maps', () {
      final json = {
        'items': [
          {'id': 1},
          {'id': 2},
        ],
      };
      final result = readList(json, 'items');
      expect(result.length, 2);
    });

    test('returns empty list for missing key', () {
      expect(readList({}, 'items'), []);
    });
  });
}
