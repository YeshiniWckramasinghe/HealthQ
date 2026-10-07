import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/doctor_service.dart';
import 'doctor_bottom_nav.dart';
import 'medical_attachment_viewer_dialog.dart';

class ConsultationScreen extends StatefulWidget {
  final DoctorPatientModel patient;

  const ConsultationScreen({
    super.key,
    required this.patient,
  });

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  late final TextEditingController _notesController;
  late final TextEditingController _prescriptionController;
  String _selectedDiagnosis = 'Type 2 Diabetes Mellitus (Follow up)';
  final List<MedicalAttachmentModel> _attachedFiles = [];

  final List<String> _diagnoses = [
    'Type 2 Diabetes Mellitus (Follow up)',
    'Essential Hypertension',
    'Acute Upper Respiratory Tract Infection',
    'Dyslipidemia / High Cholesterol',
    'General Physical Weakness & Fatigue',
    'Routine Health Examination',
  ];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.patient.consultationNotes.isNotEmpty
          ? widget.patient.consultationNotes
          : 'Patient complains of fatigue and high blood sugar levels. Advised lifestyle changes and continue medication.',
    );
    _prescriptionController = TextEditingController(
      text: widget.patient.prescription.isNotEmpty
          ? widget.patient.prescription
          : '1. Metformin 500mg – 1-0-1 (after meals)\n2. Amlodipine 5mg – 1-0-0\n3. Atorvastatin 20mg – 1-0-0',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  void _showAddAttachmentModal() {
    String selectedType = 'X-ray';
    final nameController = TextEditingController(text: 'Chest_XRay_PA.png');

    final presets = [
      {'name': 'Chest_XRay_PA_View.png', 'type': 'X-ray', 'size': '3.8 MB', 'findings': 'PA View: Normal cardiothoracic ratio. No focal infiltration or effusion.'},
      {'name': 'Full_Blood_Count_Report.pdf', 'type': 'Lab Report', 'size': '1.4 MB', 'findings': 'Hemoglobin: 13.8 g/dL. Total WBC: 7,200 /mcL. Platelet count normal.'},
      {'name': 'HbA1c_Blood_Test_Panel.pdf', 'type': 'Lab Report', 'size': '1.1 MB', 'findings': 'HbA1c: 7.2%. Fasting Plasma Glucose: 138 mg/dL. Renal function normal.'},
      {'name': 'Abdominal_Ultrasound_Scan.jpg', 'type': 'Scan Report', 'size': '4.2 MB', 'findings': 'Ultrasound Abdomen: Grade 1 fatty liver changes. Kidneys normal.'},
      {'name': 'Resting_12Lead_ECG_Scan.pdf', 'type': 'Lab Report', 'size': '1.5 MB', 'findings': 'Resting ECG: Normal sinus rhythm at 76 bpm. No acute ST changes.'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attach Medical Document',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary500,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.gray400),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Presets:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((p) {
                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            nameController.text = p['name']!;
                            selectedType = p['type']!;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            p['name']!,
                            style: const TextStyle(fontSize: 12, color: AppColors.primary500),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Document Type',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.gray500),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'X-ray', child: Text('X-ray')),
                          DropdownMenuItem(value: 'Lab Report', child: Text('Lab Report')),
                          DropdownMenuItem(value: 'Scan Report', child: Text('Scan Report (Ultrasound / CT / MRI)')),
                          DropdownMenuItem(value: 'Other', child: Text('Other Medical Document')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'File Name',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.gray500),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'e.g. Chest_XRay_PA.png',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final now = DateTime.now();
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                        final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

                        final matchedPreset = presets.firstWhere(
                          (p) => p['name'] == nameController.text.trim(),
                          orElse: () => {
                            'name': nameController.text.trim(),
                            'type': selectedType,
                            'size': '2.5 MB',
                            'findings': 'Attached during consultation for clinical review.',
                          },
                        );

                        final newAttachment = MedicalAttachmentModel(
                          id: 'ATT-${now.millisecondsSinceEpoch}',
                          name: nameController.text.trim().isNotEmpty
                              ? nameController.text.trim()
                              : 'Medical_Document_${now.millisecondsSinceEpoch}.pdf',
                          type: selectedType,
                          date: dateStr,
                          fileSize: matchedPreset['size'] ?? '2.5 MB',
                          findings: matchedPreset['findings'] ?? 'Clinical examination document.',
                        );

                        setState(() {
                          _attachedFiles.add(newAttachment);
                        });

                        Navigator.of(ctx).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${newAttachment.name} attached successfully.'),
                            backgroundColor: AppColors.primary400,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Add Attachment', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary400,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onCompleteConsultation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF27AE60)),
            SizedBox(width: 10),
            Text('Complete Consultation'),
          ],
        ),
        content: Text(
          'Mark consultation for ${widget.patient.name} as Completed?\n'
          'Notes, diagnosis, prescription, and ${_attachedFiles.length} attachment(s) will be saved to medical history. '
          'The queue will automatically advance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();

              DoctorService.instance.completeConsultation(
                patientId: widget.patient.id,
                notes: _notesController.text.trim(),
                diagnosis: _selectedDiagnosis,
                prescription: _prescriptionController.text.trim(),
                attachments: _attachedFiles,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Consultation completed for ${widget.patient.name}. Queue advanced.',
                  ),
                  backgroundColor: const Color(0xFF007471),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 3),
                ),
              );

              // Return to previous screen or queue
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary400,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

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
                        'Consultation',
                        style: TextStyle(
                          fontSize: 20,
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
                    // Top Row with 2 Cards
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Patient summary card
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(14),
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
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primary400,
                                  child: Text(
                                    patient.initials,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patient.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.primary500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${patient.gender} · ${patient.age} years',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.gray400,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Patient ID: ${patient.id}',
                                        style: const TextStyle(
                                          fontSize: 11,
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
                        ),
                        const SizedBox(width: 12),

                        // Right: Appt Time Card
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(14),
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
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: AppColors.primary400,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Appt Time',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary400,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  patient.time,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  '20 Sep 2025',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.gray400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 1: Consultation Notes
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
                          const Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                color: AppColors.primary400,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Consultation Notes',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Notes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _notesController,
                                  maxLines: 4,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary500,
                                    height: 1.4,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${_notesController.text.length}/500',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.gray400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Card 2: Diagnosis
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
                          const Row(
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                color: AppColors.primary400,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Diagnosis',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedDiagnosis,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.gray400,
                                ),
                                items: _diagnoses.map((d) {
                                  return DropdownMenuItem<String>(
                                    value: d,
                                    child: Text(
                                      d,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedDiagnosis = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Card 3: Prescription / Medication
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
                          const Row(
                            children: [
                              Icon(
                                Icons.medication_outlined,
                                color: AppColors.primary400,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Prescription / Medication',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prescription / Medication',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _prescriptionController,
                                  maxLines: 4,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary500,
                                    height: 1.4,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${_prescriptionController.text.length}/1000',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.gray400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ================= CARD 4: CONSULTATION ATTACHMENTS =================
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.attach_file_rounded,
                                    color: AppColors.primary400,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Consultation Attachments',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary500,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: _showAddAttachmentModal,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Attach', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE6F6F4),
                                  foregroundColor: AppColors.primary400,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Attach X-rays, medical reports, or scan images to this session.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray400,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_attachedFiles.isEmpty)
                            InkWell(
                              onTap: _showAddAttachmentModal,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFCBD5E1),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  children: const [
                                    Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 32,
                                      color: AppColors.primary400,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Tap to upload or attach medical files',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary500,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Supports X-rays, Lab PDFs, Ultrasound/CT Scans',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.gray400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _attachedFiles.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, idx) {
                                final file = _attachedFiles[idx];
                                return Container(
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
                                          color: file.badgeBg,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          file.icon,
                                          color: file.badgeColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              file.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${file.type} · ${file.fileSize}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.gray400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.primary400),
                                        tooltip: 'Preview Attachment',
                                        onPressed: () => showMedicalAttachmentViewerDialog(context, file),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18, color: Color(0xFFDC2626)),
                                        tooltip: 'Remove',
                                        onPressed: () {
                                          setState(() => _attachedFiles.removeAt(idx));
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Card 5: Complete Consultation
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
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: Color(0xFF27AE60),
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Complete Consultation',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _attachedFiles.isEmpty
                                ? 'This patient will be marked as Completed and the queue will move to the next patient.'
                                : 'This patient and ${_attachedFiles.length} attached document(s) will be saved to history and the queue will move to the next patient.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray400,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _onCompleteConsultation,
                              icon: const Icon(Icons.check, size: 20),
                              label: const Text(
                                'Complete Consultation',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary400,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
}
