import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_services.dart';

class AdminApi {

  static Map<String, String> headers = {
    "Content-Type": "application/json",
    "ngrok-skip-browser-warning": "true",
  };

  static Future<String> _baseUrl() async {
    return await ConfigService.getBaseUrl();
  }

  // -----------------------
  // Admin Register
  // -----------------------
  static Future<String> registerAdmin(String username, String password) async {

    final baseUrl = await _baseUrl();

    final res = await http.post(
      Uri.parse("$baseUrl/admin/register"),
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

    final baseUrl = await _baseUrl();

    final res = await http.post(
      Uri.parse("$baseUrl/admin/login"),
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

    final baseUrl = await _baseUrl();

    final res = await http.get(
      Uri.parse("$baseUrl/admin/requests"),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load requests: ${res.body}");
    }
  }

  // -----------------------
  // Approve Login Request
  // -----------------------
  static Future<void> approveRequest(int requestId, int staffId) async {

    final baseUrl = await _baseUrl();

    final res = await http.post(
      Uri.parse("$baseUrl/admin/approve"),
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

    final baseUrl = await _baseUrl();

    final res = await http.get(
      Uri.parse("$baseUrl/admin/staffs"),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load staff list: ${res.body}");
    }
  }

  // -----------------------
  // App Config
  // -----------------------
  static Future<Map<String, dynamic>?> getAppConfig() async {

    final baseUrl = await _baseUrl();

    final res = await http.get(
      Uri.parse('$baseUrl/admin/app-config'),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load app config: ${res.body}');
    }

    if (res.body.isEmpty) return null;

    return jsonDecode(res.body);
  }

  static Future<double> updateAllowedRadius(double radius) async {

    final baseUrl = await _baseUrl();

    final res = await http.put(
      Uri.parse('$baseUrl/admin/app-config/radius'),
      headers: headers,
      body: jsonEncode({
        'allowedRadiusMeters': radius
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update radius: ${res.body}');
    }

    final data = jsonDecode(res.body);

    return (data['allowedRadiusMeters'] as num).toDouble();
  }

  // -----------------------
  // Staff Attendance
  // -----------------------
  static Future<List<dynamic>> getStaffAttendance(int staffId) async {

    final baseUrl = await _baseUrl();

    final res = await http.get(
      Uri.parse("$baseUrl/admin/attendance/$staffId"),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Error loading attendance: ${res.body}");
    }
  }

  // -----------------------
  // Check-in / Check-out Pairs
  // -----------------------
  static Future<List<dynamic>> getCheckPairs(int staffId) async {

    final baseUrl = await _baseUrl();

    final res = await http.get(
      Uri.parse("$baseUrl/admin/attendance/pairs/$staffId"),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Error loading pairs: ${res.body}");
    }
  }

  // -----------------------
  // Today's Attendance (All)
  // -----------------------
  static Future<List<dynamic>> getTodayAttendanceForAll() async {

    final baseUrl = await _baseUrl();

    final res = await http.get(
      Uri.parse("$baseUrl/admin/attendance/today/all"),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Error loading today's attendance: ${res.body}");
    }
  }

  // -----------------------
  // Today's Attendance Staffwise
  // -----------------------
  static Future<List<dynamic>> getTodayStaffWise() async {

    final baseUrl = await _baseUrl();

    final res = await http.get(
      Uri.parse("$baseUrl/admin/attendance/today/staffwise"),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Error loading staffwise attendance: ${res.body}");
    }
  }

  // -----------------------
  // App Version
  // -----------------------
  static Future<String?> getLatestAppVersion() async {

    final baseUrl = await _baseUrl();

    final res = await http.get(
      Uri.parse("$baseUrl/app/latest-version"),
      headers: headers,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["latestVersion"]?.toString();
    }

    if (res.statusCode == 404) {
      return null;
    }

    throw Exception("Failed to load latest app version: ${res.body}");
  }

  static Future<void> createAppVersion(String versionNo) async {

    final baseUrl = await _baseUrl();

    final res = await http.post(
      Uri.parse("$baseUrl/admin/app-version"),
      headers: headers,
      body: jsonEncode({
        "versionNo": versionNo
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to update app version: ${res.body}");
    }
  }
}