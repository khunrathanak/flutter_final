// In skincare_api_util.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
// You might need to import your Product model and ProductProvider if you return products directly
// For this example, we'll just print the result and assume you'll call the provider later.
// OR, you can pass the provider instance.

// Option 1: analyzeSkin returns the raw API result for further processing
Future<Map<String, dynamic>?> analyzeSkin(Uint8List imageBytes) async { // Return nullable map
  const apiKey = 'cmab96kuj0001l704eknyedn9'; // Replace with your actual API key
  final uri = Uri.parse(
      'https://prod.api.market/api/v1/ailabtools/skin-analyze/portrait/analysis/skinanalyze');
  final request = http.MultipartRequest('POST', uri)
    ..headers.addAll({
      'accept': 'application/json',
      'x-magicapi-key': apiKey,
    })
    ..files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'skin.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));

  try {
    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
      print('Skin analysis raw response: $decodedResponse');
      if (decodedResponse['error_code'] == 0 && decodedResponse.containsKey('result')) {
        return decodedResponse['result'] as Map<String, dynamic>; // Return only the 'result' part
      } else {
        print('API Error: ${decodedResponse['error_detail'] ?? decodedResponse['error_code']}');
        return null;
      }
    } else {
      print('HTTP Error: ${response.statusCode}');
      print('Body: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Exception during API call: $e');
    return null;
  }
}