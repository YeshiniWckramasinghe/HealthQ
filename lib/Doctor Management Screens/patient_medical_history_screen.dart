import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/doctor_service.dart';
import 'consultation_screen.dart';
import 'doctor_bottom_nav.dart';
import 'medical_attachment_viewer_dialog.dart';

class PatientMedicalHistoryScreen extends StatelessWidget {
  final DoctorPatientModel patient;

  const PatientMedicalHistoryScreen({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final consultations = patient.pastConsultations;
    final attachments = patient.pastAttachments;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // ================= TOP HEADER =================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                        'Patient Medical History',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary500,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.more_horiz,
                    color: AppColors.primary400,
                    size: 24,
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
                    const SizedBox(height: 18),

                    // Navigation Pills (Overview, Medical History, Appointments)
                    Row(
                      children: [
                        _buildNavPill(context, 'Overview', isActive: false, onTap: () => Navigator.of(context).pop()),
                        const SizedBox(width: 10),
                        _buildNavPill(context, 'Medical History', isActive: true),
                        const SizedBox(width: 10),
                        _buildNavPill(context, 'Appointments', isActive: false),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Card 1: Allergies
                    _buildSectionCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFDC2626),
                      title: 'Allergies',
                      children: patient.allergies.isNotEmpty
                          ? patient.allergies.map((a) => _buildBulletItem(a)).toList()
                          : [_buildBulletItem('No known drug allergies')],
                    ),
                    const SizedBox(height: 14),

                    // Card 2: Previous Conditions
                    _buildSectionCard(
                      icon: Icons.medical_services_outlined,
                      iconColor: AppColors.primary400,
                      title: 'Previous Conditions',
                      children: patient.previousConditions.isNotEmpty
                          ? patient.previousConditions.map((c) => _buildBulletItem(c)).toList()
                          : [_buildBulletItem('No past chronic conditions reported')],
                    ),
                    const SizedBox(height: 14),

                    // Card 3: Previous Visits
                    _buildSectionCard(
                      icon: Icons.calendar_today_outlined,
                      iconColor: AppColors.primary400,
                      title: 'Previous Visits',
                      children: patient.previousVisits.isNotEmpty
                          ? patient.previousVisits.map((v) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      v['date'] ?? '',
                                      style: const TextStyle(
                                        color: AppColors.primary400,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Text('  -  ', style: TextStyle(color: AppColors.gray400)),
                                    Expanded(
                                      child: Text(
                                        v['title'] ?? '',
                                        style: const TextStyle(
                                          color: AppColors.primary500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList()
                          : [_buildBulletItem('First recorded visit')],
                    ),
                    const SizedBox(height: 14),

                    // Card 4: Current Medications
                    _buildSectionCard(
                      icon: Icons.medication_outlined,
                      iconColor: AppColors.primary400,
                      title: 'Current Medications',
                      children: patient.currentMedications.isNotEmpty
                          ? patient.currentMedications.map((m) {
                              return _buildBulletItem('${m['name']} – ${m['dosage']}');
                            }).toList()
                          : [_buildBulletItem('None')],
                    ),
                    const SizedBox(height: 14),

                    // ================= CARD 5: PREVIOUS CONSULTATIONS & NOTES =================
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.history_edu_outlined, color: AppColors.primary400, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Previous Consultations & Clinical Notes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (consultations.isEmpty)
                            const Text(
                              'No prior consultation history recorded.',
                              style: TextStyle(color: AppColors.gray400, fontSize: 13),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: consultations.length,
                              separatorBuilder: (context, index) => const Divider(height: 24, color: Color(0xFFF1F5F9)),
                              itemBuilder: (context, idx) {
                                final cons = consultations[idx];
                                return Column(
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
                                    const SizedBox(height: 6),
                                    Text(
                                      'Diagnosis: ${cons.diagnosis}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cons.notes,
                                      style: const TextStyle(fontSize: 12, color: AppColors.gray500, height: 1.4),
                                    ),
                                    if (cons.prescription.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Rx: ${cons.prescription.replaceAll('\n', '; ')}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.primary500),
                                        ),
                                      ),
                                    ],
                                    if (cons.attachments.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: cons.attachments.map((att) {
                                          return InkWell(
                                            onTap: () => showMedicalAttachmentViewerDialog(context, att),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: att.badgeBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(att.icon, size: 12, color: att.badgeColor),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    att.name,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: att.badgeColor,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.open_in_new, size: 10, color: AppColors.gray400),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ================= CARD 6: PREVIOUS MEDICAL ATTACHMENTS & SCANS =================
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.folder_shared_outlined, color: AppColors.primary400, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Previous Attachments & Scans',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap any file to inspect radiographic scans, lab reports, or ECGs.',
                            style: TextStyle(fontSize: 12, color: AppColors.gray400),
                          ),
                          const SizedBox(height: 12),
                          if (attachments.isEmpty)
                            const Text(
                              'No historical attachments available for this patient.',
                              style: TextStyle(color: AppColors.gray400, fontSize: 13),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: attachments.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, idx) {
                                final att = attachments[idx];
                                return InkWell(
                                  onTap: () => showMedicalAttachmentViewerDialog(context, att),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: att.badgeBg,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(att.icon, color: att.badgeColor, size: 18),
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
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Button: Start Consultation
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ConsultationScreen(patient: patient),
                            ),
                          );
                        },
                        icon: const Icon(Icons.medical_services_outlined, size: 20),
                        label: const Text(
                          'Start Consultation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary400,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
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

  Widget _buildNavPill(
    BuildContext context,
    String label, {
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary400 : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary400 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            if (!isActive)
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
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.white : AppColors.gray500,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primary500, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
