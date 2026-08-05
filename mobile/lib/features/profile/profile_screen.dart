import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'security_screen.dart';
import 'work_history_screen.dart';
import 'support_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.accent),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Profile Image with Glow
            _buildProfileAvatar(),
            const SizedBox(height: 24),
            // Name and Title with Edit Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 40), // Spacer for balance
                Text(
                  user?.name.toUpperCase() ?? 'ALEX',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: AppColors.accent, size: 28),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'FIELD INSPECTOR',
              style: GoogleFonts.orbitron(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 40),
            // Stats Row
            _buildTotalScansCard(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _buildMiniStatCard('ANOMALIES', '42', 'CRITICAL', Colors.redAccent.withOpacity(0.5))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAccuracyCard()),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Menu Options
            _buildMenuOption(
              Icons.security_rounded, 
              'Account Security', 
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SecurityScreen())),
            ),
            _buildMenuOption(
              Icons.history_rounded, 
              'Work History', 
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkHistoryScreen())),
            ),
            _buildMenuOption(
              Icons.headset_mic_outlined, 
              'Help & Support', 
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen())),
            ),
            const SizedBox(height: 40),
            // Logout Button
            _buildLogoutButton(ref),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 60,
            backgroundImage: AssetImage('assets/images/profile_alex.png'),
            backgroundColor: Color(0xFF121212),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified_rounded, color: Colors.black, size: 18),
        ),
      ],
    );
  }

  Widget _buildTotalScansCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL SCANS',
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1,240',
                style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: AppColors.accent.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, String subLabel, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subLabel,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACCURACY',
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '99.8%',
            style: GoogleFonts.inter(
              color: AppColors.accent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.998,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(color: AppColors.accent.withOpacity(0.5), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 20),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: OutlinedButton.icon(
          onPressed: () => ref.read(authProvider.notifier).logout(),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: Text(
            'LOGOUT',
            style: GoogleFonts.orbitron(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}
