import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const Icon(Icons.grid_view_rounded, color: AppColors.accent),
        title: Text(
          'SYSTEM ALERTS',
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
          children: [
            const SizedBox(height: 16),
            _buildNetworkStatusCard(),
            const SizedBox(height: 24),
            _buildAlertCard(
              context,
              title: 'Critical Crack',
              time: '2m ago',
              details: 'PANEL_ID: #8829-X • 104°C',
              location: 'Section 4G • Array Alpha',
              priority: 'CRITICAL',
              isActive: true,
              icon: Icons.thermostat_outlined,
            ),
            _buildAlertCard(
              context,
              title: 'Soiling Accumulation',
              time: '14m ago',
              details: 'PANEL_ID: #4401-K • -12% Efficiency',
              location: 'Section 2A • Array Gamma',
              priority: 'HIGH',
              isActive: false,
              icon: Icons.flash_on_outlined,
            ),
            _buildAlertCard(
              context,
              title: 'Connection Lag',
              time: '48m ago',
              details: 'GATEWAY: #GT-09 • Intermittent',
              location: 'Comm Hub • North Bank',
              priority: 'MEDIUM',
              isActive: false,
              icon: Icons.wifi_off_rounded,
            ),
            _buildAlertCard(
              context,
              title: 'Diode Failure',
              time: '1h ago',
              details: 'PANEL_ID: #1105-B • 88°C',
              location: 'Section 1C • Array Delta',
              priority: 'HIGH',
              isActive: false,
              icon: Icons.thermostat_outlined,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NETWORK STATUS',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '9 Active Alerts',
                  style: GoogleFonts.inter(
                    color: AppColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'HIGH PRIORITY ACTION REQUIRED',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.yellow,
            size: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    BuildContext context, {
    required String title,
    required String time,
    required String details,
    required String location,
    required String priority,
    required bool isActive,
    required IconData icon,
  }) {
    Color priorityColor;
    if (priority == 'CRITICAL') {
      priorityColor = const Color(0xFFEF5350);
    } else if (priority == 'HIGH') {
      priorityColor = const Color(0xFF29B6F6);
    } else {
      priorityColor = const Color(0xFFFFA726);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? priorityColor.withValues(alpha: 0.3) : Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Small Preview Image Placeholder
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(Icons.image_outlined, color: Colors.white24),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        priority,
                        style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            color: priority == 'CRITICAL' ? Colors.red : Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.grid_on_outlined, color: Colors.white24, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            details,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                location,
                style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: () => _showAlertDetails(
                    context,
                    title: title,
                    details: details,
                    location: location,
                    priority: priority,
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isActive ? AppColors.accent : Colors.transparent,
                    side: BorderSide(color: isActive ? AppColors.accent : Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    'VIEW DETAILS',
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  void _showAlertDetails(
    BuildContext context, {
    required String title,
    required String details,
    required String location,
    required String priority,
  }) {
    Color priorityColor;
    if (priority == 'CRITICAL') {
      priorityColor = const Color(0xFFEF5350);
    } else if (priority == 'HIGH') {
      priorityColor = const Color(0xFF29B6F6);
    } else {
      priorityColor = const Color(0xFFFFA726);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: priorityColor.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: priorityColor),
            const SizedBox(width: 12),
            Text(
              'ALERT DETAILS',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildDetailRow('TYPE', title),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDetailRow('PRIORITY', priority, color: priorityColor),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDetailRow('DATA', details),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDetailRow('LOCATION', location),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'RECOMMENDED ACTION',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              priority == 'CRITICAL'
                  ? 'Immediate onsite inspection required. Shut down array if temperature exceeds 110°C.'
                  : priority == 'HIGH'
                      ? 'Schedule maintenance within 24 hours. Monitor efficiency levels closely.'
                      : 'Non-critical issue. Add to routine maintenance log for next scheduled visit.',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'ACKNOWLEDGE',
                style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
