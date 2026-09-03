import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../../shared/models/language.dart';

class ApiClient {
  static const String baseUrl = AppConstants.apiBaseUrl;

  static const List<Language> defaultLangs = [
    Language(code: 'auto', name: 'Auto Detect', nativeName: 'Auto Detect', flag: '🌐'),
    Language(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧', popular: true),
    Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳', popular: true),
    Language(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸', popular: true),
    Language(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷', popular: true),
    Language(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪', popular: true),
    Language(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦', rtl: true, popular: true),
    Language(code: 'ur', name: 'Urdu', nativeName: 'اردو', flag: '🇵🇰', rtl: true, popular: true),
    Language(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳', popular: true),
    Language(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵', popular: true),
    Language(code: 'ru', name: 'Russian', nativeName: 'Русский', flag: '🇷🇺', popular: true),
  ];

  static Future<List<Language>> getLanguages() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/languages'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List list = data['languages'] ?? [];
        return list.map((item) => Language.fromJson(item)).toList();
      }
    } catch (e) {}
    return defaultLangs;
  }

  // Core Direct Document Translation Method
  static Future<Map<String, dynamic>> translateDocument({
    required Uint8List fileBytes,
    required String fileName,
    required String sourceLanguage,
    required String targetLanguage,
    required String jobId,
    String? requestId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/translate/document');
      final request = http.MultipartRequest('POST', uri);

      request.fields['sourceLanguage'] = sourceLanguage;
      request.fields['targetLanguage'] = targetLanguage;
      request.fields['jobId'] = jobId;
      request.fields['requestId'] = requestId ?? 'req_${DateTime.now().millisecondsSinceEpoch}';

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (e) {
      print('[ApiClient] Direct backend document upload notice: $e');
    }

    return {'success': false, 'error': 'Direct document translation failed'};
  }

  // Instant Live Text Translation
  static Future<Map<String, dynamic>> translateText(String text, String source, String target) async {
    if (text.trim().isEmpty) {
      return {'success': true, 'translatedText': '', 'detectedSourceLanguage': source};
    }

    // 1. Direct Live Google Translate API (GTX client)
    try {
      final gtxUrl = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$source&tl=$target&dt=t&q=${Uri.encodeComponent(text)}';
      final gtxRes = await http.get(Uri.parse(gtxUrl));
      if (gtxRes.statusCode == 200) {
        final dynamic data = jsonDecode(gtxRes.body);
        if (data is List && data.isNotEmpty && data[0] is List) {
          final List parts = data[0];
          final String translatedStr = parts.map((p) => (p is List && p.isNotEmpty) ? p[0]?.toString() ?? '' : '').join();
          if (translatedStr.trim().isNotEmpty) {
            return {
              'success': true,
              'translatedText': translatedStr,
              'detectedSourceLanguage': (data.length > 2 && data[2] != null) ? data[2].toString() : (source == 'auto' ? 'auto' : source),
              'provider': 'Google Neural Live Engine',
            };
          }
        }
      }
    } catch (e) {}

    // 2. Shared Backend API
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/translate/text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'sourceLanguage': source,
          'targetLanguage': target,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['translatedText'] != null && data['translatedText'].toString().trim().isNotEmpty) {
          return {
            'success': true,
            'translatedText': data['translatedText'],
            'detectedSourceLanguage': data['detectedSourceLanguage'] ?? source,
            'provider': data['provider'] ?? 'PolyLingo Neural Backend',
          };
        }
      }
    } catch (e) {}

    // 3. Direct Live MyMemory Translation API
    try {
      final myMemoryUrl = 'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=$source|$target';
      final mmRes = await http.get(Uri.parse(myMemoryUrl));
      if (mmRes.statusCode == 200) {
        final data = jsonDecode(mmRes.body);
        final trans = data['responseData']?['translatedText'];
        if (trans != null && trans.toString().trim().isNotEmpty && !trans.toString().contains('MYMEMORY WARNING')) {
          return {
            'success': true,
            'translatedText': trans.toString(),
            'detectedSourceLanguage': source,
            'provider': 'MyMemory Live Engine',
          };
        }
      }
    } catch (e) {}

    // If all real APIs fail, return error with explicit failure message (NO fake data)
    return {
      'success': false,
      'error': 'Translation validation failed. The live translation service could not process the text from "$source" to "$target".',
      'translatedText': '',
    };
  }
}
