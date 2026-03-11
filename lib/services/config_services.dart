import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const _key = "api_base_url";

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? "http://103.207.1.87:3030";
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url);
  }
}