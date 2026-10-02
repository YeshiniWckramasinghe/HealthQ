import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'opd_header_banner.dart';
import 'opd_bottom_nav.dart';
import 'patient_management_hub_screen.dart';
import 'appointments_list_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _todayDoctors = [
    {
      'name': 'Dr. S. Perera',
      'specialty': 'Cardiology • 08:00-12:00',
      'queue': '34',
    },
    {
      'name': 'Dr. R. Fernando',
      'specialty': 'General Med. • 09:00-13:00',
      'queue': '52',
    },
    {
      'name': 'Dr. A. Wijesuriya',
      'specialty': 'Pediatrics • 08:30-12:30',
      'queue': '28',
    },
    {
      'name': 'Dr. K. Jayasinghe',
      'specialty': 'Neurology • 10:00-14:00',
      'queue': '19',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OpdColors.primary100,
      body: Column(
        children: [
          // Header banner with hospital corridor photo
          const OpdHeaderBanner(
            title: 'Good Morning, Nurse',
            nurseId: 'ID: NUR1002-021',
            department: 'General Medicine OPD',
            hospital: 'Government Hospital — Colombo',
          ),

          // Main body content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: OpdColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: OpdColors.primary300.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: OpdColors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search doctors, specialties...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: OpdColors.textMuted,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: OpdColors.primary300,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Quick Action Hub (3 Columns)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.person_search_outlined,
                          title: 'Patient\nManagement',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PatientManagementHubScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.calendar_month_outlined,
                          title: 'Appointments',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AppointmentsListScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.format_list_numbered_outlined,
                          title: 'Queue\nManagement',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Queue Management selected'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // TODAY'S OPD Section Header
                  const Text(
                    "TODAY'S OPD",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: OpdColors.primary500,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Doctor Cards
                  ..._todayDoctors.map((doc) => _buildDoctorCard(doc)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const OpdBottomNav(currentIndex: 0),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: OpdColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: OpdColors.primary200.withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: OpdColors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: OpdColors.primary300,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: OpdColors.primary500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, String> doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: OpdColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: OpdColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: OpdColors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['name']!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: OpdColors.primary500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  doc['specialty']!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: OpdColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: OpdColors.primary100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: OpdColors.primary200.withValues(alpha: 0.7),
                width: 1,
              ),
            ),
            child: Text(
              doc['queue']!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: OpdColors.primary400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
