Map<String, dynamic> readMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) {
    return value;
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> readList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList();
  }
  return const [];
}

String readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '-',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    if (value is num) {
      return value.toString();
    }
  }
  return fallback;
}

int readInt(Map<String, dynamic> json, List<String> keys, {int fallback = 0}) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
  }
  return fallback;
}
