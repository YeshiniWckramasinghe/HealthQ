import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffModel {
  final String staffId;
  final String name;
  final String email;
  final String contactNo;
  final String role; // 'doctor' or 'nurse'
  final String hospital;
  final String? department;
  final String? specialty;
  final String? room;

  StaffModel({
    required this.staffId,
    required this.name,
    required this.email,
    required this.contactNo,
    required this.role,
    required this.hospital,
    this.department,
    this.specialty,
    this.room,
  });

  factory StaffModel.fromMap(Map<String, dynamic> data) {
    return StaffModel(
      staffId: data['staffId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      contactNo: data['contactNo'] ?? '',
      role: (data['role'] ?? '').toString().toLowerCase(),
      hospital: data['hospital'] ?? 'Government Hospital — Colombo',
      department: data['department'],
      specialty: data['specialty'],
      room: data['room'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staffId': staffId,
      'name': name,
      'email': email,
      'contactNo': contactNo,
      'role': role,
      'hospital': hospital,
      'department': department,
      'specialty': specialty,
      'room': room,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class StaffAuthService {
  static final StaffAuthService instance = StaffAuthService._();
  StaffAuthService._();

  // In-memory fallback dataset for instant, reliable operation
  final List<Map<String, dynamic>> _defaultStaff = [
    {
      'staffId': 'DOC1001-0001',
      'name': 'Dr. S. Perera',
      'email': 'dr.perera@healthq.gov.lk',
      'contactNo': '0712344582',
      'password': 'Password123!',
      'role': 'doctor',
      'hospital': 'Government Hospital — Colombo',
      'department': 'Cardiology OPD',
      'specialty': 'Cardiology',
      'room': 'Room 01',
    },
    {
      'staffId': 'NUR1002-0011',
      'name': 'Nurse K. Silva',
      'email': 'nurse.silva@healthq.gov.lk',
      'contactNo': '0771234582',
      'password': 'Password123!',
      'role': 'nurse',
      'hospital': 'Government Hospital — Colombo',
      'department': 'General Medicine OPD',
      'specialty': 'General OPD',
      'room': 'Triage A',
    },
  ];

  /// Ensure default staff accounts are seeded into Cloud Firestore
  Future<void> seedDefaultStaffIfNeeded() async {
    try {
      final staffRef = FirebaseFirestore.instance.collection('staff');
      for (final staff in _defaultStaff) {
        final doc = await staffRef.doc(staff['staffId']).get();
        if (!doc.exists) {
          await staffRef.doc(staff['staffId']).set({
            ...staff,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('Seeded staff member: ${staff['staffId']} (${staff['role']})');
        }
      }
    } catch (e) {
      debugPrint('Staff seed note: $e');
    }
  }

  /// Authenticate staff member by hospital, staffId, password, and role
  Future<StaffModel?> authenticateStaff({
    required String hospital,
    required String staffId,
    required String password,
    required String role,
  }) async {
    final cleanStaffId = staffId.trim().toUpperCase();
    final cleanRole = role.trim().toLowerCase();
    final cleanPassword = password.trim();

    // 1. Try querying Firestore 'staff' collection
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('staff')
          .where('staffId', isEqualTo: cleanStaffId)
          .where('role', isEqualTo: cleanRole)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        final dbPassword = (data['password'] ?? '').toString();

        if (dbPassword == cleanPassword) {
          return StaffModel.fromMap(data);
        }
      }
    } catch (e) {
      debugPrint('Firestore staff auth error: $e');
    }

    // 2. Fallback check against in-memory defaults
    for (final staff in _defaultStaff) {
      final matchId = (staff['staffId'] as String).toUpperCase() == cleanStaffId ||
          (staff['email'] as String).toLowerCase() == staffId.trim().toLowerCase();
      final matchRole = (staff['role'] as String).toLowerCase() == cleanRole;
      final matchPass = (staff['password'] as String) == cleanPassword;

      if (matchId && matchRole && matchPass) {
        return StaffModel.fromMap(staff);
      }
    }

    return null;
  }

  /// Find staff member by Staff ID or Email
  Future<StaffModel?> findStaff(String staffIdOrEmail) async {
    final cleanInput = staffIdOrEmail.trim().toUpperCase();
    final staffRef = FirebaseFirestore.instance.collection('staff');

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      if (cleanInput.contains('@')) {
        snapshot = await staffRef
            .where('email', isEqualTo: staffIdOrEmail.trim().toLowerCase())
            .limit(1)
            .get();
      } else {
        snapshot = await staffRef
            .where('staffId', isEqualTo: cleanInput)
            .limit(1)
            .get();
      }

      if (snapshot.docs.isNotEmpty) {
        return StaffModel.fromMap(snapshot.docs.first.data());
      }
    } catch (e) {
      debugPrint('Firestore find staff error: $e');
    }

    // Fallback search in memory
    for (final staff in _defaultStaff) {
      if ((staff['staffId'] as String).toUpperCase() == cleanInput ||
          (staff['email'] as String).toLowerCase() == staffIdOrEmail.trim().toLowerCase()) {
        return StaffModel.fromMap(staff);
      }
    }

    return null;
  }

  /// Update password for staff member in database
  Future<bool> updatePassword({
    required String staffIdOrEmail,
    required String newPassword,
  }) async {
    final cleanInput = staffIdOrEmail.trim().toUpperCase();

    try {
      // Find staff doc
      final staffRef = FirebaseFirestore.instance.collection('staff');
      QuerySnapshot<Map<String, dynamic>> snapshot;

      if (cleanInput.contains('@')) {
        snapshot = await staffRef
            .where('email', isEqualTo: staffIdOrEmail.trim().toLowerCase())
            .limit(1)
            .get();
      } else {
        snapshot = await staffRef
            .where('staffId', isEqualTo: cleanInput)
            .limit(1)
            .get();
      }

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'password': newPassword.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      debugPrint('Firestore update password error: $e');
    }

    // Fallback update in local memory
    for (final staff in _defaultStaff) {
      if ((staff['staffId'] as String).toUpperCase() == cleanInput ||
          (staff['email'] as String).toLowerCase() == staffIdOrEmail.trim().toLowerCase()) {
        staff['password'] = newPassword.trim();
        return true;
      }
    }

    return true;
  }
}
