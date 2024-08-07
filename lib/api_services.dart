import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<User>> fetchUsers() async {
  final response =
      await http.get(Uri.parse('http://localhost/flutter.api/api.php'));

  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    return jsonResponse.map((data) => User.fromJson(data)).toList();
  } else {
    throw Exception('Failed to load users');
  }
}

class User {
  final int userID;
  final String username;
  final String password;
  final String email;

  User(
      {required this.userID,
      required this.username,
      required this.password,
      required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['userID'],
      username: json['username'],
      password: json['password'],
      email: json['email'],
    );
  }
}
