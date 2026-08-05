import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';


class WorkHistoryScreen extends StatelessWidget {
  const WorkHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'WORK HISTORY',
          style: GoogleFonts.orbitron(
            color: AppColors.accent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildMonthHeader('MAY 2026'),
          _buildHistoryItem('Inspection Session', 'Sector-B / Arrays 1-12', 'Today, 10:24 AM', true),
          _buildHistoryItem('Equipment Calibration', 'Main Processing Node', 'Today, 08:15 AM', false),
          const SizedBox(height: 24),
          _buildMonthHeader('APRIL 2026'),
          _buildHistoryItem('Monthly Audit', 'Full Site Survey', 'Apr 28, 09:00 AM', true),
          _buildHistoryItem('Maintenance Relay', 'Inverter Node 7', 'Apr 25, 14:30 PM', false),
          _buildHistoryItem('Emergency Scan', 'Sector-A / Grid 4', 'Apr 22, 11:20 AM', true),
          _buildHistoryItem('System Training', 'HQ Training Center', 'Apr 15, 10:00 AM', false),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(String month) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        month,
        style: GoogleFonts.orbitron(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
      ),
    );
  }

  Widget _buildHistoryItem(String title, String location, String time, bool isScan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isScan ? AppColors.accent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isScan ? Icons.qr_code_scanner_rounded : Icons.build_circle_outlined,
              color: isScan ? AppColors.accent : Colors.white54,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(location, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(
            time.split(',').last.trim(),
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
