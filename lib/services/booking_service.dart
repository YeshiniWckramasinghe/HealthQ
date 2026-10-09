import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Hospital {
  final String id, name, province, district, city, status;
  final int slotsLeft;
  final String identificationNo;
  final String address;
  final String contactNo;
  final String openingHours;
  final String type;
  final List<String> departments;

  const Hospital({
    required this.id,
    required this.name,
    required this.province,
    required this.district,
    required this.city,
    required this.status,
    required this.slotsLeft,
    this.identificationNo = '',
    this.address = '',
    this.contactNo = '',
    this.openingHours = '',
    this.type = '',
    this.departments = const [],
  });

  /// Generates Hospital Identification No:
  /// Province first letter + District first letter + 5 digits (e.g. WC00001)
  static String formatIdentificationNo(String province, String district, int number) {
    final p = province.trim().isNotEmpty ? province.trim()[0].toUpperCase() : 'W';
    final d = district.trim().isNotEmpty ? district.trim()[0].toUpperCase() : 'C';
    final numStr = number.toString().padLeft(5, '0');
    return '$p$d$numStr';
  }

  /// Resolves Hospital Identification No (e.g. WC00001, WG00002, CK00003, SG00004, NJ00005, NK00006)
  /// from hospital code, hospital name, or location.
  static String resolveHospitalCode(String? hospitalNameOrId) {
    if (hospitalNameOrId == null || hospitalNameOrId.trim().isEmpty) return '';
    final raw = hospitalNameOrId.trim();
    if (RegExp(r'^[A-Za-z]{2}\d{5}$').hasMatch(raw)) {
      return raw.toUpperCase();
    }
    final key = raw.toLowerCase();
    // Prioritize specific hospital names before generic words like "teaching" or "district"
    if (key.contains('karapitiya') || key.contains('galle') || key.contains('sg00004')) {
      return 'SG00004';
    } else if (key.contains('jaffna') || key.contains('nj00005')) {
      return 'NJ00005';
    } else if (key.contains('kurunegala') || key.contains('nk00006')) {
      return 'NK00006';
    } else if (key.contains('kandy') || key.contains('ck00003') || key == 'teaching hospital') {
      return 'CK00003';
    } else if (key.contains('gampaha') || key.contains('negombo') || key.contains('wg00002') || key == 'district hospital') {
      return 'WG00002';
    } else if (key.contains('city') || key.contains('colombo') || key.contains('wc00001') || key.contains('national')) {
      return 'WC00001';
    } else if (key.contains('teaching')) {
      return 'CK00003';
    } else if (key.contains('district')) {
      return 'WG00002';
    }
    return '';
  }

  /// Strictly determines if an item's hospital (e.g., appointment or doctor)
  /// belongs to the target hospital.
  static bool matchesHospital({
    required String targetHospital,
    String? targetCode,
    required String itemHospital,
    String? itemCode,
  }) {
    final tHosp = targetHospital.trim().toLowerCase();
    final iHosp = itemHospital.trim().toLowerCase();

    // 1. Resolve official 7-char codes (e.g. WC00001, CK00003, WG00002)
    final tResolvedCode = resolveHospitalCode(
        targetCode != null && targetCode.trim().isNotEmpty
            ? targetCode
            : targetHospital);
    final iResolvedCode = resolveHospitalCode(
        itemCode != null && itemCode.trim().isNotEmpty
            ? itemCode
            : itemHospital);

    // If both resolve to valid official codes and they match, it is a DEFINITE MATCH!
    if (tResolvedCode.isNotEmpty &&
        iResolvedCode.isNotEmpty &&
        tResolvedCode == iResolvedCode) {
      return true;
    }

    // 2. Exact match of raw codes or IDs (e.g. "city_general" == "city_general")
    final tRawCode = (targetCode ?? '').trim().toLowerCase();
    final iRawCode = (itemCode ?? '').trim().toLowerCase();
    if (tRawCode.isNotEmpty && iRawCode.isNotEmpty && tRawCode == iRawCode) {
      return true;
    }

    // 3. Exact hospital name match
    if (tHosp.isNotEmpty && iHosp.isNotEmpty && tHosp == iHosp) {
      return true;
    }

    // 4. Target code contained in item hospital or vice-versa
    if (tResolvedCode.isNotEmpty &&
        (iHosp.contains(tResolvedCode.toLowerCase()) ||
            iRawCode.contains(tResolvedCode.toLowerCase()))) {
      return true;
    }
    if (iResolvedCode.isNotEmpty &&
        (tHosp.contains(iResolvedCode.toLowerCase()) ||
            tRawCode.contains(iResolvedCode.toLowerCase()))) {
      return true;
    }

    // 5. If BOTH resolved to DIFFERENT valid 7-char codes (e.g. WC00001 != WG00002),
    // they definitely belong to different hospitals!
    if (tResolvedCode.isNotEmpty &&
        iResolvedCode.isNotEmpty &&
        tResolvedCode != iResolvedCode) {
      return false;
    }

    // 6. Name containment (one contains the other)
    if (tHosp.isNotEmpty && iHosp.isNotEmpty) {
      if (tHosp.contains(iHosp) || iHosp.contains(tHosp)) return true;

      // 7. Distinct keyword matching
      if ((tHosp.contains('colombo') || tHosp.contains('city')) &&
          (iHosp.contains('colombo') || iHosp.contains('city'))) {
        return true;
      }
      if ((tHosp.contains('gampaha') ||
              tHosp.contains('negombo') ||
              tHosp.contains('district')) &&
          (iHosp.contains('gampaha') ||
              iHosp.contains('negombo') ||
              iHosp.contains('district'))) {
        return true;
      }
      if (tHosp.contains('kandy') && iHosp.contains('kandy')) {
        return true;
      }
      if ((tHosp.contains('karapitiya') || tHosp.contains('galle')) &&
          (iHosp.contains('karapitiya') || iHosp.contains('galle'))) {
        return true;
      }
      if (tHosp.contains('jaffna') && iHosp.contains('jaffna')) {
        return true;
      }
      if (tHosp.contains('kurunegala') && iHosp.contains('kurunegala')) {
        return true;
      }
    }

    // 8. If itemHospital is empty but itemCode matched via keyword
    if (tHosp.isNotEmpty && iRawCode.isNotEmpty) {
      if (iRawCode.contains('colombo') || iRawCode.contains('city')) {
        if (tHosp.contains('colombo') || tHosp.contains('city')) {
          return true;
        }
      }
      if (iRawCode.contains('kandy') && tHosp.contains('kandy')) {
        return true;
      }
      if ((iRawCode.contains('gampaha') || iRawCode.contains('negombo')) &&
          (tHosp.contains('gampaha') || tHosp.contains('negombo'))) {
        return true;
      }
      if ((iRawCode.contains('karapitiya') || iRawCode.contains('galle')) &&
          (tHosp.contains('karapitiya') || tHosp.contains('galle'))) {
        return true;
      }
      if (iRawCode.contains('jaffna') && tHosp.contains('jaffna')) {
        return true;
      }
      if (iRawCode.contains('kurunegala') && tHosp.contains('kurunegala')) {
        return true;
      }
    }

    return false;
  }

  factory Hospital.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final rawSlots = m['slotsLeft'] ?? m['slots_left'] ?? 0;
    final int slots = rawSlots is int
        ? rawSlots
        : (int.tryParse(rawSlots.toString()) ?? (rawSlots is num ? rawSlots.toInt() : 0));

    final rawDept = m['departments'] ?? m['specialities'] ?? m['units'];
    List<String> depts = [];
    if (rawDept is List) {
      depts = rawDept.map((e) => e.toString()).toList();
    }
    if (depts.isEmpty) {
      depts = const ['OPD Consultation', 'Emergency Care', 'General Medicine', 'Paediatrics', 'Cardiology'];
    }

    final cityVal = (m['city'] ?? '').toString();
    final distVal = (m['district'] ?? '').toString();
    final provVal = (m['province'] ?? '').toString();
    var addr = (m['address'] ?? m['location'] ?? '').toString();
    if (addr.isEmpty) {
      addr = [
        if (cityVal.isNotEmpty) cityVal,
        if (distVal.isNotEmpty && distVal != cityVal) distVal,
        if (provVal.isNotEmpty) provVal,
        'Sri Lanka'
      ].join(', ');
    }

    final rawIdNo = (m['identificationNo'] ??
            m['hospitalIdentificationNo'] ??
            m['hospitalCode'] ??
            m['hospitalId'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();

    String idNo = rawIdNo;
    if (idNo.isEmpty || !RegExp(r'^[A-Z]{2}\d{5}$').hasMatch(idNo)) {
      final key = '${d.id}_${m['name'] ?? ''}'.toLowerCase();
      if (key.contains('city') || key.contains('colombo')) {
        idNo = 'WC00001';
      } else if (key.contains('district') || key.contains('gampaha') || key.contains('negombo')) {
        idNo = 'WG00002';
      } else if (key.contains('teaching') || key.contains('kandy')) {
        idNo = 'CK00003';
      } else if (key.contains('karapitiya') || key.contains('galle')) {
        idNo = 'SG00004';
      } else if (key.contains('jaffna')) {
        idNo = 'NJ00005';
      } else if (key.contains('kurunegala')) {
        idNo = 'NK00006';
      } else {
        idNo = formatIdentificationNo(provVal, distVal, 10001);
      }
    }

    return Hospital(
      id: d.id,
      name: (m['name'] ?? m['hospitalName'] ?? m['hospital_name'] ?? d.id).toString(),
      province: provVal,
      district: distVal,
      city: cityVal,
      status: (m['status'] ?? 'open').toString().toLowerCase(),
      slotsLeft: slots,
      identificationNo: idNo,
      address: addr,
      contactNo: (m['contactNo'] ?? m['contact'] ?? m['phone'] ?? '011-2691111').toString(),
      openingHours: (m['openingHours'] ?? m['hours'] ?? 'OPD: 8:00 AM - 4:00 PM (Emergency 24/7)').toString(),
      type: (m['type'] ?? 'Government General Hospital').toString(),
      departments: depts,
    );
  }

  bool get isFull => status == 'full';
  bool get isOpen => status == 'open';
  bool get isLimited => status == 'limited';
  String get label => switch (status) {
        'open' => 'OPD Open',
        'limited' => slotsLeft > 0 ? '$slotsLeft slots left' : 'Slots limited',
        _ => 'Full',
      };
  Color get color => switch (status) {
        'open' => const Color(0xFF10B981), // Green dot in wireframe
        'limited' => const Color(0xFFF59E0B), // Orange/Amber dot in wireframe
        _ => const Color(0xFFEF4444), // Red dot in wireframe
      };
}

class Doctor {
  final String id, name, speciality, hospital;
  final String? hospitalId;
  final String? room;
  final String? contactNo;
  final String? email;
  int waiting;

  Doctor({
    required this.id,
    required this.name,
    required this.speciality,
    this.hospital = '',
    this.hospitalId,
    this.room,
    this.contactNo,
    this.email,
    this.waiting = 0,
  });

  factory Doctor.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    return Doctor.fromMap(d.data() ?? {}, docId: d.id);
  }

  factory Doctor.fromMap(Map<String, dynamic> m, {required String docId}) {
    final rawName = m['name'] ?? m['fullName'] ?? m['doctorName'] ?? 'Doctor';
    var nameStr = rawName.toString().trim();
    if (nameStr.isEmpty) nameStr = 'Doctor';
    if (!nameStr.toLowerCase().startsWith('dr.') &&
        !nameStr.toLowerCase().startsWith('dr ')) {
      nameStr = 'Dr. $nameStr';
    }

    final rawSpec = m['speciality'] ??
        m['specialty'] ??
        m['department'] ??
        m['unit'] ??
        'General Medicine';
    final specStr = rawSpec.toString().trim().isNotEmpty
        ? rawSpec.toString().trim()
        : 'General Medicine';

    final rawHosp =
        m['hospital'] ?? m['hospitalName'] ?? m['hospital_name'] ?? '';
    final rawHospId = m['hospitalId'] ?? m['hospitalCode'] ?? m['identificationNo'];
    final effectiveHospId = (rawHospId != null && rawHospId.toString().trim().isNotEmpty)
        ? rawHospId.toString().trim()
        : Hospital.resolveHospitalCode(rawHosp.toString());
    final rawRoom = m['room'] ?? m['roomNo'] ?? m['room_no'];
    final rawPhone =
        m['contactNo'] ?? m['phone'] ?? m['mobile'] ?? m['contact'];
    final rawEmail = m['email'] ?? m['mail'];

    return Doctor(
      id: docId,
      name: nameStr,
      speciality: specStr,
      hospital: rawHosp.toString().trim(),
      hospitalId: effectiveHospId.isNotEmpty ? effectiveHospId : null,
      room: rawRoom?.toString().trim(),
      contactNo: rawPhone?.toString().trim(),
      email: rawEmail?.toString().trim(),
    );
  }
}

class AppointmentRecord {
  final String id,
      userId,
      authUid,
      nic,
      hospitalName,
      hospitalIdentificationNo,
      doctorName,
      date,
      dateLabel,
      session,
      status,
      patientName,
      contact;
  final int queueNo;
  final DateTime createdAt;

  AppointmentRecord({
    required this.id,
    this.userId = '',
    this.authUid = '',
    this.nic = '',
    required this.hospitalName,
    this.hospitalIdentificationNo = '',
    required this.doctorName,
    required this.date,
    required this.dateLabel,
    required this.session,
    required this.status,
    required this.queueNo,
    required this.createdAt,
    this.patientName = '',
    this.contact = '',
  });

  factory AppointmentRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final nicVal = (m['nic'] ?? '').toString();
    final userVal = (m['userId'] ?? '').toString();
    final authVal = (m['authUid'] ?? m['userUid'] ?? '').toString();
    final rawHospName = (m['hospitalName'] ?? m['hospital'] ?? '').toString();
    final hid = (m['hospitalIdentificationNo'] ??
            m['hospitalCode'] ??
            m['hospitalId'] ??
            '')
        .toString();
    final effectiveHid = Hospital.resolveHospitalCode(hid.isNotEmpty ? hid : rawHospName);
    return AppointmentRecord(
      id: d.id,
      userId: userVal.isNotEmpty ? userVal : nicVal,
      authUid: authVal,
      nic: nicVal,
      hospitalName: rawHospName,
      hospitalIdentificationNo: effectiveHid,
      doctorName: m['doctorName'] ?? '',
      date: m['date'] ?? '',
      dateLabel: m['dateLabel'] ?? '',
      session: m['session'] ?? '',
      status: m['status'] ?? 'pending',
      queueNo: (m['queueNo'] ?? 0) as int,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      patientName: m['patientName'] ?? '',
      contact: m['contact'] ?? '',
    );
  }

  /// Match appointment to current user by Auth UID, User ID (NIC), or Document ID prefix
  bool matchesUser(String uid, [String? userNic]) {
    if (authUid == uid) return true;
    if (userId == uid) return true;
    if (userNic != null &&
        userNic.isNotEmpty &&
        (userId == userNic || nic == userNic)) {
      return true;
    }
    if (id.startsWith('${uid}_')) return true;
    return false;
  }
}

class UserProfile {
  final String userId, fullName, nic, dob, contact, email, photoUrl, photoBase64;
  const UserProfile({
    this.userId = '',
    this.fullName = '',
    this.nic = '',
    this.dob = '',
    this.contact = '',
    this.email = '',
    this.photoUrl = '',
    this.photoBase64 = '',
  });

  bool get hasProfilePic => photoBase64.isNotEmpty || photoUrl.isNotEmpty;

  /// User ID strictly defaults to NIC number if not explicitly set
  String get effectiveUserId =>
      userId.isNotEmpty ? userId : (nic.isNotEmpty ? nic : '');

  String get initials {
    final src = fullName.trim().isNotEmpty ? fullName.trim() : email.trim();
    if (src.isEmpty) return '?';
    final parts = src.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}


class NotificationItem {
  final String id, title, body;
  final DateTime createdAt;
  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory NotificationItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return NotificationItem(
      id: d.id,
      title: m['title'] ?? '',
      body: m['body'] ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class BookingService {
  static final BookingService instance = BookingService();
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String queueKey(String hid, String did, String date, String session) =>
      '${hid}_${did}_${date}_$session';

  /// Get hospitals from Cloud Firestore with automatic seeding if empty and fallback
  Future<List<Hospital>> getHospitals() async {
    try {
      final snap = await _db
          .collection('hospitals')
          .get()
          .timeout(const Duration(seconds: 8));

      // If empty or missing identification numbers, trigger automatic sync/seed
      final bool needsSeed = snap.docs.isEmpty ||
          snap.docs.any((d) =>
              (d.data()['identificationNo'] ?? '').toString().trim().isEmpty);
      if (needsSeed) {
        await seedIfEmpty();
      }

      final effectiveSnap = needsSeed
          ? await _db
              .collection('hospitals')
              .get()
              .timeout(const Duration(seconds: 8))
          : snap;

      if (effectiveSnap.docs.isNotEmpty) {
        final Map<String, Hospital> uniqueHospitals = {};
        for (final doc in effectiveSnap.docs) {
          final h = Hospital.fromDoc(doc);
          // Key by identificationNo or name to prevent duplicate cards
          final key = h.identificationNo.isNotEmpty
              ? h.identificationNo
              : h.name.toLowerCase();
          uniqueHospitals[key] = h;
        }
        final list = uniqueHospitals.values.toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        return list;
      }
    } catch (e) {
      debugPrint('Error getting hospitals from Firestore: $e');
    }
    return _fallbackHospitals;
  }

  static const List<Hospital> _fallbackHospitals = [
    Hospital(
      id: 'city_general',
      name: 'City General Hospital',
      province: 'Western Province',
      district: 'Colombo',
      city: 'Colombo',
      status: 'open',
      slotsLeft: 0,
      identificationNo: 'WC00001',
      address: 'No. 12, Kynsey Road, Colombo 08',
      contactNo: '011-2691111',
      openingHours: 'OPD: 8:00 AM - 4:00 PM (Emergency 24/7)',
      type: 'National Teaching Hospital',
      departments: ['OPD Consultation', 'Cardiology', 'General Medicine', 'Paediatrics', 'Emergency Care'],
    ),
    Hospital(
      id: 'district_hospital',
      name: 'District Hospital',
      province: 'Western Province',
      district: 'Gampaha',
      city: 'Negombo',
      status: 'full',
      slotsLeft: 0,
      identificationNo: 'WG00002',
      address: 'Colombo Road, Negombo, Gampaha',
      contactNo: '031-2222261',
      openingHours: 'OPD: 8:00 AM - 4:00 PM (Emergency 24/7)',
      type: 'District General Hospital',
      departments: ['OPD Consultation', 'Neurology', 'Orthopaedics', 'Dermatology', 'Emergency Care'],
    ),
    Hospital(
      id: 'teaching_hospital',
      name: 'Teaching Hospital',
      province: 'Central Province',
      district: 'Kandy',
      city: 'Kandy',
      status: 'limited',
      slotsLeft: 3,
      identificationNo: 'CK00003',
      address: 'William Gopallawa Mawatha, Kandy',
      contactNo: '081-2222261',
      openingHours: 'OPD: 8:00 AM - 4:00 PM (Emergency 24/7)',
      type: 'National Teaching Hospital',
      departments: ['OPD Consultation', 'Paediatrics', 'General Surgery', 'ENT Specialist', 'Cardiology'],
    ),
    Hospital(
      id: 'karapitiya',
      name: 'Karapitiya Hospital',
      province: 'Southern Province',
      district: 'Galle',
      city: 'Galle',
      status: 'open',
      slotsLeft: 0,
      identificationNo: 'SG00004',
      address: 'Karapitiya, Galle, Southern Province',
      contactNo: '091-2232250',
      openingHours: 'OPD: 8:00 AM - 4:00 PM (Emergency 24/7)',
      type: 'Teaching Hospital',
      departments: ['OPD Consultation', 'Oncology', 'Cardiology', 'General Medicine', 'Emergency Care'],
    ),
    Hospital(
      id: 'jaffna_base',
      name: 'Jaffna Base Hospital',
      province: 'Northern Province',
      district: 'Jaffna',
      city: 'Jaffna',
      status: 'limited',
      slotsLeft: 5,
      identificationNo: 'NJ00005',
      address: 'Hospital Road, Jaffna, Northern Province',
      contactNo: '021-2222261',
      openingHours: 'OPD: 8:00 AM - 4:00 PM (Emergency 24/7)',
      type: 'Teaching Hospital',
      departments: ['OPD Consultation', 'General Medicine', 'Paediatrics', 'Cardiology', 'Emergency Care'],
    ),
    Hospital(
      id: 'kurunegala',
      name: 'Kurunegala Hospital',
      province: 'North Western Province',
      district: 'Kurunegala',
      city: 'Kurunegala',
      status: 'open',
      slotsLeft: 0,
      identificationNo: 'NK00006',
      address: 'Circular Road, Kurunegala',
      contactNo: '037-2222261',
      openingHours: 'OPD: 8:00 AM - 4:00 PM (Emergency 24/7)',
      type: 'Teaching Hospital',
      departments: ['OPD Consultation', 'Orthopaedics', 'General Medicine', 'Ophthalmology', 'Emergency Care'],
    ),
  ];

  static final List<Doctor> _sampleHospitalDoctors = [
    // 1. City General Hospital (WC00001)
    Doctor(
      id: 'dr_wc_01',
      name: 'Dr. S. Perera',
      speciality: 'Cardiology',
      hospital: 'City General Hospital',
      hospitalId: 'WC00001',
      room: 'Room 04',
      contactNo: '071-2345671',
      email: 's.perera@healthq.lk',
    ),
    Doctor(
      id: 'dr_wc_02',
      name: 'Dr. R. Fernando',
      speciality: 'General Medicine',
      hospital: 'City General Hospital',
      hospitalId: 'WC00001',
      room: 'Room 02',
      contactNo: '071-2345672',
      email: 'r.fernando@healthq.lk',
    ),
    Doctor(
      id: 'dr_wc_03',
      name: 'Dr. M. Silva',
      speciality: 'Paediatrics',
      hospital: 'City General Hospital',
      hospitalId: 'WC00001',
      room: 'Room 01',
      contactNo: '071-2345673',
      email: 'm.silva@healthq.lk',
    ),

    // 2. District Hospital (WG00002)
    Doctor(
      id: 'dr_wg_01',
      name: 'Dr. K. Jayasinghe',
      speciality: 'Neurology',
      hospital: 'District Hospital',
      hospitalId: 'WG00002',
      room: 'Room 07',
      contactNo: '077-3456781',
      email: 'k.jayasinghe@healthq.lk',
    ),
    Doctor(
      id: 'dr_wg_02',
      name: 'Dr. N. Alwis',
      speciality: 'Orthopaedics',
      hospital: 'District Hospital',
      hospitalId: 'WG00002',
      room: 'Room 05',
      contactNo: '077-3456782',
      email: 'n.alwis@healthq.lk',
    ),
    Doctor(
      id: 'dr_wg_03',
      name: 'Dr. D. Wickramasinghe',
      speciality: 'Dermatology',
      hospital: 'District Hospital',
      hospitalId: 'WG00002',
      room: 'Room 03',
      contactNo: '077-3456783',
      email: 'd.wick@healthq.lk',
    ),

    // 3. Teaching Hospital (CK00003)
    Doctor(
      id: 'dr_ck_01',
      name: 'Dr. A. Wijesuriya',
      speciality: 'Paediatrics',
      hospital: 'Teaching Hospital',
      hospitalId: 'CK00003',
      room: 'Room 10',
      contactNo: '072-4567891',
      email: 'a.wijesuriya@healthq.lk',
    ),
    Doctor(
      id: 'dr_ck_02',
      name: 'Dr. P. Gunawardena',
      speciality: 'General Surgery',
      hospital: 'Teaching Hospital',
      hospitalId: 'CK00003',
      room: 'Room 12',
      contactNo: '072-4567892',
      email: 'p.gunawardena@healthq.lk',
    ),
    Doctor(
      id: 'dr_ck_03',
      name: 'Dr. H. Rathnayake',
      speciality: 'ENT Specialist',
      hospital: 'Teaching Hospital',
      hospitalId: 'CK00003',
      room: 'Room 08',
      contactNo: '072-4567893',
      email: 'h.rathnayake@healthq.lk',
    ),

    // 4. Karapitiya Hospital (SG00004)
    Doctor(
      id: 'dr_sg_01',
      name: 'Dr. C. De Silva',
      speciality: 'Oncology',
      hospital: 'Karapitiya Hospital',
      hospitalId: 'SG00004',
      room: 'Room 06',
      contactNo: '076-5678901',
      email: 'c.desilva@healthq.lk',
    ),
    Doctor(
      id: 'dr_sg_02',
      name: 'Dr. T. Mendis',
      speciality: 'Cardiology',
      hospital: 'Karapitiya Hospital',
      hospitalId: 'SG00004',
      room: 'Room 09',
      contactNo: '076-5678902',
      email: 't.mendis@healthq.lk',
    ),
    Doctor(
      id: 'dr_sg_03',
      name: 'Dr. V. Gamage',
      speciality: 'General Medicine',
      hospital: 'Karapitiya Hospital',
      hospitalId: 'SG00004',
      room: 'Room 11',
      contactNo: '076-5678903',
      email: 'v.gamage@healthq.lk',
    ),

    // 5. Jaffna Base Hospital (NJ00005)
    Doctor(
      id: 'dr_nj_01',
      name: 'Dr. R. Kumar',
      speciality: 'General Medicine',
      hospital: 'Jaffna Base Hospital',
      hospitalId: 'NJ00005',
      room: 'Room 03',
      contactNo: '075-6789012',
      email: 'r.kumar@healthq.lk',
    ),
    Doctor(
      id: 'dr_nj_02',
      name: 'Dr. S. Sivakumar',
      speciality: 'Paediatrics',
      hospital: 'Jaffna Base Hospital',
      hospitalId: 'NJ00005',
      room: 'Room 05',
      contactNo: '075-6789013',
      email: 's.sivakumar@healthq.lk',
    ),
    Doctor(
      id: 'dr_nj_03',
      name: 'Dr. K. Thanabalasingam',
      speciality: 'Cardiology',
      hospital: 'Jaffna Base Hospital',
      hospitalId: 'NJ00005',
      room: 'Room 02',
      contactNo: '075-6789014',
      email: 'k.thana@healthq.lk',
    ),

    // 6. Kurunegala Hospital (NK00006)
    Doctor(
      id: 'dr_nk_01',
      name: 'Dr. W. Bandara',
      speciality: 'Orthopaedics',
      hospital: 'Kurunegala Hospital',
      hospitalId: 'NK00006',
      room: 'Room 04',
      contactNo: '078-7890123',
      email: 'w.bandara@healthq.lk',
    ),
    Doctor(
      id: 'dr_nk_02',
      name: 'Dr. M. Senanayake',
      speciality: 'General Medicine',
      hospital: 'Kurunegala Hospital',
      hospitalId: 'NK00006',
      room: 'Room 07',
      contactNo: '078-7890124',
      email: 'm.sena@healthq.lk',
    ),
    Doctor(
      id: 'dr_nk_03',
      name: 'Dr. L. Abeykoon',
      speciality: 'Ophthalmology',
      hospital: 'Kurunegala Hospital',
      hospitalId: 'NK00006',
      room: 'Room 01',
      contactNo: '078-7890125',
      email: 'l.abeykoon@healthq.lk',
    ),
  ];

  /// Get registered doctors from Cloud Firestore ('staff' collection, 'doctors' collection,
  /// or hospital subcollections) with smart hospital filtering and deduplication.
  Future<List<Doctor>> getDoctors(String? hospitalId, {String? hospitalName}) async {
    final Map<String, Doctor> doctorsMap = {};

    // 1. Primary: Fetch registered doctors from Cloud Firestore 'staff' collection
    try {
      final staffSnap = await _db
          .collection('staff')
          .get()
          .timeout(const Duration(seconds: 8));
      for (final doc in staffSnap.docs) {
        final data = doc.data();
        final role = (data['role'] ?? '').toString().toLowerCase().trim();
        final hasDoctorName = data.containsKey('doctorName') ||
            (data['name'] ?? '').toString().toLowerCase().startsWith('dr');
        final hasDoctorRole = role == 'doctor' || role == 'doc';
        final hasDoctorId =
            (data['staffId'] ?? doc.id).toString().toUpperCase().startsWith('D');

        if (role != 'nurse' &&
            (hasDoctorRole || hasDoctorName || (hasDoctorId && role != 'admin'))) {
          final doctor = Doctor.fromMap(data, docId: doc.id);
          doctorsMap[doctor.name.toLowerCase()] = doctor;
        }
      }
    } catch (e) {
      debugPrint('Error fetching doctors from staff collection: $e');
    }

    // 2. Fetch from top-level 'doctors' collection
    try {
      final docsSnap = await _db
          .collection('doctors')
          .get()
          .timeout(const Duration(seconds: 8));
      for (final doc in docsSnap.docs) {
        final doctor = Doctor.fromDoc(doc);
        doctorsMap[doctor.name.toLowerCase()] = doctor;
      }
    } catch (e) {
      debugPrint('Error fetching doctors from doctors collection: $e');
    }

    // 3. Fetch from subcollection 'hospitals/$hospitalId/doctors' if hospitalId is specified
    if (hospitalId != null && hospitalId.isNotEmpty) {
      try {
        final subSnap = await _db
            .collection('hospitals')
            .doc(hospitalId)
            .collection('doctors')
            .get()
            .timeout(const Duration(seconds: 8));
        for (final doc in subSnap.docs) {
          final doctor = Doctor.fromDoc(doc);
          doctorsMap[doctor.name.toLowerCase()] = doctor;
        }
      } catch (e) {
        debugPrint('Error fetching doctors from hospital subcollection: $e');
      }
    }

    var allDoctors = doctorsMap.values.toList();

    final bool hasHospitalFilter = (hospitalId != null && hospitalId.isNotEmpty) ||
        (hospitalName != null && hospitalName.isNotEmpty);

    // 4. If hospital is selected, strictly filter doctors assigned to this hospital
    if (hasHospitalFilter) {
      final targetHosp = (hospitalName ?? hospitalId ?? '').trim();
      final targetCode = Hospital.resolveHospitalCode(hospitalId ?? hospitalName);

      final filtered = allDoctors.where((d) {
        return Hospital.matchesHospital(
          targetHospital: targetHosp,
          targetCode: targetCode,
          itemHospital: d.hospital,
          itemCode: d.hospitalId,
        );
      }).toList();

      if (filtered.isNotEmpty) {
        allDoctors = filtered;
      } else {
        // Fall back to sample doctors STRICTLY for this hospital only
        final sampleForHosp = _sampleHospitalDoctors.where((d) {
          return Hospital.matchesHospital(
            targetHospital: targetHosp,
            targetCode: targetCode,
            itemHospital: d.hospital,
            itemCode: d.hospitalId,
          );
        }).toList();

        allDoctors = sampleForHosp;
      }
    } else {
      // 5. Fallback sample registered doctors ONLY when no hospital filter is specified
      if (allDoctors.isEmpty) {
        allDoctors = List.from(_sampleHospitalDoctors);
      }
    }

    // Sort alphabetically by doctor name
    allDoctors.sort((a, b) => a.name.compareTo(b.name));
    return allDoctors;
  }

  /// Get sample doctors for a specific hospital (used for seeding or fallback)
  List<Doctor> getSampleDoctorsForHospital(String? hospitalNameOrId) {
    if (hospitalNameOrId == null || hospitalNameOrId.trim().isEmpty) {
      return List.unmodifiable(_sampleHospitalDoctors);
    }
    final targetHosp = hospitalNameOrId.trim();
    final targetCode = Hospital.resolveHospitalCode(targetHosp);
    final docs = _sampleHospitalDoctors.where((d) {
      return Hospital.matchesHospital(
        targetHospital: targetHosp,
        targetCode: targetCode,
        itemHospital: d.hospital,
        itemCode: d.hospitalId,
      );
    }).toList();
    return docs;
  }

  /// Fills each doctor's `waiting` with the current queue count for that date/session.
  Future<void> loadWaiting(
      String? hid, List<Doctor> docs, String date, String session) async {
    if (docs.isEmpty) return;
    try {
      final effectiveHid = (hid == null || hid.isEmpty) ? 'general' : hid;
      final snaps = await Future.wait([
        for (final d in docs)
          _db
              .collection('queues')
              .doc(queueKey(
                  d.hospital.isNotEmpty ? d.hospital : effectiveHid,
                  d.id,
                  date,
                  session))
              .get(),
      ]);
      for (var i = 0; i < docs.length; i++) {
        docs[i].waiting = (snaps[i].data()?['count'] ?? 0) as int;
      }
    } catch (e) {
      debugPrint('Error loading doctor waiting counts: $e');
    }
  }


  /// Books an appointment and returns the generated queue number.
  /// User ID strictly defaults to NIC number for patient identification across all systems.
  /// Runs in a transaction so two people can never get the same number.
  Future<int> book({
    required Hospital hospital,
    required Doctor doctor,
    required String date,
    required String dateLabel,
    required String session,
    required String patientName,
    required String nic,
    String? userId,
    required String dob,
    required String contact,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please log in to book an appointment');

    final cleanNic = nic.trim().toUpperCase();
    final effectiveUserId = (userId != null && userId.trim().isNotEmpty)
        ? userId.trim().toUpperCase()
        : cleanNic;

    final key = queueKey(hospital.id, doctor.id, date, session);
    final hRef = _db.collection('hospitals').doc(hospital.id);
    final qRef = _db.collection('queues').doc(key);
    final aRef = _db.collection('appointments').doc('${user.uid}_$key');
    final nRef = _db.collection('notifications').doc();
    final uRef = _db.collection('users').doc(user.uid);
    final nicDocRef = _db.collection('users').doc(effectiveUserId);

    // Same format as the register screen: DD/MM/YYYY
    final dobDisplay = dob.length == 10 && dob.contains('-')
        ? '${dob.substring(8, 10)}/${dob.substring(5, 7)}/${dob.substring(0, 4)}'
        : dob;

    return _db.runTransaction<int>((tx) async {
      final h = await tx.get(hRef);
      if (h.data()?['status'] == 'full') {
        throw Exception('This hospital OPD is full');
      }
      if ((await tx.get(aRef)).exists) {
        throw Exception(
            'You already have an appointment with this doctor for that session');
      }
      final q = await tx.get(qRef);
      final u = await tx.get(uRef);
      final next = ((q.data()?['count'] ?? 0) as int) + 1;

      tx.set(qRef, {
        'count': next,
        'hospitalId': hospital.id,
        'doctorId': doctor.id,
        'date': date,
        'session': session,
      });

      final cleanHospCode = hospital.identificationNo.isNotEmpty &&
              RegExp(r'^[A-Za-z]{2}\d{5}$').hasMatch(hospital.identificationNo.trim())
          ? hospital.identificationNo.trim().toUpperCase()
          : Hospital.resolveHospitalCode('${hospital.id}_${hospital.name}');

      // Appointments are initially 'pending' awaiting confirmation by hospital OPD staff
      const initialStatus = 'pending';

      // Saved with User ID strictly defaulting to NIC
      tx.set(aRef, {
        'userId': effectiveUserId,
        'patientId': effectiveUserId,
        'authUid': user.uid,
        'userUid': user.uid,
        'hospitalId': hospital.id,
        'hospitalIdentificationNo': cleanHospCode,
        'hospitalCode': cleanHospCode,
        'hospitalName': hospital.name,
        'hospital': hospital.name,
        'doctorId': doctor.id,
        'doctorName': doctor.name,
        'doctor': doctor.name,
        'speciality': doctor.speciality,
        'date': date,
        'dateLabel': dateLabel,
        'session': session,
        'patientName': patientName,
        'nic': cleanNic,
        'dob': dob,
        'contact': contact,
        'queueNo': next,
        'status': initialStatus,
        'isConfirmedByStaff': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(nRef, {
        'userId': user.uid,
        'patientUserId': effectiveUserId,
        'title': 'Appointment Request Submitted',
        'body':
            'Your appointment request at ${hospital.name} on $dateLabel is submitted (Pending Confirmation). Queue token #$next reserved. Hospital OPD staff will review and confirm.',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Fill missing profile fields in users/{user.uid}
      final um = u.data() ?? {};
      final fill = <String, dynamic>{
        'userId': effectiveUserId,
        'nic': cleanNic,
        'patientId': effectiveUserId,
        if ((um['fullName'] ?? '') == '') 'fullName': patientName,
        if ((um['dob'] ?? '') == '') 'dob': dobDisplay,
        if ((um['contactNo'] ?? um['contact'] ?? '') == '') 'contactNo': contact,
        if ((um['email'] ?? '') == '' && user.email != null) 'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (fill.isNotEmpty) tx.set(uRef, fill, SetOptions(merge: true));

      // Also ensure profile indexed by NIC exists
      tx.set(nicDocRef, {
        'userId': effectiveUserId,
        'nic': cleanNic,
        'patientId': effectiveUserId,
        'authUid': user.uid,
        'uid': user.uid,
        'fullName': patientName,
        'dob': dobDisplay,
        'contactNo': contact,
        'email': user.email ?? (um['email'] ?? ''),
        'role': 'patient',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return next;
    });
  }

  Stream<List<AppointmentRecord>> myAppointments() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    final uid = user.uid;

    return _db.collection('users').doc(uid).snapshots().asyncExpand((userDoc) {
      final userData = userDoc.data() ?? {};
      final userNic = (userData['nic'] ?? userData['userId'] ?? '').toString().trim().toUpperCase();
      return _db.collection('appointments').snapshots().map((s) {
        final list = s.docs
            .map(AppointmentRecord.fromDoc)
            .where((a) => a.matchesUser(uid, userNic))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    });
  }

  /// Confirms an appointment by OPD management staff
  Future<void> confirmAppointment({
    required String appointmentId,
    String? staffName,
    String? staffHospital,
  }) async {
    final docRef = _db.collection('appointments').doc(appointmentId);
    final doc = await docRef.get();
    if (!doc.exists) throw Exception('Appointment not found');
    final data = doc.data() ?? {};

    await docRef.update({
      'status': 'confirmed',
      'isConfirmedByStaff': true,
      'confirmedByStaffName': staffName ?? 'OPD Management',
      'confirmedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Notify patient in real-time
    final targetUid = (data['authUid'] ?? data['userUid'] ?? data['userId'] ?? '').toString();
    if (targetUid.isNotEmpty) {
      await _db.collection('notifications').add({
        'userId': targetUid,
        'patientUserId': data['userId'] ?? '',
        'title': 'Appointment Confirmed!',
        'body':
            'Your appointment with ${data['doctorName'] ?? 'Doctor'} at ${data['hospitalName'] ?? 'the hospital'} on ${data['dateLabel'] ?? data['date'] ?? ''} has been confirmed by OPD Management. Queue #${data['queueNo'] ?? ''}.',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Rejects or cancels an appointment by OPD management staff
  Future<void> cancelAppointment({
    required String appointmentId,
    String? reason,
    String? cancelNotes,
    String? staffName,
  }) async {
    final docRef = _db.collection('appointments').doc(appointmentId);
    final doc = await docRef.get();
    if (!doc.exists) throw Exception('Appointment not found');
    final data = doc.data() ?? {};

    final effectiveReason = reason ?? 'Cancelled by OPD Management';
    await docRef.update({
      'status': 'cancelled',
      'cancelReason': effectiveReason,
      if (cancelNotes != null && cancelNotes.trim().isNotEmpty)
        'cancelNotes': cancelNotes.trim(),
      if (staffName != null && staffName.trim().isNotEmpty)
        'cancelledByStaffName': staffName.trim(),
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Notify patient
    final targetUid = (data['authUid'] ?? data['userUid'] ?? data['userId'] ?? '').toString();
    if (targetUid.isNotEmpty) {
      await _db.collection('notifications').add({
        'userId': targetUid,
        'patientUserId': data['userId'] ?? '',
        'title': 'Appointment Update',
        'body':
            'Your appointment at ${data['hospitalName'] ?? 'the hospital'} on ${data['dateLabel'] ?? data['date'] ?? ''} has been cancelled: $effectiveReason.',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<UserProfile> myProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(const UserProfile());
    return _db.collection('users').doc(user.uid).snapshots().map((d) {
      final m = d.data() ?? {};
      final nic = (m['nic'] ?? '').toString();
      final userId = (m['userId'] ?? (nic.isNotEmpty ? nic : '')).toString();
      return UserProfile(
        userId: userId,
        fullName: m['fullName'] ?? user.displayName ?? '',
        nic: nic.isNotEmpty ? nic : userId,
        dob: m['dob'] ?? '',
        contact: m['contactNo'] ?? m['contact'] ?? user.phoneNumber ?? '',
        email: user.email ?? m['email'] ?? '',
        photoUrl: (m['photoUrl'] ?? user.photoURL ?? '').toString(),
        photoBase64: (m['photoBase64'] ?? '').toString(),
      );
    });
  }

  /// Update patient profile with authentication enforcement when changing email or contact.
  Future<void> updateProfile({
    required String fullName,
    required String nic,
    required String dob,
    required String email,
    required String contact,
    String? photoBase64,
    String? photoUrl,
    String? currentPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No logged in user found.');

    final newEmail = email.trim();
    final oldEmail = (user.email ?? '').trim();
    final emailChanged =
        newEmail.isNotEmpty && newEmail.toLowerCase() != oldEmail.toLowerCase();

    // Check existing contact from Firestore
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final existingData = userDoc.data() ?? {};
    final oldContact = (existingData['contactNo'] ??
            existingData['contact'] ??
            '')
        .toString()
        .trim();
    final contactChanged =
        contact.trim().isNotEmpty && contact.trim() != oldContact;

    // Requirement: if update gmail or phone no, authentication is required
    if (emailChanged || contactChanged) {
      if (currentPassword == null || currentPassword.isEmpty) {
        throw Exception(
            'Current password is required to verify your identity before updating ${emailChanged && contactChanged ? 'email and contact number' : emailChanged ? 'email address' : 'contact number'}.');
      }

      if (user.email != null && user.email!.isNotEmpty) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        try {
          await user.reauthenticateWithCredential(cred);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            throw Exception(
                'Authentication failed: Incorrect password. Please try again.');
          }
          throw Exception('Authentication failed: ${e.message}');
        }
      }

      if (emailChanged) {
        try {
          await user.verifyBeforeUpdateEmail(newEmail);
        } catch (e) {
          debugPrint('verifyBeforeUpdateEmail note: $e');
        }
      }
    }

    if (fullName.isNotEmpty) {
      await user.updateDisplayName(fullName);
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      await user.updatePhotoURL(photoUrl);
    }

    final effectiveUserId = nic.isNotEmpty ? nic : user.uid;
    final updateData = <String, dynamic>{
      'userId': effectiveUserId,
      'nic': nic,
      'patientId': effectiveUserId,
      'fullName': fullName,
      'dob': dob,
      'email': newEmail.isNotEmpty ? newEmail : oldEmail,
      'contactNo': contact,
      'contact': contact,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (photoBase64 != null) updateData['photoBase64'] = photoBase64;
    if (photoUrl != null) updateData['photoUrl'] = photoUrl;

    await _db
        .collection('users')
        .doc(user.uid)
        .set(updateData, SetOptions(merge: true));
    if (nic.isNotEmpty) {
      await _db
          .collection('users')
          .doc(nic)
          .set(updateData, SetOptions(merge: true));
    }
  }

  /// Permanently delete patient account after re-authenticating with password.
  Future<void> deleteAccount(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No logged in user found.');

    if (user.email != null && user.email!.isNotEmpty) {
      if (password.isEmpty) {
        throw Exception('Password is required to confirm account deletion.');
      }
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      try {
        await user.reauthenticateWithCredential(cred);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          throw Exception('Incorrect password. Account deletion cancelled.');
        }
        throw Exception('Authentication failed: ${e.message}');
      }
    }

    final uid = user.uid;
    final userDoc = await _db.collection('users').doc(uid).get();
    final nic = (userDoc.data()?['nic'] ?? '').toString();

    // 1. Delete user profile from Firestore
    await _db.collection('users').doc(uid).delete();
    if (nic.isNotEmpty) {
      await _db.collection('users').doc(nic).delete();
    }

    // 2. Mark appointments cancelled
    final appts = await _db
        .collection('appointments')
        .where('authUid', isEqualTo: uid)
        .get();
    for (final doc in appts.docs) {
      await doc.reference.update({'status': 'cancelled'});
    }

    // 3. Delete from Firebase Auth
    await user.delete();
  }

  Stream<List<NotificationItem>> myNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final list = s.docs.map(NotificationItem.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Run ONCE (e.g. from main.dart) to sync hospitals (with identificationNo)
  /// and each hospital's sample doctors in Cloud Firestore.
  Future<void> seedIfEmpty() async {
    try {
      final batch = _db.batch();

      // 1. Seed / Update all hospitals with their Hospital Identification No
      // Format: Province 1st char + District 1st char + 5 digits (e.g. WC00001)
      for (final h in _fallbackHospitals) {
        final ref = _db.collection('hospitals').doc(h.id);
        batch.set(ref, {
          'id': h.id,
          'identificationNo': h.identificationNo,
          'hospitalId': h.identificationNo,
          'hospitalCode': h.identificationNo,
          'name': h.name,
          'province': h.province,
          'district': h.district,
          'city': h.city,
          'status': h.status,
          'slotsLeft': h.slotsLeft,
          'address': h.address,
          'contactNo': h.contactNo,
          'openingHours': h.openingHours,
          'type': h.type,
          'departments': h.departments,
        }, SetOptions(merge: true));

        // Also index under identificationNo so direct lookups by identificationNo work instantly
        final idRef = _db.collection('hospitals').doc(h.identificationNo);
        batch.set(idRef, {
          'id': h.id,
          'identificationNo': h.identificationNo,
          'hospitalId': h.identificationNo,
          'hospitalCode': h.identificationNo,
          'name': h.name,
          'province': h.province,
          'district': h.district,
          'city': h.city,
          'status': h.status,
          'slotsLeft': h.slotsLeft,
          'address': h.address,
          'contactNo': h.contactNo,
          'openingHours': h.openingHours,
          'type': h.type,
          'departments': h.departments,
        }, SetOptions(merge: true));
      }
      await batch.commit();

      // 2. Seed sample doctors for EACH hospital into Firestore
      final docBatch = _db.batch();
      for (final doc in _sampleHospitalDoctors) {
        final hospDocId = _fallbackHospitals
            .where((h) => h.identificationNo == doc.hospitalId || h.name == doc.hospital)
            .map((h) => h.id)
            .firstOrNull ?? 'city_general';

        // A. Subcollection hospitals/{hospitalDocId}/doctors/{docId}
        final subRef1 = _db
            .collection('hospitals')
            .doc(hospDocId)
            .collection('doctors')
            .doc(doc.id);
        docBatch.set(subRef1, {
          'id': doc.id,
          'name': doc.name,
          'speciality': doc.speciality,
          'specialty': doc.speciality,
          'hospital': doc.hospital,
          'hospitalId': doc.hospitalId,
          'room': doc.room,
          'contactNo': doc.contactNo,
          'email': doc.email,
        }, SetOptions(merge: true));

        // B. Subcollection hospitals/{identificationNo}/doctors/{docId}
        if (doc.hospitalId != null && doc.hospitalId!.isNotEmpty) {
          final subRef2 = _db
              .collection('hospitals')
              .doc(doc.hospitalId!)
              .collection('doctors')
              .doc(doc.id);
          docBatch.set(subRef2, {
            'id': doc.id,
            'name': doc.name,
            'speciality': doc.speciality,
            'specialty': doc.speciality,
            'hospital': doc.hospital,
            'hospitalId': doc.hospitalId,
            'room': doc.room,
            'contactNo': doc.contactNo,
            'email': doc.email,
          }, SetOptions(merge: true));
        }

        // C. Top-level 'doctors' collection
        final topDocRef = _db.collection('doctors').doc(doc.id);
        docBatch.set(topDocRef, {
          'id': doc.id,
          'name': doc.name,
          'speciality': doc.speciality,
          'specialty': doc.speciality,
          'hospital': doc.hospital,
          'hospitalId': doc.hospitalId,
          'room': doc.room,
          'contactNo': doc.contactNo,
          'email': doc.email,
        }, SetOptions(merge: true));

        // D. Top-level 'staff' collection for doctor login
        final staffRef = _db.collection('staff').doc(doc.id);
        docBatch.set(staffRef, {
          'staffId': doc.id.toUpperCase(),
          'name': doc.name,
          'doctorName': doc.name,
          'role': 'doctor',
          'speciality': doc.speciality,
          'specialty': doc.speciality,
          'hospital': doc.hospital,
          'hospitalId': doc.hospitalId,
          'room': doc.room,
          'contactNo': doc.contactNo,
          'email': doc.email,
        }, SetOptions(merge: true));
      }
      await docBatch.commit();
      debugPrint('BookingService.seedIfEmpty: Successfully seeded all hospitals with identification numbers and sample doctors.');
    } catch (e) {
      debugPrint('BookingService.seedIfEmpty skipped or failed: $e');
    }
  }
}