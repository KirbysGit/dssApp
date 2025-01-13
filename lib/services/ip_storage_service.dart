import 'package:shared_preferences/shared_preferences.dart';

class IPStorageService {
  static const String _key = 'camera_ips';

  Future<void> saveIPs(List<String> ips) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ips);
  }

  Future<List<String>> getIPs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> addIP(String ip) async {
    final ips = await getIPs();
    if (!ips.contains(ip)) {
      ips.add(ip);
      await saveIPs(ips);
    }
  }

  Future<void> removeIP(String ip) async {
    final ips = await getIPs();
    ips.remove(ip);
    await saveIPs(ips);
  }
} 