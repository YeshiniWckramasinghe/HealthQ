import 'package:flutter/material.dart';
import 'opd_bottom_nav.dart';

class OpdDoctorProfileScreen extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final String? hospital;

  const OpdDoctorProfileScreen({
    super.key,
    required this.doctor,
    this.hospital,
  });

  static const Color headerTeal = Color(0xFF006760);
  static const Color primaryTeal = Color(0xFF007A78);
  static const Color bgMint = Color(0xFFF3F8F7);

  @override
  Widget build(BuildContext context) {
    final name = (doctor['name'] ?? 'Doctor Name').toString();
    final speciality = (doctor['speciality'] ?? doctor['department'] ?? 'General Medicine').toString();
    final designation = (doctor['designation'] ?? 'Consultant Specialist').toString();
    final regNo = (doctor['regNo'] ?? 'SLMC-10001').toString();
    final phone = (doctor['phone'] ?? '011-234-5678').toString();
    final email = (doctor['email'] ?? 'doctor@govhosp.lk').toString();
    final opdDays = (doctor['opdDays'] ?? 'Daily').toString();
    final session = (doctor['session'] ?? '08:30 - 13:00').toString();
    final room = (doctor['room'] ?? 'Room 02').toString();
    final hospName = hospital ?? (doctor['hospital'] ?? 'City General Hospital').toString();

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
              'Doctor Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Doctor Profile & OPD Schedule',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Doctor Profile Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFBAE6FD), width: 2),
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        color: Color(0xFF0284C7),
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E2C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      designation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4F1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBCE3DC)),
                      ),
                      child: Text(
                        speciality,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. OPD Clinic Schedule Card
              const Text(
                'OPD CLINIC SCHEDULE',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: primaryTeal,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Clinic Days', opdDays, isHighlight: true),
                    const Divider(height: 18),
                    _buildInfoRow('Session Hours', session),
                    const Divider(height: 18),
                    _buildInfoRow('Room Assignment', room),
                    const Divider(height: 18),
                    _buildInfoRow('Hospital', hospName),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 3. Credentials & Contact
              const Text(
                'CREDENTIALS & CONTACT',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: primaryTeal,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('SLMC Registration', regNo),
                    const Divider(height: 18),
                    _buildInfoRow('Phone', phone),
                    const Divider(height: 18),
                    _buildInfoRow('Email', email),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: OpdBottomNav(
        currentIndex: 0,
        hospital: hospital,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? primaryTeal : const Color(0xFF0F2E2C),
          ),
        ),
      ],
    );
  }
}
