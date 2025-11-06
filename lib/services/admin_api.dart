import 'dart:convert';
import 'package:http/http.dart' as http;

const String backendBaseUrl = "http://103.207.1.87:3030";

class AdminApi {
  // 🔄 Get all pending login requests
  static Future<List<dynamic>> getPendingRequests() async {
    final res = await http.get(Uri.parse("$backendBaseUrl/admin/requests"));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load requests");
    }
  }

  // 🧾 Get all staff records
  static Future<List<dynamic>> getAllStaffs() async {
    final res = await http.get(Uri.parse("$backendBaseUrl/admin/staffs"));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load staff list");
    }
  }

  // ✅ Approve a login request
  static Future<void> approveRequest(int requestId, int staffId) async {
    final res = await http.post(
      Uri.parse("$backendBaseUrl/admin/approve"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"requestId": requestId, "staffId": staffId}),
    );

    if (res.statusCode != 200) {
      throw Exception("Approval failed: ${res.body}");
    }
  }
}
