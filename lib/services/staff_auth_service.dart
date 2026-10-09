import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import 'booking_service.dart';

class StaffModel {
  final String staffId;
  final String name;
  final String email;
  final String contactNo;
  final String role; // 'doctor' or 'nurse'
  final String hospital;
  final String? hospitalId;
  final String? hospitalCode;
  final String? department;
  final String? specialty;
  final String? room;
  final String? shift;
  final String? photoUrl;
  final String? photoBase64;

  StaffModel({
    required this.staffId,
    required this.name,
    required this.email,
    required this.contactNo,
    required this.role,
    required this.hospital,
    this.hospitalId,
    this.hospitalCode,
    this.department,
    this.specialty,
    this.room,
    this.shift,
    this.photoUrl,
    this.photoBase64,
  });

  bool get hasProfilePic =>
      (photoBase64 != null && photoBase64!.isNotEmpty) ||
      (photoUrl != null && photoUrl!.isNotEmpty);

  String get initials {
    if (name.trim().isEmpty) return 'S';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  factory StaffModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return StaffModel.fromMap(data, docId: doc.id);
  }

  factory StaffModel.fromMap(Map<String, dynamic> data, {String? docId}) {
    final rawStaffId =
        data['staffId'] ?? data['staff_id'] ?? data['id'] ?? docId ?? '';
    final rawName = data['name'] ??
        data['fullName'] ??
        data['doctorName'] ??
        data['nurseName'] ??
        'Staff Member';
    final rawEmail = data['email'] ?? data['mail'] ?? '';
    final rawPhone =
        data['contactNo'] ?? data['phone'] ?? data['mobile'] ?? data['contact'] ?? '';
    final rawRole = (data['role'] ?? '').toString().trim().toLowerCase();
    final rawHospital =
        data['hospital'] ?? data['hospitalName'] ?? 'City General Hospital';
    final rawHospCode = (data['hospitalCode'] ??
            data['hospitalIdentificationNo'] ??
            data['hospitalId'] ??
            '')
        .toString()
        .trim();
    final resolvedHospCode = rawHospCode.isNotEmpty
        ? rawHospCode.toUpperCase()
        : Hospital.resolveHospitalCode(rawHospital.toString());

    return StaffModel(
      staffId: rawStaffId.toString().trim(),
      name: rawName.toString().trim(),
      email: rawEmail.toString().trim(),
      contactNo: rawPhone.toString().trim(),
      role: rawRole,
      hospital: rawHospital.toString().trim(),
      hospitalId: resolvedHospCode.isNotEmpty ? resolvedHospCode : null,
      hospitalCode: resolvedHospCode.isNotEmpty ? resolvedHospCode : null,
      department: data['department']?.toString().trim() ??
          data['unit']?.toString().trim(),
      specialty: data['specialty']?.toString().trim() ??
          data['speciality']?.toString().trim(),
      room: data['room']?.toString().trim() ?? data['roomNo']?.toString().trim(),
      shift: data['shift']?.toString().trim() ?? 'Morning (06:00-14:00)',
      photoUrl: data['photoUrl']?.toString().trim(),
      photoBase64: data['photoBase64']?.toString().trim(),
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
      'hospitalId': hospitalId,
      'hospitalCode': hospitalCode,
      'department': department,
      'specialty': specialty,
      'room': room,
      'shift': shift,
      'photoUrl': photoUrl,
      'photoBase64': photoBase64,
    };
  }

  StaffModel copyWith({
    String? staffId,
    String? name,
    String? email,
    String? contactNo,
    String? role,
    String? hospital,
    String? hospitalId,
    String? hospitalCode,
    String? department,
    String? specialty,
    String? room,
    String? shift,
    String? photoUrl,
    String? photoBase64,
  }) {
    return StaffModel(
      staffId: staffId ?? this.staffId,
      name: name ?? this.name,
      email: email ?? this.email,
      contactNo: contactNo ?? this.contactNo,
      role: role ?? this.role,
      hospital: hospital ?? this.hospital,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalCode: hospitalCode ?? this.hospitalCode,
      department: department ?? this.department,
      specialty: specialty ?? this.specialty,
      room: room ?? this.room,
      shift: shift ?? this.shift,
      photoUrl: photoUrl ?? this.photoUrl,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }
}

class StaffAuthService {
  static final StaffAuthService instance = StaffAuthService._();
  StaffAuthService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StaffModel? _currentStaff;
  StaffModel? get currentStaff => _currentStaff;

  void setCurrentStaff(StaffModel? staff) {
    _currentStaff = staff;
  }

  /// Ensure Firebase is ready and attempt anonymous auth if not logged in
  Future<void> _prepareFirebaseSession() async {
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

      // 4. Employee not found in database
      if (targetDoc == null || !targetDoc.exists || targetDoc.data() == null) {
        return StaffAuthResult.fail(
          'Staff ID "$cleanStaffId" was not found in the hospital database. Please verify your ID or contact your hospital administrator.',
        );
      }

      final data = targetDoc.data()!;

      // 5. Verify Role in database
      final dbRole = (data['role'] ?? '').toString().trim().toLowerCase();
      if (dbRole.isNotEmpty && dbRole != cleanRole) {
        final displayDbRole = dbRole[0].toUpperCase() + dbRole.substring(1);
        final displaySelectedRole =
            cleanRole[0].toUpperCase() + cleanRole.substring(1);
        return StaffAuthResult.fail(
          'Role mismatch: Account "$cleanStaffId" is registered as a $displayDbRole in the hospital database, but $displaySelectedRole was selected.',
        );
      }

      // 6. Verify Password in database
      final dbPassword =
          (data['password'] ?? data['pass'] ?? '').toString().trim();
      if (dbPassword.isEmpty) {
        return StaffAuthResult.fail(
          'No password set for this staff account. Please contact hospital administration or use Forgot Password.',
        );
      }

      if (dbPassword != cleanPassword) {
        return StaffAuthResult.fail(
          'Incorrect password for staff account "$cleanStaffId". Please check your password or reset it.',
        );
      }

      // 7. Parse model strictly from real Firestore data
      final staffModel = StaffModel.fromDoc(targetDoc);
      _currentStaff = staffModel;
      return StaffAuthResult.ok(staffModel);
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
      StaffModel? found;

      // 1. Direct document ID lookup
      final docUpper = await staffRef.doc(cleanInput.toUpperCase()).get();
      if (docUpper.exists && docUpper.data() != null) {
        found = StaffModel.fromDoc(docUpper);
      } else {
        final docDirect = await staffRef.doc(cleanInput).get();
        if (docDirect.exists && docDirect.data() != null) {
          found = StaffModel.fromDoc(docDirect);
        }
      }

      // 2. Query email
      if (found == null && cleanInput.contains('@')) {
        final snapshot = await staffRef
            .where('email', isEqualTo: cleanInput.toLowerCase())
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          found = StaffModel.fromDoc(snapshot.docs.first);
        }
      }

      // 3. Query staffId field
      if (found == null) {
        final snapUpper = await staffRef
            .where('staffId', isEqualTo: cleanInput.toUpperCase())
            .limit(1)
            .get();
        if (snapUpper.docs.isNotEmpty) {
          found = StaffModel.fromDoc(snapUpper.docs.first);
        } else {
          final snap = await staffRef
              .where('staffId', isEqualTo: cleanInput)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) {
            found = StaffModel.fromDoc(snap.docs.first);
          }
        }
      }

      if (found != null && _currentStaff == null) {
        _currentStaff = found;
      }
      return found;
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

  /// Update profile photo (Base64 or URL) for staff member in Cloud Firestore
  Future<bool> updateStaffProfilePhoto({
    required String staffId,
    required String photoData,
  }) async {
    final cleanInput = staffId.trim();
    if (cleanInput.isEmpty) return false;

    await _prepareFirebaseSession();
    final staffRef = _db.collection('staff');

    try {
      final updateData = {
        'photoBase64': photoData,
        'photoUrl': photoData.startsWith('http') ? photoData : '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 1. Direct doc lookup
      final docUpper = await staffRef.doc(cleanInput.toUpperCase()).get();
      if (docUpper.exists) {
        await docUpper.reference.update(updateData);
        return true;
      }

      final docDirect = await staffRef.doc(cleanInput).get();
      if (docDirect.exists) {
        await docDirect.reference.update(updateData);
        return true;
      }

      // 2. Query by staffId field
      final snapUpper = await staffRef
          .where('staffId', isEqualTo: cleanInput.toUpperCase())
          .limit(1)
          .get();
      if (snapUpper.docs.isNotEmpty) {
        await snapUpper.docs.first.reference.update(updateData);
        return true;
      }

      final snap = await staffRef
          .where('staffId', isEqualTo: cleanInput)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update(updateData);
        return true;
      }

      // If document doesn't exist yet, create a merged doc
      await staffRef.doc(cleanInput.toUpperCase()).set(updateData, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Firestore update staff profile photo error: $e');
    }

    return false;
  }

  bool _isPermissionDeniedError(dynamic e) {
    final str = e.toString().toLowerCase();
    return str.contains('permission-denied') ||
        str.contains('permission_denied') ||
        str.contains('insufficient permissions');
  }
}
