import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/booking_service.dart';
import '../services/staff_auth_service.dart';
import 'opd_bottom_nav.dart';

class OpdNotificationItem {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final DateTime timestamp;
  final String type;
  final String? token;
  final bool isRead;

  OpdNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.timestamp,
    required this.type,
    this.token,
    this.isRead = false,
  });
}

class OpdNotificationsScreen extends StatefulWidget {
  final String? hospital;
  final String? hospitalCode;
  final String? nurseId;
  final String? nurseName;
  final String? department;
  final List<OpdNotificationItem>? initialNotifications;

  const OpdNotificationsScreen({
    super.key,
    this.hospital,
    this.hospitalCode,
    this.nurseId,
    this.nurseName,
    this.department,
    this.initialNotifications,
  });

  @override
  State<OpdNotificationsScreen> createState() => _OpdNotificationsScreenState();
}

class _OpdNotificationsScreenState extends State<OpdNotificationsScreen> {
  static const Color headerTeal = Color(0xFF006760);
  static const Color primaryTeal = Color(0xFF007A78);
  static const Color bgMint = Color(0xFFF3F8F7);

  final List<OpdNotificationItem> _liveNotifications = [];
  bool _isLoading = true;

  String get _effectiveHospital {
    if (widget.hospital != null && widget.hospital!.trim().isNotEmpty) {
      return widget.hospital!.trim();
    }
    if (StaffAuthService.instance.currentStaff?.hospital != null &&
        StaffAuthService.instance.currentStaff!.hospital.trim().isNotEmpty) {
      return StaffAuthService.instance.currentStaff!.hospital.trim();
    }
    return 'Government Hospital Colombo';
  }

  String get _effectiveHospitalCode {
    if (widget.hospitalCode != null && widget.hospitalCode!.trim().isNotEmpty) {
      return widget.hospitalCode!.trim();
    }
    return Hospital.resolveHospitalCode(_effectiveHospital);
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (widget.initialNotifications != null) {
      setState(() {
        _liveNotifications.clear();
        _liveNotifications.addAll(widget.initialNotifications!);
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<OpdNotificationItem> dynamicItems = [];
      final now = DateTime.now();

      try {
        final appointmentsSnap = await FirebaseFirestore.instance
            .collection('appointments')
            .orderBy('updatedAt', descending: true)
            .limit(10)
            .get()
            .timeout(const Duration(seconds: 4));

        for (final doc in appointmentsSnap.docs) {
          final d = doc.data();
          final hosp = (d['hospitalName'] ?? d['hospital'] ?? '').toString();
          final hospCode = (d['hospitalIdentificationNo'] ?? d['hospitalCode'] ?? '').toString();

          if (hosp.isNotEmpty &&
              !Hospital.matchesHospital(
                targetHospital: _effectiveHospital,
                targetCode: _effectiveHospitalCode,
                itemHospital: hosp,
                itemCode: hospCode,
              )) {
            continue;
          }

          final patientName = (d['patientName'] ?? d['name'] ?? 'Patient').toString();
          final status = (d['status'] ?? 'Waiting').toString();
          final token = (d['token'] ?? 'T-001').toString();
          final doctor = (d['doctorName'] ?? d['doctor'] ?? 'Doctor').toString();

          dynamicItems.add(
            OpdNotificationItem(
              id: doc.id,
              title: '$token Status Update: $status',
              message: 'Patient $patientName was updated to "$status" for $doctor.',
              timeAgo: 'Just now',
              timestamp: now,
              type: 'queue',
              token: token,
              isRead: false,
            ),
          );
        }
      } catch (e) {
        debugPrint('Firestore live notifications stream note: $e');
      }

      if (dynamicItems.isEmpty) {
        dynamicItems.addAll(_wireframeDefaultNotifications);
      }

      if (mounted) {
        setState(() {
          _liveNotifications.clear();
          _liveNotifications.addAll(dynamicItems);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _liveNotifications.clear();
          _liveNotifications.addAll(_wireframeDefaultNotifications);
          _isLoading = false;
        });
      }
    }
  }

  List<OpdNotificationItem> get _wireframeDefaultNotifications => [
        OpdNotificationItem(
          id: 'notif_01',
          title: 'Queue Call: T-003 is Next',
          message: 'Patient Suresh Jayawardena has been called for General Medicine OPD (Dr. R. Fernando).',
          timeAgo: '2m ago',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          type: 'queue',
          token: 'T-003',
          isRead: false,
        ),
        OpdNotificationItem(
          id: 'notif_02',
          title: 'Doctor Shift Schedule Notice',
          message: 'Dr. S. Perera (Cardiology) is in clinic Room 04. Estimated 18 patients on waitlist.',
          timeAgo: '15m ago',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          type: 'doctor',
          isRead: false,
        ),
        OpdNotificationItem(
          id: 'notif_03',
          title: 'Urgent Lab Report Ready',
          message: 'ECG report available for Token T-001 (Kamal Perera). Ready for physician review.',
          timeAgo: '28m ago',
          timestamp: DateTime.now().subtract(const Duration(minutes: 28)),
          type: 'urgent',
          token: 'T-001',
          isRead: true,
        ),
        OpdNotificationItem(
          id: 'notif_04',
          title: 'Patient No-Show Notice',
          message: 'Token T-005 (Rohan Wickrama) marked absent after 3 consecutive token calls.',
          timeAgo: '45m ago',
          timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
          type: 'queue',
          token: 'T-005',
          isRead: true,
        ),
        OpdNotificationItem(
          id: 'notif_05',
          title: 'OPD Daily System Dispatch',
          message: 'Morning clinic shift commenced at $_effectiveHospital. All triage stations online.',
          timeAgo: '2h ago',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          type: 'info',
          isRead: true,
        ),
      ];

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFDC2626);
      case 'queue':
        return primaryTeal;
      case 'doctor':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFFD97706);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'urgent':
        return Icons.warning_amber_rounded;
      case 'queue':
        return Icons.format_list_numbered_rounded;
      case 'doctor':
        return Icons.medical_services_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgMint,
      appBar: AppBar(
        backgroundColor: headerTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Real-Time Clinic & Patient Dispatch Feed',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Notifications',
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryTeal,
          onRefresh: _loadNotifications,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryTeal))
              : _liveNotifications.isEmpty
                  ? const Center(
                      child: Text(
                        'No notifications at this time.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _liveNotifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _liveNotifications[index];
                        final typeColor = _getTypeColor(item.type);
                        final typeIcon = _getTypeIcon(item.type);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: item.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBCE3DC),
                              width: item.isRead ? 1 : 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type Badge Icon
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  typeIcon,
                                  color: typeColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                              color: const Color(0xFF0F2E2C),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          item.timeAgo,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.message,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                        height: 1.35,
                                      ),
                                    ),
                                    if (item.token != null) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                        ),
                                        child: Text(
                                          'Token: ${item.token}',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: primaryTeal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
      bottomNavigationBar: OpdBottomNav(
        currentIndex: 3,
        hospital: _effectiveHospital,
      ),
    );
  }
}
