import 'package:flutter/material.dart';

/// Data model representing a medical document attachment (X-ray, scan, lab report, etc.)
class MedicalAttachmentModel {
  final String id;
  final String name; // e.g. "Chest_XRay_PA.png", "HbA1c_Blood_Test.pdf"
  final String type; // 'X-ray', 'Lab Report', 'Scan Report', 'Prescription', 'Other'
  final String date; // "15 Mar 2025"
  final String fileSize; // "3.4 MB"
  final String findings; // Clinical findings or report summary

  const MedicalAttachmentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.fileSize,
    this.findings = '',
  });

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'x-ray':
        return Icons.medical_information_outlined;
      case 'lab report':
        return Icons.description_outlined;
      case 'scan report':
        return Icons.biotech_outlined;
      case 'prescription':
        return Icons.medication_outlined;
      default:
        return Icons.attach_file_rounded;
    }
  }

  Color get badgeColor {
    switch (type.toLowerCase()) {
      case 'x-ray':
        return const Color(0xFF2563EB); // blue
      case 'lab report':
        return const Color(0xFF007471); // teal
      case 'scan report':
        return const Color(0xFF7C3AED); // purple
      case 'prescription':
        return const Color(0xFFD97706); // amber
      default:
        return const Color(0xFF4B5563);
    }
  }

  Color get badgeBg {
    switch (type.toLowerCase()) {
      case 'x-ray':
        return const Color(0xFFDBEAFE);
      case 'lab report':
        return const Color(0xFFD1FAE5);
      case 'scan report':
        return const Color(0xFFEDE9FE);
      case 'prescription':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF3F4F6);
    }
  }
}

/// Data model representing a past consultation session
class PastConsultationRecord {
  final String id;
  final String date;
  final String doctorName;
  final String hospital;
  final String diagnosis;
  final String notes;
  final String prescription;
  final List<MedicalAttachmentModel> attachments;

  const PastConsultationRecord({
    required this.id,
    required this.date,
    required this.doctorName,
    required this.hospital,
    required this.diagnosis,
    required this.notes,
    required this.prescription,
    this.attachments = const [],
  });
}

/// Data model representing a patient and their consultation/appointment details
class DoctorPatientModel {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String address;
  final String bloodGroup;
  final String tokenNo;
  final String time;
  final String room;
  String status; // 'Completed', 'In Progress', 'Waiting', 'Next', 'Upcoming'
  final String type; // 'Consultation', 'Follow-up', 'Routine Checkup'
  final List<String> allergies;
  final List<String> previousConditions;
  final List<Map<String, String>> previousVisits;
  final List<Map<String, String>> currentMedications;
  String consultationNotes;
  String diagnosis;
  String prescription;
  final List<PastConsultationRecord> pastConsultations;
  final List<MedicalAttachmentModel> pastAttachments;

  DoctorPatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.address,
    required this.bloodGroup,
    required this.tokenNo,
    required this.time,
    required this.room,
    required this.status,
    required this.type,
    this.allergies = const [],
    this.previousConditions = const [],
    this.previousVisits = const [],
    this.currentMedications = const [],
    this.consultationNotes = '',
    this.diagnosis = '',
    this.prescription = '',
    this.pastConsultations = const [],
    this.pastAttachments = const [],
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'PT';
  }

  DoctorPatientModel copyWith({
    String? status,
    String? consultationNotes,
    String? diagnosis,
    String? prescription,
    List<PastConsultationRecord>? pastConsultations,
    List<MedicalAttachmentModel>? pastAttachments,
  }) {
    return DoctorPatientModel(
      id: id,
      name: name,
      age: age,
      gender: gender,
      phone: phone,
      address: address,
      bloodGroup: bloodGroup,
      tokenNo: tokenNo,
      time: time,
      room: room,
      status: status ?? this.status,
      type: type,
      allergies: allergies,
      previousConditions: previousConditions,
      previousVisits: previousVisits,
      currentMedications: currentMedications,
      consultationNotes: consultationNotes ?? this.consultationNotes,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      pastConsultations: pastConsultations ?? this.pastConsultations,
      pastAttachments: pastAttachments ?? this.pastAttachments,
    );
  }
}

/// Data model representing the Doctor's profile
class DoctorProfileModel {
  String staffId;
  String name;
  String specialty;
  String hospital;
  String email;
  String phone;
  int totalSlots;
  String nextActiveDate;

  DoctorProfileModel({
    required this.staffId,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.email,
    required this.phone,
    this.totalSlots = 18,
    this.nextActiveDate = '20 Sep 2026',
  });
}

/// Data model representing an availability slot
class DoctorAvailabilitySlotModel {
  final String timeRange;
  final String status; // 'Available', 'Unavailable', 'Pending', 'Approved', 'Rejected'
  final String date;
  final String location;

  DoctorAvailabilitySlotModel({
    required this.timeRange,
    required this.status,
    required this.date,
    required this.location,
  });
}

/// Data model representing a doctor availability change request
class AvailabilityRequestModel {
  final String id;
  final String doctorName;
  final String targetDate;
  final String timeSlot;
  final String currentStatus;
  final String requestedStatus;
  final String reason;
  final String submittedTime;
  String status; // 'Pending', 'Approved', 'Rejected'
  final int progressStep; // 1 = Submitted, 2 = Pending review, 3 = Completed

  AvailabilityRequestModel({
    required this.id,
    required this.doctorName,
    required this.targetDate,
    required this.timeSlot,
    required this.currentStatus,
    required this.requestedStatus,
    required this.reason,
    required this.submittedTime,
    this.status = 'Pending',
    this.progressStep = 2,
  });
}

/// Singleton Doctor Service managing doctor-side dummy data for Phase 1
/// and structured to seamlessly integrate with Firebase Cloud Firestore in Phase 2.
class DoctorService extends ChangeNotifier {
  static final DoctorService instance = DoctorService._internal();
  DoctorService._internal() {
    _initializeData();
  }

  // Doctor Profile
  late DoctorProfileModel _profile;
  DoctorProfileModel get profile => _profile;

  // Appointments List
  late List<DoctorPatientModel> _appointments;
  List<DoctorPatientModel> get appointments => List.unmodifiable(_appointments);

  // Queue State
  DoctorPatientModel? _currentConsulting;
  DoctorPatientModel? get currentConsulting => _currentConsulting;

  DoctorPatientModel? _nextPatient;
  DoctorPatientModel? get nextPatient => _nextPatient;

  final List<DoctorPatientModel> _waitingQueue = [];
  List<DoctorPatientModel> get waitingQueue => List.unmodifiable(_waitingQueue);

  // Time Slots
  late List<DoctorAvailabilitySlotModel> _timeSlots;
  List<DoctorAvailabilitySlotModel> get timeSlots => List.unmodifiable(_timeSlots);

  // Availability Change Requests
  late List<AvailabilityRequestModel> _requests;
  List<AvailabilityRequestModel> get requests => List.unmodifiable(_requests);

  void resetData() {
    _initializeData();
    notifyListeners();
  }

  void _initializeData() {
    _profile = DoctorProfileModel(
      staffId: 'DOC-2024-0847',
      name: 'Dr. Ananya Perera',
      specialty: 'General Medicine',
      hospital: 'Government General Hospital',
      email: 'nimal.perera@hospital.lk',
      phone: '071 234 5678',
      totalSlots: 18,
      nextActiveDate: '20 Sep 2026',
    );

    // Common medical attachments for dummy records
    final kasunAttachments = [
      const MedicalAttachmentModel(
        id: 'ATT-101',
        name: 'Chest_XRay_PA_View.png',
        type: 'X-ray',
        date: '15 Mar 2025',
        fileSize: '4.2 MB',
        findings: 'Chest X-Ray PA View: Normal cardiothoracic ratio (<50%). Lung parenchymal markings are within normal limits. Costophrenic angles are clear. No acute focal consolidation or pneumothorax.',
      ),
      const MedicalAttachmentModel(
        id: 'ATT-102',
        name: 'HbA1c_Glycated_Report.pdf',
        type: 'Lab Report',
        date: '15 Mar 2025',
        fileSize: '1.8 MB',
        findings: 'Glycated Hemoglobin (HbA1c): 7.4% (Target: <6.5%). Fasting Plasma Glucose: 146 mg/dL. Renal function: Serum Creatinine 0.92 mg/dL, eGFR >90. Moderate glycemic sub-optimization.',
      ),
      const MedicalAttachmentModel(
        id: 'ATT-103',
        name: 'Abdominal_Ultrasound_Scan.jpg',
        type: 'Scan Report',
        date: '10 Jan 2025',
        fileSize: '3.5 MB',
        findings: 'Ultrasound Whole Abdomen: Liver is normal in size with mild increased echogenicity consistent with Grade 1 Hepatic Steatosis. Gallbladder, spleen, pancreas, and bilateral kidneys appear normal.',
      ),
      const MedicalAttachmentModel(
        id: 'ATT-104',
        name: 'Resting_12Lead_ECG.pdf',
        type: 'Lab Report',
        date: '10 Jan 2025',
        fileSize: '1.2 MB',
        findings: '12-Lead Electrocardiogram: Regular sinus rhythm, ventricular rate 74 bpm. Normal axis, PR interval 150 ms, QRS duration 86 ms. No pathological Q waves or ST-T changes.',
      ),
    ];

    final kasunPastConsultations = [
      PastConsultationRecord(
        id: 'CONS-901',
        date: '15 Mar 2025',
        doctorName: 'Dr. S. Perera',
        hospital: 'Government Hospital — Colombo',
        diagnosis: 'Type 2 Diabetes Mellitus (Follow-up Review)',
        notes: 'Patient presented for routine quarterly diabetic assessment. Fasting blood glucose mildly elevated at 146 mg/dL. Blood pressure 128/82 mmHg. Reports mild early morning fatigue. Advised 30 minutes brisk walking daily and low-GI carbohydrate diet. Continue oral antidiabetic therapy.',
        prescription: '1. Tab. Metformin 500mg – 1-0-1 (After meals)\n2. Tab. Atorvastatin 20mg – 0-0-1 (Night)',
        attachments: [kasunAttachments[0], kasunAttachments[1]],
      ),
      PastConsultationRecord(
        id: 'CONS-902',
        date: '10 Jan 2025',
        doctorName: 'Dr. Ananya Perera',
        hospital: 'Teaching Hospital — OPD',
        diagnosis: 'Essential Hypertension & Mild Hepatic Steatosis',
        notes: 'Initial workup for borderline hypertension. BP 138/88 mmHg. Advised salt restriction and reduction of saturated fats. Liver function test shows mild transaminase elevation; ultrasound shows grade 1 fatty liver.',
        prescription: '1. Tab. Amlodipine 5mg – 1-0-0 (Morning)\n2. Tab. Paracetamol 500mg SOS for headaches',
        attachments: [kasunAttachments[2], kasunAttachments[3]],
      ),
    ];

    _appointments = [
      DoctorPatientModel(
        id: 'P1001',
        name: 'Nimal Perera',
        age: 45,
        gender: 'Male',
        phone: '071 554 9912',
        address: 'No. 45, Galle Road, Colombo',
        bloodGroup: 'B+',
        tokenNo: '01',
        time: '09:00 AM',
        room: 'Room 01',
        status: 'Completed',
        type: 'Consultation',
        allergies: ['Dust (mild)'],
        previousConditions: ['Gastritis (2021)'],
        previousVisits: [
          {'date': '10 Jan 2025', 'title': 'Routine Examination'},
        ],
        currentMedications: [
          {'name': 'Omeprazole 20mg', 'dosage': '1-0-0'},
        ],
        consultationNotes: 'Patient recovered well from acute gastritis. Advised healthy diet.',
        diagnosis: 'Resolved Gastritis',
        prescription: 'Omeprazole 20mg if needed.',
        pastAttachments: [
          const MedicalAttachmentModel(
            id: 'ATT-105',
            name: 'Upper_GI_Endoscopy_Report.pdf',
            type: 'Scan Report',
            date: '10 Jan 2025',
            fileSize: '2.1 MB',
            findings: 'Upper GI Endoscopy: Mild antral erythema without ulceration or mucosal atrophy. Biopsy negative for H. pylori.',
          ),
        ],
        pastConsultations: [
          const PastConsultationRecord(
            id: 'CONS-903',
            date: '10 Jan 2025',
            doctorName: 'Dr. S. Perera',
            hospital: 'Government Hospital — Colombo',
            diagnosis: 'Acute Superficial Gastritis',
            notes: 'Epigastric discomfort following spicy meals. Prescribed PPI therapy for 4 weeks.',
            prescription: '1. Cap. Omeprazole 20mg – 1-0-0 before breakfast',
          ),
        ],
      ),
      DoctorPatientModel(
        id: 'P1002',
        name: 'Sanduni Silva',
        age: 28,
        gender: 'Female',
        phone: '077 443 1120',
        address: 'No. 18, Kandy Road, Kadawatha',
        bloodGroup: 'A+',
        tokenNo: '02',
        time: '09:15 AM',
        room: 'Room 01',
        status: 'In Progress',
        type: 'Consultation',
        allergies: ['Sulfa drugs'],
        previousConditions: ['Migraine (2022)'],
        previousVisits: [
          {'date': '02 Feb 2025', 'title': 'Headache follow-up'},
        ],
        currentMedications: [
          {'name': 'Paracetamol 500mg', 'dosage': '1-1-1'},
        ],
        consultationNotes: 'Under observation for headache. Vitals checked and normal.',
        diagnosis: 'Tension Headache',
        prescription: 'Paracetamol 500mg SOS.',
        pastAttachments: [
          const MedicalAttachmentModel(
            id: 'ATT-106',
            name: 'Brain_MRI_Screening.png',
            type: 'Scan Report',
            date: '02 Feb 2025',
            fileSize: '5.8 MB',
            findings: 'MRI Brain 1.5T: No evidence of acute intracranial pathology, mass effect, or midline shift. Ventricles are normal size.',
          ),
        ],
      ),
      DoctorPatientModel(
        id: 'P1003',
        name: 'Kasun Fernando',
        age: 34,
        gender: 'Male',
        phone: '071 234 5678',
        address: 'No. 12, Matara',
        bloodGroup: 'O+',
        tokenNo: '03',
        time: '09:30 AM',
        room: 'Room 01',
        status: 'In Progress',
        type: 'Consultation',
        allergies: [
          'Penicillin (mild reaction)',
          'Dust (sneezing)',
        ],
        previousConditions: [
          'Type 2 Diabetes (2020)',
          'Hypertension (2021)',
          'High Cholesterol (2022)',
        ],
        previousVisits: [
          {'date': '15 Mar 2025', 'title': 'General Checkup'},
          {'date': '10 Jan 2025', 'title': 'Follow up (Diabetes)'},
        ],
        currentMedications: [
          {'name': 'Metformin 500mg', 'dosage': '1-0-1'},
          {'name': 'Amlodipine 5mg', 'dosage': '1-0-0'},
          {'name': 'Atorvastatin 20mg', 'dosage': '1-0-0'},
        ],
        consultationNotes: 'Patient complains of fatigue and high blood sugar levels. Advised lifestyle changes and continue medication.',
        diagnosis: 'Type 2 Diabetes Mellitus (Follow up)',
        prescription: '1. Metformin 500mg – 1-0-1 (after meals)\n2. Amlodipine 5mg – 1-0-0\n3. Atorvastatin 20mg – 1-0-0',
        pastAttachments: kasunAttachments,
        pastConsultations: kasunPastConsultations,
      ),
      DoctorPatientModel(
        id: 'P1004',
        name: 'Nimal Perera',
        age: 42,
        gender: 'Male',
        phone: '071 998 8776',
        address: 'No. 3, Ward Place, Colombo 07',
        bloodGroup: 'O+',
        tokenNo: '04',
        time: '09:45 AM',
        room: 'Room 01',
        status: 'Next',
        type: 'Consultation',
        allergies: ['Penicillin'],
        previousConditions: ['Hypertension (2020)'],
        previousVisits: [
          {'date': '05 Jan 2025', 'title': 'Routine checkup'},
        ],
        currentMedications: [
          {'name': 'Losartan 50mg', 'dosage': '1-0-0'},
        ],
      ),
      DoctorPatientModel(
        id: 'P1005',
        name: 'Sanduni Silva',
        age: 30,
        gender: 'Female',
        phone: '077 223 3445',
        address: 'No. 77, Havelock Road, Colombo 05',
        bloodGroup: 'B+',
        tokenNo: '05',
        time: '10:00 AM',
        room: 'Room 01',
        status: 'Waiting',
        type: 'Consultation',
      ),
      DoctorPatientModel(
        id: 'P1006',
        name: 'Tharindu Jayasinghe',
        age: 35,
        gender: 'Male',
        phone: '076 887 7665',
        address: 'No. 12, Baseline Road, Borella',
        bloodGroup: 'A+',
        tokenNo: '06',
        time: '10:15 AM',
        room: 'Room 01',
        status: 'Waiting',
        type: 'Consultation',
      ),
      DoctorPatientModel(
        id: 'P1007',
        name: 'Ishara Senanayake',
        age: 26,
        gender: 'Female',
        phone: '075 998 7765',
        address: 'No. 14, Station Road, Panadura',
        bloodGroup: 'O-',
        tokenNo: '07',
        time: '10:30 AM',
        room: 'Room 01',
        status: 'Waiting',
        type: 'Routine Checkup',
        allergies: ['None known'],
        previousConditions: ['Anemia (2023)'],
        previousVisits: [
          {'date': '14 Feb 2025', 'title': 'Blood test review'},
        ],
        currentMedications: [
          {'name': 'Ferrous Fumarate 200mg', 'dosage': '0-1-0'},
        ],
      ),
      DoctorPatientModel(
        id: 'P1008',
        name: 'Sunil Weerakkody',
        age: 52,
        gender: 'Male',
        phone: '071 887 6654',
        address: 'No. 5, Lake View, Nugegoda',
        bloodGroup: 'A+',
        tokenNo: '08',
        time: '10:45 AM',
        room: 'Room 01',
        status: 'Upcoming',
        type: 'Follow-up',
      ),
      DoctorPatientModel(
        id: 'P1009',
        name: 'Menaka Rathnayake',
        age: 41,
        gender: 'Female',
        phone: '077 332 1109',
        address: 'No. 99, Highlevel Road, Maharagama',
        bloodGroup: 'O+',
        tokenNo: '09',
        time: '11:00 AM',
        room: 'Room 01',
        status: 'Upcoming',
        type: 'Consultation',
      ),
      DoctorPatientModel(
        id: 'P1010',
        name: 'Anura Bandara',
        age: 60,
        gender: 'Male',
        phone: '070 445 2213',
        address: 'No. 17, Circular Road, Dehiwala',
        bloodGroup: 'B+',
        tokenNo: '10',
        time: '11:15 AM',
        room: 'Room 01',
        status: 'Upcoming',
        type: 'Consultation',
      ),
      DoctorPatientModel(
        id: 'P1011',
        name: 'Chathurika Fonseka',
        age: 33,
        gender: 'Female',
        phone: '078 991 2234',
        address: 'No. 24, Sea Street, Negombo',
        bloodGroup: 'AB-',
        tokenNo: '11',
        time: '11:30 AM',
        room: 'Room 01',
        status: 'Upcoming',
        type: 'Routine Checkup',
      ),
      DoctorPatientModel(
        id: 'P1012',
        name: 'Dinesh Kumara',
        age: 29,
        gender: 'Male',
        phone: '071 123 7890',
        address: 'No. 61, Cross St, Moratuwa',
        bloodGroup: 'O+',
        tokenNo: '12',
        time: '11:45 AM',
        room: 'Room 01',
        status: 'Upcoming',
        type: 'Consultation',
      ),
    ];

    // Setup initial queue matching Figma queue-pro.png:
    _currentConsulting = _appointments[2];
    _nextPatient = _appointments[3];

    _waitingQueue.clear();
    _waitingQueue.addAll([
      _appointments[4],
      _appointments[5],
      _appointments[6],
    ]);

    // Available Time Slots matching Figma available-time-slots.png
    _timeSlots = [
      DoctorAvailabilitySlotModel(
        timeRange: '09:00 - 10:00',
        status: 'Available',
        date: '20 September 2026 - Sunday',
        location: 'OPD Block A - Gov Hospital',
      ),
      DoctorAvailabilitySlotModel(
        timeRange: '10:00 - 11:00',
        status: 'Available',
        date: '20 September 2026 - Sunday',
        location: 'OPD Block A - Gov Hospital',
      ),
      DoctorAvailabilitySlotModel(
        timeRange: '11:00 - 12:00',
        status: 'Unavailable',
        date: '20 September 2026 - Sunday',
        location: 'OPD Block A - Gov Hospital',
      ),
      DoctorAvailabilitySlotModel(
        timeRange: '13:00 - 14:00',
        status: 'Pending',
        date: '20 September 2026 - Sunday',
        location: 'OPD Block A - Gov Hospital',
      ),
      DoctorAvailabilitySlotModel(
        timeRange: '14:00 - 15:00',
        status: 'Approved',
        date: '20 September 2026 - Sunday',
        location: 'OPD Block A - Gov Hospital',
      ),
      DoctorAvailabilitySlotModel(
        timeRange: '15:00 - 16:00',
        status: 'Rejected',
        date: '20 September 2026 - Sunday',
        location: 'OPD Block A - Gov Hospital',
      ),
    ];

    // Availability Requests matching Figma my-availability-requests.png
    _requests = [
      AvailabilityRequestModel(
        id: 'REQ-2026-1547',
        doctorName: 'Dr. Ananya Perera',
        targetDate: '20 Sep 2026',
        timeSlot: '11:00 - 12:00',
        currentStatus: 'Available',
        requestedStatus: 'Unavailable',
        reason: 'Attending a medical conference',
        submittedTime: '19 Sep 2026, 10:30 AM',
        status: 'Pending',
        progressStep: 2,
      ),
      AvailabilityRequestModel(
        id: 'REQ-2026-1546',
        doctorName: 'Dr. Ananya Perera',
        targetDate: '18 Sep 2026',
        timeSlot: '09:00 - 10:00',
        currentStatus: 'Unavailable',
        requestedStatus: 'Available',
        reason: 'Special clinic shift coverage',
        submittedTime: '17 Sep 2026, 08:15 AM',
        status: 'Approved',
        progressStep: 3,
      ),
      AvailabilityRequestModel(
        id: 'REQ-2026-1545',
        doctorName: 'Dr. Ananya Perera',
        targetDate: '15 Sep 2026',
        timeSlot: '14:00 - 15:00',
        currentStatus: 'Available',
        requestedStatus: 'Unavailable',
        reason: 'Personal emergency leave',
        submittedTime: '14 Sep 2026, 04:00 PM',
        status: 'Rejected',
        progressStep: 3,
      ),
    ];
  }

  // ================= STATS FOR DASHBOARD =================
  int get totalAppointmentsCount => _appointments.length;

  int get waitingPatientsCount {
    return _waitingQueue.length + (_nextPatient != null ? 1 : 0);
  }

  int get inConsultationCount => _currentConsulting != null ? 1 : 0;

  int get completedTasksCount {
    return _appointments.where((a) => a.status.toLowerCase() == 'completed').length;
  }

  // ================= QUEUE FLOW LOGIC =================
  void callNextPatient() {
    if (_nextPatient == null && _waitingQueue.isEmpty) return;

    if (_currentConsulting != null) {
      final prevIndex = _appointments.indexWhere((p) => p.id == _currentConsulting!.id);
      if (prevIndex != -1) {
        _appointments[prevIndex] = _appointments[prevIndex].copyWith(status: 'Completed');
      }
    }

    if (_nextPatient != null) {
      _currentConsulting = _nextPatient!.copyWith(status: 'In Progress');
      final apptIndex = _appointments.indexWhere((p) => p.id == _nextPatient!.id);
      if (apptIndex != -1) {
        _appointments[apptIndex] = _appointments[apptIndex].copyWith(status: 'In Progress');
      }

      if (_waitingQueue.isNotEmpty) {
        final newNext = _waitingQueue.removeAt(0);
        _nextPatient = newNext.copyWith(status: 'Next');
        final nextIdx = _appointments.indexWhere((p) => p.id == newNext.id);
        if (nextIdx != -1) {
          _appointments[nextIdx] = _appointments[nextIdx].copyWith(status: 'Next');
        }
      } else {
        _nextPatient = null;
      }
    } else if (_waitingQueue.isNotEmpty) {
      final newCurrent = _waitingQueue.removeAt(0);
      _currentConsulting = newCurrent.copyWith(status: 'In Progress');
      final curIdx = _appointments.indexWhere((p) => p.id == newCurrent.id);
      if (curIdx != -1) {
        _appointments[curIdx] = _appointments[curIdx].copyWith(status: 'In Progress');
      }

      if (_waitingQueue.isNotEmpty) {
        final newNext = _waitingQueue.removeAt(0);
        _nextPatient = newNext.copyWith(status: 'Next');
        final nextIdx = _appointments.indexWhere((p) => p.id == newNext.id);
        if (nextIdx != -1) {
          _appointments[nextIdx] = _appointments[nextIdx].copyWith(status: 'Next');
        }
      } else {
        _nextPatient = null;
      }
    }

    notifyListeners();
  }

  /// Complete consultation for the given patient, saving notes, diagnosis, prescription,
  /// and any new medical attachments into patient history.
  void completeConsultation({
    required String patientId,
    required String notes,
    required String diagnosis,
    required String prescription,
    List<MedicalAttachmentModel>? attachments,
  }) {
    final targetId = patientId.isNotEmpty ? patientId : (_currentConsulting?.id ?? '');
    final idx = _appointments.indexWhere((p) => p.id == targetId);
    if (idx != -1) {
      final now = DateTime.now();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final todayStr = '${now.day} ${months[now.month - 1]} ${now.year}';

      final attachedList = attachments ?? [];

      final newRecord = PastConsultationRecord(
        id: 'CONS-${now.millisecondsSinceEpoch}',
        date: todayStr,
        doctorName: _profile.name,
        hospital: _profile.hospital,
        diagnosis: diagnosis,
        notes: notes,
        prescription: prescription,
        attachments: attachedList,
      );

      final updatedPastConsultations = [
        newRecord,
        ..._appointments[idx].pastConsultations,
      ];

      final updatedPastAttachments = [
        ...attachedList,
        ..._appointments[idx].pastAttachments,
      ];

      _appointments[idx] = _appointments[idx].copyWith(
        status: 'Completed',
        consultationNotes: notes,
        diagnosis: diagnosis,
        prescription: prescription,
        pastConsultations: updatedPastConsultations,
        pastAttachments: updatedPastAttachments,
      );
    }

    // Advance queue
    callNextPatient();
  }

  // ================= PROFILE & AVAILABILITY REQUEST LOGIC =================
  void updateDoctorProfile({
    required String name,
    required String specialty,
    required String hospital,
    required String email,
    required String phone,
  }) {
    _profile.name = name;
    _profile.specialty = specialty;
    _profile.hospital = hospital;
    _profile.email = email;
    _profile.phone = phone;
    notifyListeners();
  }

  AvailabilityRequestModel submitAvailabilityRequest({
    required String targetDate,
    required String timeSlot,
    required String requestedStatus,
    required String reason,
    required String currentStatus,
  }) {
    final newId = 'REQ-2026-${1548 + _requests.length}';
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final timeStr = '${now.day} ${months[now.month - 1]} ${now.year}, 10:30 AM';

    final newRequest = AvailabilityRequestModel(
      id: newId,
      doctorName: _profile.name,
      targetDate: targetDate,
      timeSlot: timeSlot,
      currentStatus: currentStatus,
      requestedStatus: requestedStatus,
      reason: reason,
      submittedTime: timeStr,
      status: 'Pending',
      progressStep: 2,
    );

    _requests.insert(0, newRequest);
    notifyListeners();
    return newRequest;
  }

  void cancelRequest(String requestId) {
    _requests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }

  int get pendingRequestsCount {
    return _requests.where((r) => r.status.toLowerCase() == 'pending').length;
  }
}
