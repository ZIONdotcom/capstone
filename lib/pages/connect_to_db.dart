import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<List<dynamic>> fetchData() async {
    final response = await http.get(Uri.parse('https://rutaco.online/get_data.php'));

    if (response.statusCode == 200) {
      
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }
}



