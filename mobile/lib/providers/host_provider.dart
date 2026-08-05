import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final hostProvider = StateNotifierProvider<HostNotifier, String?>((ref) {
  return HostNotifier();
});

class HostNotifier extends StateNotifier<String?> {
  HostNotifier() : super(null) {
    _loadHost();
  }

  Future<void> _loadHost() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('server_ip');
  }

  Future<void> setHost(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    // Clean IP (remove http:// or trailing slashes if present, we'll standardize it)
    String cleanIp = ip.trim();
    if (!cleanIp.startsWith('http')) {
      cleanIp = 'http://$cleanIp';
    }
    // Remove trailing slash if present
    if (cleanIp.endsWith('/')) {
      cleanIp = cleanIp.substring(0, cleanIp.length - 1);
    }
    
    await prefs.setString('server_ip', cleanIp);
    state = cleanIp;
    print('Host saved: $cleanIp');
  }
}
