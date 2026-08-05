import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/models.dart';

import 'host_provider.dart';

final apiClientProvider = Provider((ref) {
  final host = ref.watch(hostProvider);
  return ApiClient(host ?? 'http://10.0.2.2'); // Default if not yet set
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(AuthState()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    // For native PHP, we'll simplify this by storing user data in prefs or similar
  }

  Future<bool> login(String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      final url = 'service_api.php?action=login';
      print('Attempting login at: ${_apiClient.dio.options.baseUrl}$url');
      
      final response = await _apiClient.dio.post(url, data: {
        'email': email,
        'password': password,
      });
      
      print('Login response: ${response.data}');
      
      final token = response.data['access_token'];
      final user = User.fromJson(response.data['user']);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setInt('user_id', user.id);
      
      state = AuthState(user: user);
      return true;
    } catch (e) {
      print('Login error: $e');
      if (e is DioException) {
        print('Dio error type: ${e.type}');
        print('Dio error response: ${e.response?.data}');
      }
      state = AuthState(error: 'Invalid login details');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = AuthState();
  }
}
