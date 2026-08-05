import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/host_provider.dart';
import '../auth/login_screen.dart';
import '../auth/host_setup_screen.dart';
import '../home/home_screen.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Version Info
                  Text(
                    'SOLARSCAN_OS v.2.4.0',
                    style: GoogleFonts.orbitron(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  const Spacer(),

                  // Logo and Frame
                  _buildLogo(),

                  const SizedBox(height: 24),

                  // Subtitle
                  Text(
                    'Smart solar panel inspection\npowered by AI',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Diagnostic Protocol
                  _buildProtocolSection(),

                  const Spacer(),

                  // Stats Card
                  _buildStatsCard(),

                  const SizedBox(height: 24),

                  // Get Started Button
                  _buildGetStartedButton(context, ref),

                  const SizedBox(height: 32),

                  // Bottom Labels
                  _buildBottomLabels(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Image.asset(
        'assets/images/app_logo.png',
        height: 180,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildProtocolSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 1, color: Colors.white12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'DIAGNOSTIC PROTOCOL ACTIVE',
                style: GoogleFonts.orbitron(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ),
            Expanded(child: Container(height: 1, color: Colors.white12)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Avatars (simplified)
          SizedBox(
            width: 60,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[800],
                  child: const Icon(Icons.person, size: 20, color: Colors.white54),
                ),
                Positioned(
                  left: 20,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.accent,
                    child: const Icon(Icons.radar, size: 18, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACTIVE SESSIONS',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '1,240 Sites',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Monitored',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            height: 40,
            width: 1,
            color: Colors.white12,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ACCURACY',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '99.8%',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          final authState = ref.read(authProvider);
          final host = ref.read(hostProvider);

          Widget nextScreen;
          if (host == null) {
            nextScreen = const HostSetupScreen();
          } else if (authState.user == null) {
            nextScreen = const LoginScreen();
          } else {
            nextScreen = const HomeScreen();
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => nextScreen),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GET STARTED',
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _bottomLabel('LIDAR SCANNING'),
        _bottomLabel('THERMAL IMAGING'),
        _bottomLabel('ANOMALY DETECTION'),
      ],
    );
  }

  Widget _bottomLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: Colors.white24,
        fontSize: 8,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }
}

class CornerBracketPainter extends CustomPainter {
  final Color color;
  CornerBracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double length = 25;

    // Top Left
    canvas.drawLine(const Offset(0, 0), const Offset(length, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, length), paint);

    // Top Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - length, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - length), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - length, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - length), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
