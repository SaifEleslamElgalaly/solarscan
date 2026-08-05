import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';


class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

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
          'HELP & SUPPORT',
          style: GoogleFonts.orbitron(
            color: AppColors.accent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildSupportHero(),
            const SizedBox(height: 32),
            _buildSupportAction(Icons.chat_bubble_outline_rounded, 'Live Support', 'Start a conversation with an agent'),
            _buildSupportAction(Icons.mail_outline_rounded, 'Email Support', 'support@solarscan.ai'),
            _buildSupportAction(Icons.help_outline_rounded, 'Frequently Asked Questions', 'Quick answers to common issues'),
            _buildSupportAction(Icons.menu_book_outlined, 'Inspector Manual', 'System operational guidelines'),
            const SizedBox(height: 40),
            _buildAppInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF121212), AppColors.accent.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(Icons.headset_mic_rounded, color: AppColors.accent, size: 48),
          const SizedBox(height: 16),
          Text(
            'HOW CAN WE HELP?',
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Our technical team is available 24/7 for system assistance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportAction(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accent, size: 24),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white24, size: 18),
        onTap: () {},
      ),
    );
  }

  Widget _buildAppInfo() {
    return Column(
      children: [
        const Divider(color: Colors.white10, height: 40),
        const Text('SOLARSCAN MOBILE V2.4.0', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 4),
        const Text('STABLE BUILD - PRODUCTION ENVIRONMENT', style: TextStyle(color: Colors.white10, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
