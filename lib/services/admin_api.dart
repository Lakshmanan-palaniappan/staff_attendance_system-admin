import 'dart:convert';
import 'package:http/http.dart' as http;

const String backendBaseUrl = /*"https://e29f2adc850c.ngrok-free.app"*/"http://10.201.191.29:3030";

class AdminApi {
  static Map<String, String> headers = {
    "Content-Type": "application/json",
    "ngrok-skip-browser-warning": "true",
  };

  // -----------------------
  // Admin Register
  // -----------------------
  static Future<String> registerAdmin(String username, String password) async {
    final res = await http.post(
      Uri.parse("$backendBaseUrl/admin/register"),
      headers: headers,
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    if (res.statusCode == 200) {
      return "Registered";
    } else {
      throw Exception(res.body);
    }
  }

  // -----------------------
  // Admin Login
  // -----------------------
  static Future<String> loginAdmin(String username, String password) async {
    final res = await http.post(
      Uri.parse("$backendBaseUrl/admin/login"),
      headers: headers,
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    if (res.statusCode == 200) {
      return "Logged In";
    } else {
      throw Exception(res.body);
    }
  }

  // -----------------------
  // Pending Login Requests
  // -----------------------
  static Future<List<dynamic>> getPendingRequests() async {
    final res = await http.get(
      Uri.parse("$backendBaseUrl/admin/requests"),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      throw Exception("Failed to load requests: ${res.body}");
    }
  }

  // -----------------------
  // Approve Login Request
  // -----------------------
  static Future<void> approveRequest(int requestId, int staffId) async {
    final res = await http.post(
      Uri.parse("$backendBaseUrl/admin/approve"),
      headers: headers,
      body: jsonEncode({
        "requestId": requestId,
        "staffId": staffId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Approval failed: ${res.body}");
    }
  }

  // -----------------------
  // Get all staff
  // -----------------------
  static Future<List<dynamic>> getAllStaffs() async {
    final res = await http.get(
      Uri.parse("$backendBaseUrl/admin/staffs"),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      throw Exception("Failed to load staff list: ${res.body}");
    }
  }

  // -----------------------
  // Get full attendance of a staff
  // -----------------------
  static Future<List<dynamic>> getStaffAttendance(int staffId) async {
    final res = await http.get(
      Uri.parse("$backendBaseUrl/admin/attendance/$staffId"),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Error loading attendance: ${res.body}");
    }
  }

  // -----------------------
  // Get check-in/check-out pairs
  // -----------------------
  static Future<List<dynamic>> getCheckPairs(int staffId) async {
    final res = await http.get(
      Uri.parse("$backendBaseUrl/admin/attendance/pairs/$staffId"),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Error loading pairs: ${res.body}");
    }
  }

  // -----------------------
  // Get today's attendance for all staff
  // -----------------------
  static Future<List<dynamic>> getTodayAttendanceForAll() async {
    final res = await http.get(
      Uri.parse("$backendBaseUrl/admin/attendance/today/all"),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Error loading today's attendance: ${res.body}");
    }
  }
  static Future<List<dynamic>> getTodayStaffWise() async {
  final res = await http.get(
    Uri.parse("$backendBaseUrl/admin/attendance/today/staffwise"),
    headers: headers,
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Error loading staffwise attendance: ${res.body}");
  }

}

static Future<String?> getLatestAppVersion() async {
    final res = await http.get(
      Uri.parse("$backendBaseUrl/app/latest-version"),
      headers: headers,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["latestVersion"]?.toString();
    }

    if (res.statusCode == 404) {
      // No latest configured yet
      return null;
    }

    throw Exception("Failed to load latest app version: ${res.body}");
  }

  static Future<void> createAppVersion(String versionNo) async {
    final res = await http.post(
      Uri.parse("$backendBaseUrl/admin/app-version"),
      headers: headers,
      body: jsonEncode({"versionNo": versionNo}),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to update app version: ${res.body}");
    }
  }


}


