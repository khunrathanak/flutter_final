import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

Future<void> analyzeSkin(Uint8List imageBytes) async {
  const apiKey = 'cmab96kuj0001l704eknyedn9';

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

  final response = await http.Response.fromStream(await request.send());

  if (response.statusCode == 200) {
    final result = jsonDecode(response.body);
    print('Skin analysis result: $result');
  } else {
    print('Error: ${response.statusCode}');
    print('Body: ${response.body}');
  }
}
