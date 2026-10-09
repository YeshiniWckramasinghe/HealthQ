import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class StaffAuthResult {
  final bool success;
  final StaffModel? staff;
  final String? errorMessage;
  final bool isPermissionDenied;

  const StaffAuthResult({
    required this.success,
    this.staff,
    this.errorMessage,
    this.isPermissionDenied = false,
  });

  factory StaffAuthResult.ok(StaffModel staff) =>
      StaffAuthResult(success: true, staff: staff);

  factory StaffAuthResult.fail(String error,
          {bool isPermissionDenied = false}) =>
      StaffAuthResult(
        success: false,
        errorMessage: error,
        isPermissionDenied: isPermissionDenied,
      );
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
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint('Firebase initialization check: $e');
    }

    // If unauthenticated, try signing in anonymously so request.auth != null
    // in case Firestore rules require authenticated requests.
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint(
            'Signed in anonymously for staff session: ${FirebaseAuth.instance.currentUser?.uid}');
      } catch (authError) {
        // Safe to ignore if anonymous sign-in is disabled in Firebase console
        debugPrint('Anonymous auth attempt note: $authError');
      }
    }
  }

  /// Fetch hospital names dynamically from Firestore 'hospitals' collection
  Future<List<String>> fetchHospitals() async {
    await _prepareFirebaseSession();
    try {
      final snapshot = await _db
          .collection('hospitals')
          .get()
          .timeout(const Duration(seconds: 8));
      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          final name = data['name'] ?? data['hospitalName'] ?? doc.id;
          return name.toString().trim();
        }).where((n) => n.isNotEmpty).toSet().toList();
        list.sort();
        return list;
      }
    } catch (e) {
      debugPrint('Error fetching hospitals from database: $e');
    }
    return [];
  }

  /// Authenticate staff member strictly against Cloud Firestore 'staff' collection.
  Future<StaffAuthResult> authenticateStaff({
    required String hospital,
    required String staffId,
    required String password,
    required String role,
  }) async {
    final cleanStaffId = staffId.trim();
    final cleanRole = role.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanStaffId.isEmpty || cleanPassword.isEmpty) {
      return StaffAuthResult.fail('Please enter both Staff ID and Password.');
    }

    await _prepareFirebaseSession();

    try {
      final staffRef = _db.collection('staff');
      DocumentSnapshot<Map<String, dynamic>>? targetDoc;

      // 1. Direct document ID lookup (handles document ID matching staff ID)
      try {
        final directDocUpper = await staffRef
            .doc(cleanStaffId.toUpperCase())
            .get()
            .timeout(const Duration(seconds: 10));
        if (directDocUpper.exists && directDocUpper.data() != null) {
          targetDoc = directDocUpper;
        } else {
          final directDoc = await staffRef
              .doc(cleanStaffId)
              .get()
              .timeout(const Duration(seconds: 10));
          if (directDoc.exists && directDoc.data() != null) {
            targetDoc = directDoc;
          }
        }
      } catch (e) {
        if (_isPermissionDeniedError(e)) rethrow;
        debugPrint('Direct doc lookup note: $e');
      }

      // 2. Query by 'staffId' field (uppercase or exact)
      if (targetDoc == null) {
        try {
          final qUpper = await staffRef
              .where('staffId', isEqualTo: cleanStaffId.toUpperCase())
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 10));
          if (qUpper.docs.isNotEmpty) {
            targetDoc = qUpper.docs.first;
          } else {
            final qExact = await staffRef
                .where('staffId', isEqualTo: cleanStaffId)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 10));
            if (qExact.docs.isNotEmpty) {
              targetDoc = qExact.docs.first;
            }
          }
        } catch (e) {
          if (_isPermissionDeniedError(e)) rethrow;
          debugPrint('StaffId query note: $e');
        }
      }

      // 3. Query by 'email' field if user entered an email address
      if (targetDoc == null && cleanStaffId.contains('@')) {
        try {
          final qEmail = await staffRef
              .where('email', isEqualTo: cleanStaffId.toLowerCase())
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 10));
          if (qEmail.docs.isNotEmpty) {
            targetDoc = qEmail.docs.first;
          }
        } catch (e) {
          if (_isPermissionDeniedError(e)) rethrow;
          debugPrint('Email query note: $e');
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
      if (_isPermissionDeniedError(e)) {
        return StaffAuthResult.fail(
          'Firestore Permission Denied: Cloud Firestore security rules in Firebase Console are blocking unauthenticated reads for the "staff" collection.',
          isPermissionDenied: true,
        );
      } else if (e.toString().contains('TimeoutException')) {
        return StaffAuthResult.fail(
          'Database request timed out. Please check your internet connection and try again.',
        );
      }
      return StaffAuthResult.fail(
        'Database connection error: $e',
      );
    }
  }

  /// Find staff member by Staff ID or Email strictly in Cloud Firestore
  Future<StaffModel?> findStaff(String staffIdOrEmail) async {
    final cleanInput = staffIdOrEmail.trim();
    if (cleanInput.isEmpty) return null;

    await _prepareFirebaseSession();
    final staffRef = _db.collection('staff');

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

    return null;
  }

  /// Update password for staff member strictly in Cloud Firestore
  Future<bool> updatePassword({
    required String staffIdOrEmail,
    required String newPassword,
  }) async {
    final cleanInput = staffIdOrEmail.trim();
    if (cleanInput.isEmpty) return false;

    await _prepareFirebaseSession();
    final staffRef = _db.collection('staff');

    try {
      // 1. Direct doc lookup
      final docUpper = await staffRef.doc(cleanInput.toUpperCase()).get();
      if (docUpper.exists) {
        await docUpper.reference.update({
          'password': newPassword.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }

      final docDirect = await staffRef.doc(cleanInput).get();
      if (docDirect.exists) {
        await docDirect.reference.update({
          'password': newPassword.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }

      // 2. Query by email
      if (cleanInput.contains('@')) {
        final snap = await staffRef
            .where('email', isEqualTo: cleanInput.toLowerCase())
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          await snap.docs.first.reference.update({
            'password': newPassword.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return true;
        }
      }

      // 3. Query by staffId field
      final snapUpper = await staffRef
          .where('staffId', isEqualTo: cleanInput.toUpperCase())
          .limit(1)
          .get();
      if (snapUpper.docs.isNotEmpty) {
        await snapUpper.docs.first.reference.update({
          'password': newPassword.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }

      final snap = await staffRef
          .where('staffId', isEqualTo: cleanInput)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({
          'password': newPassword.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      debugPrint('Firestore update password error: $e');
    }

    return false;
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
