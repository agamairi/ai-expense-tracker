import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/domain/models/update_info.dart';

class UpdateCheckService {
  static const _lastNotifiedVersionKey = 'update_dismissed_version';

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.github.com/repos/agamairi/ai-expense-tracker/releases/latest'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      final String tagName = data['tag_name'];
      final String htmlUrl = data['html_url'];

      final String githubVersionStr = tagName.startsWith('v') ? tagName.substring(1) : tagName;
      
      final packageInfo = await PackageInfo.fromPlatform();
      final String currentVersionStr = packageInfo.version;

      if (_isVersionGreater(githubVersionStr, currentVersionStr)) {
        return UpdateInfo(
          latestVersion: githubVersionStr,
          releaseUrl: htmlUrl,
        );
      }
    } catch (e) {
      // Ignored for best-effort
    }
    return null;
  }

  bool _isVersionGreater(String v1, String v2) {
    final v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    for (int i = 0; i < maxLength; i++) {
      final p1 = i < v1Parts.length ? v1Parts[i] : 0;
      final p2 = i < v2Parts.length ? v2Parts[i] : 0;

      if (p1 > p2) return true;
      if (p1 < p2) return false;
    }
    return false;
  }

  Future<String?> getLastNotifiedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastNotifiedVersionKey);
  }

  Future<void> setLastNotifiedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastNotifiedVersionKey, version);
  }
}
