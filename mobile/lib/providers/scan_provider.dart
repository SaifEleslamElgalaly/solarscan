import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/models.dart';
import 'auth_provider.dart';

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier(ref.watch(apiClientProvider));
});

class ScanState {
  final List<ScanResult> scans;
  final bool isLoading;
  final String? error;

  ScanState({this.scans = const [], this.isLoading = false, this.error});
}

class ScanNotifier extends StateNotifier<ScanState> {
  final ApiClient _apiClient;

  ScanNotifier(this._apiClient) : super(ScanState());

  Future<void> fetchScans() async {
    state = ScanState(scans: state.scans, isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;
      final response = await _apiClient.dio.get('service_api.php?action=get_history&user_id=$userId');
      final List<ScanResult> scans = (response.data as List)
          .map((s) => ScanResult.fromJson(s))
          .toList();
      state = ScanState(scans: scans);
    } catch (e) {
      state = ScanState(scans: state.scans, error: e.toString());
    }
  }

  Future<ScanResult?> uploadImage(File image) async {
    state = ScanState(scans: state.scans, isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;
      
      String fileName = image.path.split('/').last;
      FormData formData = FormData.fromMap({
        "user_id": userId,
        "image": await MultipartFile.fromFile(image.path, filename: fileName),
      });

      final response = await _apiClient.dio.post('service_api.php?action=upload_scan', data: formData);
      print('Upload response: ${response.data}');
      
      final result = ScanResult.fromJson(response.data);
      print('Parsed ScanResult: ${result.id}');
      
      state = ScanState(scans: [result, ...state.scans]);
      return result;
    } catch (e) {
      print('Upload error: $e');
      if (e is TypeError) {
        print('Type error details: $e');
      }
      state = ScanState(scans: state.scans, error: e.toString());
      return null;
    }
  }
}
