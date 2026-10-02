import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'opd_header_banner.dart';
import 'opd_bottom_nav.dart';
import 'register_new_patient_screen.dart';
import 'manage_patient_screen.dart';

class PatientManagementHubScreen extends StatefulWidget {
  const PatientManagementHubScreen({super.key});

  @override
  State<PatientManagementHubScreen> createState() =>
      _PatientManagementHubScreenState();
}

class _PatientManagementHubScreenState
    extends State<PatientManagementHubScreen> {
  final TextEditingController _searchController = TextEditingController();

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
            title: 'Patient Management',
            nurseId: 'ID: NUR1002-021',
            department: 'General Medicine OPD',
            hospital: 'Government Hospital — Colombo',
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notice Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: OpdColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: OpdColors.primary300,
                        width: 1.2,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'OPD Registrar Notice',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: OpdColors.primary400,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Please verify Government National Identity Card (NIC) with extreme caution before registering new patients.',
                          style: TextStyle(
                            fontSize: 11,
                            color: OpdColors.textDark,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section: SEARCH PATIENT
                  const Text(
                    'SEARCH PATIENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: OpdColors.primary500,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: OpdColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: OpdColors.primary300.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Enter NIC, Phone or Patient Name...',
                        hintStyle: TextStyle(
                          fontSize: 12,
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
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ManagePatientScreen(searchNic: val.trim()),
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Item 1: Register New Patient
                  _buildNavCard(
                    title: 'Register New Patient',
                    subtitle: 'Create records for unregistered OPD patients.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterNewPatientScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Action Item 2: Manage Patient
                  _buildNavCard(
                    title: 'Manage Patient',
                    subtitle: 'Update existing demographic and medical info',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManagePatientScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Action Item 3: Patient Inquiry
                  _buildNavCard(
                    title: 'Patient Inquiry',
                    subtitle:
                        'Look up history, appointments, and prescriptions',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Patient Inquiry: Search by NIC above to inspect history.'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const OpdBottomNav(currentIndex: 0),
    );
  }

  Widget _buildNavCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: OpdColors.primary500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: OpdColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: OpdColors.primary300,
            ),
          ],
        ),
      ),
    );
  }
}
