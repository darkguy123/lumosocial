import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> translateText(String text, {String targetLang = 'en'}) async {
  if (text.isEmpty) return text;
  try {
    final url = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}'
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null && data[0] != null) {
        final segments = data[0] as List<dynamic>;
        return segments.map((s) => s[0].toString()).join('');
      }
    }
  } catch (e) {
    print('Translation error: $e');
  }
  return text;
}
