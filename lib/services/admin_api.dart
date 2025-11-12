import 'dart:convert';
import 'package:http/http.dart' as http;

const String backendBaseUrl = "https://079a9fefb19d.ngrok-free.app";

class AdminApi {
  static Future<List<dynamic>> getPendingRequests() async {
    final res = await http.get(
      Uri.parse("$backendBaseUrl/admin/requests"),
      headers: {"ngrok-skip-browser-warning": "true"},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load requests");
    }
  }

  static Future<List<dynamic>> getAllStaffs() async {
    final res = await http.get(
      Uri.parse("$backendBaseUrl/admin/staffs"),
      headers: {"ngrok-skip-browser-warning": "true"},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load staff list");
    }
  }

  static Future<void> approveRequest(int requestId, int staffId) async {
    final res = await http.post(
      Uri.parse("$backendBaseUrl/admin/approve"),
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({"requestId": requestId, "staffId": staffId}),
    );


    if (res.statusCode != 200) {
      throw Exception("Approval failed: ${res.body}");
    }
  }
}
