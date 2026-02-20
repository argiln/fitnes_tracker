import 'dart:convert';
import 'package:http/http.dart' as http;

class NutritionServiceApi {
  static const String _apiKey = 'QvAFUhMlnE1V5/L0kLjFiQ==RjE8svTLjCtrwpCk';

  static Future<Map<String, dynamic>?> fetchNutrition(String query) async {
    try {
      final url = Uri.https('api.calorieninjas.com', '/v1/nutrition', {'query': query});
      final response = await http.get(url, headers: {'X-Api-Key': _apiKey});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List;
        
        if (items.isNotEmpty) {
          return items[0]; // Return the first food item found
        }
      }
      return null; // Return null if nothing is found or error occurs
    } catch (e) {
      print("API Error: $e");
      return null;
    }
  }
}