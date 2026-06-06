import 'dart:convert';

List<dynamic> decodeJsonList(String source) {
  return jsonDecode(source) as List<dynamic>;
}

Map<String, dynamic> decodeJsonMap(String source) {
  return jsonDecode(source) as Map<String, dynamic>;
}
