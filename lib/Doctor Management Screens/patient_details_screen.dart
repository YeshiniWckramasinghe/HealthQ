import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/doctor_service.dart';
import 'patient_medical_history_screen.dart';
import 'consultation_screen.dart';
import 'doctor_bottom_nav.dart';
import 'medical_attachment_viewer_dialog.dart';

class PatientDetailsScreen extends StatefulWidget {
  final DoctorPatientModel patient;

  const PatientDetailsScreen({
    super.key,
    required this.patient,
  });

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  int _activeTabIndex = 0; // 0 = Overview, 1 = History, 2 = Appointments

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

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
                    'Patient Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500,
                    ),
                  ),
                ],
              ),
            ),

            // ================= SCROLLABLE CONTENT =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary400,
                            child: Text(
                              patient.initials,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${patient.gender} · ${patient.age} years',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.gray400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Patient ID: ${patient.id}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary400,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Navigation Tabs (Overview, History, Appointments)
                    Row(
                      children: [
                        _buildTabItem(0, 'Overview'),
                        const SizedBox(width: 24),
                        _buildTabItem(1, 'History'),
                        const SizedBox(width: 24),
                        _buildTabItem(2, 'Appointments'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_activeTabIndex == 0) ...[
                      // Personal Info Section
                      const Text(
                        'Personal Info',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
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
                          children: [
                            _buildInfoRow('Phone', patient.phone),
                            const Divider(height: 22, color: Color(0xFFF1F5F9)),
                            _buildInfoRow('Address', patient.address),
                            const Divider(height: 22, color: Color(0xFFF1F5F9)),
                            _buildInfoRow(
                              'Blood Group',
                              patient.bloodGroup,
                              isRedHighlight: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Medical History Collapsible Section
                      const Text(
                        'Medical History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
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
                          children: [
                            _buildHistoryItem(
                              title: 'Diabetes',
                              subtitle: 'Diagnosed in 2022',
                            ),
                            const Divider(height: 20, color: Color(0xFFF1F5F9)),
                            _buildHistoryItem(
                              title: 'Hypertension',
                              subtitle: 'Under medication since 2021',
                            ),
                            const Divider(height: 20, color: Color(0xFFF1F5F9)),
                            _buildHistoryItem(
                              title: 'Allergies',
                              subtitle: patient.allergies.isNotEmpty
                                  ? patient.allergies.join(', ')
                                  : 'No known drug allergies',
                            ),
                          ],
                        ),
                      ),
                    ] else if (_activeTabIndex == 1) ...[
                      // Comprehensive Medical History View with Past Consultations & Attachments
                      _buildHistoryPreview(),
                    ] else ...[
                      // Appointments View
                      _buildAppointmentsPreview(),
                    ],
                    const SizedBox(height: 24),

                    // Start Consultation Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ConsultationScreen(patient: patient),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary400,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Start Consultation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 2),
    );
  }

  Widget _buildTabItem(int index, String title) {
    final isSelected = _activeTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _activeTabIndex = index);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary400 : AppColors.gray400,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 32,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary400 : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isRedHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.gray400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isRedHighlight ? const Color(0xFFDC2626) : AppColors.primary500,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem({required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primary400,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.keyboard_arrow_down,
          color: Color(0xFF9CA3AF),
          size: 22,
        ),
      ],
    );
  }

  Widget _buildHistoryPreview() {
    final consultations = widget.patient.pastConsultations;
    final attachments = widget.patient.pastAttachments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Previous Consultations Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Previous Consultations (${consultations.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary500,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PatientMedicalHistoryScreen(patient: widget.patient),
                  ),
                );
              },
              child: const Text(
                'Full History',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary400,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (consultations.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No previous consultation records found.',
                style: TextStyle(color: AppColors.gray400, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: consultations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final cons = consultations[idx];
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cons.date,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary400,
                          ),
                        ),
                        Text(
                          cons.doctorName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cons.hospital,
                      style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                    ),
                    const Divider(height: 16, color: Color(0xFFF1F5F9)),

                    // Diagnosis
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Diagnosis: ',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.gray500),
                        ),
                        Expanded(
                          child: Text(
                            cons.diagnosis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Clinical Notes
                    Text(
                      cons.notes,
                      style: const TextStyle(fontSize: 12, color: AppColors.gray500, height: 1.4),
                    ),
                    const SizedBox(height: 8),

                    // Prescription
                    if (cons.prescription.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Prescription:\n${cons.prescription}',
                          style: const TextStyle(fontSize: 11, color: AppColors.gray500, height: 1.3),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Consultation Attachments
                    if (cons.attachments.isNotEmpty) ...[
                      const Text(
                        'Attached Reports & Scans:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gray400),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: cons.attachments.map((att) {
                          return InkWell(
                            onTap: () => showMedicalAttachmentViewerDialog(context, att),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: att.badgeBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(att.icon, size: 14, color: att.badgeColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    att.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: att.badgeColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.open_in_new, size: 12, color: AppColors.gray400),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 22),

        // 2. Previous Attachments Section
        Text(
          'Previous Medical Documents & Scans (${attachments.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary500,
          ),
        ),
        const SizedBox(height: 10),

        if (attachments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No previous attachments on file.',
                style: TextStyle(color: AppColors.gray400, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attachments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final att = attachments[idx];
              return InkWell(
                onTap: () => showMedicalAttachmentViewerDialog(context, att),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: att.badgeBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(att.icon, color: att.badgeColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              att.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${att.type} · ${att.date} · ${att.fileSize}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.visibility_outlined,
                        color: AppColors.primary400,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAppointmentsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today · ${widget.patient.time}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.patient.type} · ${widget.patient.room}',
                style: const TextStyle(color: AppColors.gray400, fontSize: 12),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF8E7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.patient.status,
              style: const TextStyle(
                color: Color(0xFFE29500),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
