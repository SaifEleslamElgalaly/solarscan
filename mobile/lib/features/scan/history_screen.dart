import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/scan_provider.dart';
import '../../providers/host_provider.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  String _activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final baseUrl = ref.watch(hostProvider);

    final filteredScans = scanState.scans.where((scan) {
      final matchesSearch = _searchQuery.isEmpty || 
          'SN-${scan.id}'.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesFilter = true;
      if (_activeFilter == 'Clean') {
        matchesFilter = scan.result.toLowerCase() == 'clean';
      } else if (_activeFilter == 'Issues') {
        matchesFilter = scan.result.toLowerCase() != 'clean';
      }
      
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const Icon(Icons.grid_view_rounded, color: AppColors.accent),
        title: Text(
          'SCAN HISTORY',
          style: GoogleFonts.orbitron(
            color: AppColors.accent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.accent),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search Panel ID (e.g. SN-8829)',
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.search, color: Colors.white24),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 12),
                _buildFilterChip('Clean'),
                const SizedBox(width: 12),
                _buildFilterChip('Issues'),
                const SizedBox(width: 12),
                _buildFilterChip('Recent'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // History List
          Expanded(
            child: scanState.isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : filteredScans.isEmpty
                ? const Center(child: Text('No scans found', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredScans.length,
                    itemBuilder: (context, index) {
                      return _buildScanCard(filteredScans[index], baseUrl!);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.accent : Colors.white10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isActive ? Colors.black : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildScanCard(ScanResult scan, String baseUrl) {
    final dateStr = DateFormat('MMMM d, y').format(scan.createdAt);
    final imageUrl = '$baseUrl/backend_php/${scan.imagePath}';
    
    Color statusColor;
    String statusText = scan.result.toUpperCase();
    
    if (statusText == 'CLEAN') {
      statusColor = const Color(0xFF66BB6A); // Green
    } else if (statusText == 'DUST') {
      statusColor = const Color(0xFF29B6F6); // Blue
    } else {
      statusColor = const Color(0xFFEF5350); // Red
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.white10,
                    child: const Icon(Icons.image_not_supported, color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Text Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'SN-${scan.id}0${scan.id}-X${scan.id}', // Fake ID pattern to match image
                        style: GoogleFonts.inter(
                          color: AppColors.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white24, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'SECTOR ${scan.id}-A • ${statusText == 'CLEAN' ? 'VERIFIED' : 'MAINTENANCE'}',
                      style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
