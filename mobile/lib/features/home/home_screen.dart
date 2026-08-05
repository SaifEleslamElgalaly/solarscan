import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';
import '../../providers/host_provider.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../scan/history_screen.dart';
import '../alerts/alerts_screen.dart';
import '../scan/camera_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(scanProvider.notifier).fetchScans());
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final result = await ref.read(scanProvider.notifier).uploadImage(File(image.path));
      if (result != null && mounted) {
        _showResultDialog(result);
      }
    }
  }

  void _showResultDialog(dynamic result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Scan Result', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Defect: ${result.result}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            const Text('Recommendation:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(result.recommendation, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final scanState = ref.watch(scanProvider);
    final baseUrl = ref.watch(hostProvider);

    final List<Widget> screens = [
      _buildHomeContent(user, scanState, baseUrl ?? ''),
      CameraScreen(isActive: _selectedIndex == 1),
      const HistoryScreen(),
      const AlertsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF0A0A0A),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: Colors.white24,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'DASHBOARD'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'SCAN'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'HISTORY'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber_rounded), label: 'ALERTS'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
        ],
      ),
    );
  }

  Widget _buildHomeContent(User? user, ScanState scanState, String baseUrl) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const Icon(Icons.grid_view_rounded, color: AppColors.accent),
        title: Text(
          'SOLARSCAN',
          style: GoogleFonts.orbitron(
            color: AppColors.accent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'WELCOME BACK',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 4),
            Text(
              'Hello, ${user?.name ?? 'Alex'}',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            
            // System Health Card
            _buildSystemHealthCard(),
            
            const SizedBox(height: 20),
            
            // Stats Row
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Panels', '742', Icons.solar_power_outlined, null)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Total Alerts', '09', Icons.warning_amber_rounded, Colors.redAccent)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Start New Scan Button
            _buildScanButton(scanState.isLoading),
            
            const SizedBox(height: 32),
            
            // Recent Scans
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Scans',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 2),
                  child: Text(
                    'VIEW ALL',
                    style: GoogleFonts.inter(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...scanState.scans.take(3).map((scan) => _buildRecentScanItem(scan, baseUrl)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealthCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Health',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'All arrays performing within optimal parameters.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      'PREDICTIVE OK',
                      style: GoogleFonts.inter(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: 0.92,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              ),
              const Text(
                '92%',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color? glowColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glowColor?.withValues(alpha: 0.3) ?? Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Icon(icon, color: glowColor ?? AppColors.accent, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : () => setState(() => _selectedIndex = 1),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'START NEW SCAN',
                    style: GoogleFonts.orbitron(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Initialize AI diagnostics',
                    style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
                : const Icon(Icons.qr_code_scanner_rounded, color: AppColors.accent, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScanItem(ScanResult scan, String baseUrl) {
    final imageUrl = '$baseUrl/backend_php/${scan.imagePath}';
    final timeAgo = _getTimeAgo(scan.createdAt);
    final isClean = scan.result.toLowerCase() == 'clean';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.white10),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: PX-8${scan.id}0${scan.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(timeAgo, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isClean ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isClean ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Text(
              scan.result.toUpperCase(),
              style: TextStyle(color: isClean ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return 'Yesterday';
  }
}
