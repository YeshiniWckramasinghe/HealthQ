import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/doctor_service.dart';
import 'request_details_screen.dart';
import 'doctor_bottom_nav.dart';

class AvailabilityRequestsScreen extends StatefulWidget {
  const AvailabilityRequestsScreen({super.key});

  @override
  State<AvailabilityRequestsScreen> createState() => _AvailabilityRequestsScreenState();
}

class _AvailabilityRequestsScreenState extends State<AvailabilityRequestsScreen> {
  final DoctorService _service = DoctorService.instance;
  String _selectedFilter = 'All'; // 'All', 'Pending', 'Approved'

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  List<AvailabilityRequestModel> get _filteredRequests {
    final list = _service.requests;
    return list.where((r) {
      if (_selectedFilter == 'Pending') return r.status.toLowerCase() == 'pending';
      if (_selectedFilter == 'Approved') return r.status.toLowerCase() == 'approved';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // ================= TOP HEADER =================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.primary400,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Availability Requests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500,
                    ),
                  ),
                ],
              ),
            ),

            // ================= FILTER CHIPS =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('All', 'All'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Pending', 'Pending'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Approved', 'Approved'),
                ],
              ),
            ),

            // ================= REQUESTS LIST =================
            Expanded(
              child: _filteredRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: AppColors.gray300),
                          const SizedBox(height: 12),
                          const Text(
                            'No availability requests found',
                            style: TextStyle(
                              color: AppColors.gray500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      itemCount: _filteredRequests.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final req = _filteredRequests[index];
                        return _buildRequestCard(req);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 3),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary400 : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary400 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.gray500,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(AvailabilityRequestModel req) {
    Color badgeBg;
    Color badgeText;

    switch (req.status.toLowerCase()) {
      case 'approved':
        badgeBg = const Color(0xFFD1FAE5);
        badgeText = const Color(0xFF047857);
        break;
      case 'rejected':
        badgeBg = const Color(0xFFFEE2E2);
        badgeText = const Color(0xFFDC2626);
        break;
      default:
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Date & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                req.targetDate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  req.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Requested Time & Status
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.gray400,
              ),
              const SizedBox(width: 8),
              Text(
                '${req.timeSlot} · ${req.requestedStatus} Requested',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Bottom Row: Submitted Date & View Details Link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Submitted: ${req.submittedTime.split(',').first}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gray400,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RequestDetailsScreen(request: req),
                    ),
                  );
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
