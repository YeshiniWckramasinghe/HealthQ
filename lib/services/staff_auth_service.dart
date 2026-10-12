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
  final bool termsAccepted;
  final DateTime? termsAcceptedAt;

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
    this.termsAccepted = false,
    this.termsAcceptedAt,
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
    final rawStaffId = data['staffId'] ??
        data['staff_id'] ??
        data['employeeId'] ??
        data['doctorId'] ??
        data['id'] ??
        docId ??
        '';
    final rawName = data['name'] ??
        data['fullName'] ??
        data['doctorName'] ??
        data['nurseName'] ??
        'Staff Member';
    final rawEmail = data['email'] ??
        data['mail'] ??
        data['officialEmail'] ??
        '';
    final rawPhone = data['contactNo'] ??
        data['phone'] ??
        data['mobile'] ??
        data['contact'] ??
        '';
    var rawRole = (data['role'] ?? '').toString().trim().toLowerCase();
    if (rawRole.isEmpty) {
      if (data['specialty'] != null ||
          data['doctorId'] != null ||
          rawStaffId.toString().toUpperCase().startsWith('DOC')) {
        rawRole = 'doctor';
      } else if (rawStaffId.toString().toUpperCase().startsWith('NUR')) {
        rawRole = 'nurse';
      } else {
        rawRole = 'doctor';
      }
    }
    final rawHospital = data['hospital'] ??
        data['hospitalName'] ??
        data['hospital_name'] ??
        '';
    final rawHospCode = (data['hospitalCode'] ??
            data['hospitalIdentificationNo'] ??
            data['hospitalId'] ??
            '')
        .toString()
        .trim();
    final resolvedHospCode = rawHospCode.isNotEmpty
        ? rawHospCode.toUpperCase()
        : (rawHospital.toString().isNotEmpty
            ? Hospital.resolveHospitalCode(rawHospital.toString())
            : '');

    final bool rawTermsAccepted = data['termsAccepted'] == true ||
        data['isTermsAccepted'] == true ||
        data['terms_accepted'] == true;
    DateTime? rawTermsAcceptedAt;
    final dynamic rawTime = data['termsAcceptedAt'] ?? data['terms_accepted_at'];
    if (rawTime != null) {
      if (rawTime is Timestamp) {
        rawTermsAcceptedAt = rawTime.toDate();
      } else if (rawTime is DateTime) {
        rawTermsAcceptedAt = rawTime;
      } else if (rawTime is String) {
        rawTermsAcceptedAt = DateTime.tryParse(rawTime);
      }
    }

    return StaffModel(
      staffId: rawStaffId.toString().trim(),
      name: rawName.toString().trim(),
      email: rawEmail.toString().trim(),
      contactNo: rawPhone.toString().trim(),
      role: rawRole,
      hospital: rawHospital.toString().trim().isNotEmpty
          ? rawHospital.toString().trim()
          : 'City General Hospital',
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
      termsAccepted: rawTermsAccepted,
      termsAcceptedAt: rawTermsAcceptedAt,
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
      'termsAccepted': termsAccepted,
      if (termsAcceptedAt != null)
        'termsAcceptedAt': termsAcceptedAt?.toIso8601String(),
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
    bool? termsAccepted,
    DateTime? termsAcceptedAt,
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
      termsAccepted: termsAccepted ?? this.termsAccepted,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
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

  /// Checks whether a staff member has accepted terms & conditions in Firestore
  Future<bool> checkStaffTermsAccepted(String staffId) async {
    final cleanId = staffId.trim();
    if (cleanId.isEmpty) return false;

    // Check cached in-memory staff first
    if (_currentStaff != null &&
        _currentStaff!.staffId.toUpperCase() == cleanId.toUpperCase() &&
        _currentStaff!.termsAccepted) {
      return true;
    }

    await _prepareFirebaseSession();
    try {
      final docUpper = await _db
          .collection('staff')
          .doc(cleanId.toUpperCase())
          .get()
          .timeout(const Duration(seconds: 6));
      if (docUpper.exists && docUpper.data() != null) {
        final data = docUpper.data()!;
        final accepted = data['termsAccepted'] == true ||
            data['isTermsAccepted'] == true ||
            data['terms_accepted'] == true;
        if (accepted && _currentStaff != null && _currentStaff!.staffId.toUpperCase() == cleanId.toUpperCase()) {
          _currentStaff = _currentStaff!.copyWith(termsAccepted: true);
        }
        return accepted;
      }

      final docExact = await _db
          .collection('staff')
          .doc(cleanId)
          .get()
          .timeout(const Duration(seconds: 6));
      if (docExact.exists && docExact.data() != null) {
        final data = docExact.data()!;
        final accepted = data['termsAccepted'] == true ||
            data['isTermsAccepted'] == true ||
            data['terms_accepted'] == true;
        if (accepted && _currentStaff != null && _currentStaff!.staffId == cleanId) {
          _currentStaff = _currentStaff!.copyWith(termsAccepted: true);
        }
        return accepted;
      }
    } catch (e) {
      debugPrint('Error checking staff terms acceptance: $e');
    }
    return false;
  }

  /// Records terms acceptance in Cloud Firestore and updates the local staff model
  Future<void> recordTermsAccepted({
    required String staffId,
    String? role,
  }) async {
    final cleanId = staffId.trim();
    if (cleanId.isEmpty) return;

    await _prepareFirebaseSession();
    final now = DateTime.now();
    final updatePayload = {
      'termsAccepted': true,
      'isTermsAccepted': true,
      'termsAcceptedAt': FieldValue.serverTimestamp(),
      'termsVersion': '2026.1-MOH-SL',
    };

    try {
      await _db
          .collection('staff')
          .doc(cleanId.toUpperCase())
          .set(updatePayload, SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Error recording terms acceptance for uppercase doc: $e');
      try {
        await _db
            .collection('staff')
            .doc(cleanId)
            .set(updatePayload, SetOptions(merge: true))
            .timeout(const Duration(seconds: 8));
      } catch (innerError) {
        debugPrint('Error recording terms acceptance for exact doc: $innerError');
      }
    }

    if (_currentStaff != null &&
        _currentStaff!.staffId.toUpperCase() == cleanId.toUpperCase()) {
      _currentStaff = _currentStaff!.copyWith(
        termsAccepted: true,
        termsAcceptedAt: now,
      );
    }
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

  /// Prepare session and seed default staff if needed
  Future<void> seedDefaultStaffIfNeeded() async {
    await _prepareFirebaseSession();
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
  /// Authenticate staff member strictly against Cloud Firestore real database records.
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
      DocumentSnapshot<Map<String, dynamic>>? targetDoc;
      final staffRef = _db.collection('staff');

      // 1. Direct document ID lookup in 'staff' collection
      try {
        final docUpper = await staffRef
            .doc(cleanStaffId.toUpperCase())
            .get()
            .timeout(const Duration(seconds: 8));
        if (docUpper.exists && docUpper.data() != null) {
          targetDoc = docUpper;
        } else {
          final docExact = await staffRef
              .doc(cleanStaffId)
              .get()
              .timeout(const Duration(seconds: 8));
          if (docExact.exists && docExact.data() != null) {
            targetDoc = docExact;
          }
        }
      } catch (e) {
        if (_isPermissionDeniedError(e)) rethrow;
        debugPrint('Direct doc lookup note: $e');
      }

      // 2. Query by staff ID / employee ID fields in 'staff' collection
      if (targetDoc == null) {
        final candidateFields = ['staffId', 'employeeId', 'staff_id', 'id'];
        for (final field in candidateFields) {
          try {
            final snap = await staffRef
                .where(field, isEqualTo: cleanStaffId.toUpperCase())
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 6));
            if (snap.docs.isNotEmpty) {
              targetDoc = snap.docs.first;
              break;
            }
            final snapExact = await staffRef
                .where(field, isEqualTo: cleanStaffId)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 6));
            if (snapExact.docs.isNotEmpty) {
              targetDoc = snapExact.docs.first;
              break;
            }
          } catch (e) {
            if (_isPermissionDeniedError(e)) rethrow;
          }
        }
      }

      // 3. Query by email in 'staff' collection
      if (targetDoc == null && cleanStaffId.contains('@')) {
        try {
          final snap = await staffRef
              .where('email', isEqualTo: cleanStaffId.toLowerCase())
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 6));
          if (snap.docs.isNotEmpty) {
            targetDoc = snap.docs.first;
          }
        } catch (e) {
          if (_isPermissionDeniedError(e)) rethrow;
        }
      }

      // 4. Fallback: Query 'doctors' collection if logging in as doctor
      if (targetDoc == null &&
          (cleanRole == 'doctor' ||
              cleanStaffId.toUpperCase().startsWith('DOC'))) {
        try {
          final docRef = _db.collection('doctors');
          final dUpper = await docRef
              .doc(cleanStaffId.toUpperCase())
              .get()
              .timeout(const Duration(seconds: 6));
          if (dUpper.exists && dUpper.data() != null) {
            targetDoc = dUpper;
          } else {
            final dExact = await docRef
                .doc(cleanStaffId)
                .get()
                .timeout(const Duration(seconds: 6));
            if (dExact.exists && dExact.data() != null) {
              targetDoc = dExact;
            } else {
              final dSnap = await docRef
                  .where('id', isEqualTo: cleanStaffId.toUpperCase())
                  .limit(1)
                  .get()
                  .timeout(const Duration(seconds: 6));
              if (dSnap.docs.isNotEmpty) {
                targetDoc = dSnap.docs.first;
              } else if (cleanStaffId.contains('@')) {
                final dEmail = await docRef
                    .where('email', isEqualTo: cleanStaffId.toLowerCase())
                    .limit(1)
                    .get()
                    .timeout(const Duration(seconds: 6));
                if (dEmail.docs.isNotEmpty) targetDoc = dEmail.docs.first;
              }
            }
          }
        } catch (e) {
          if (_isPermissionDeniedError(e)) rethrow;
          debugPrint('Doctors collection lookup note: $e');
        }
      }

      // 5. Fallback: Query 'users' collection where role is doctor/nurse/staff
      if (targetDoc == null) {
        try {
          final usersRef = _db.collection('users');
          final uDoc = await usersRef
              .doc(cleanStaffId)
              .get()
              .timeout(const Duration(seconds: 6));
          if (uDoc.exists && uDoc.data() != null) {
            final uRole = (uDoc.data()?['role'] ?? '').toString().toLowerCase();
            if (uRole == 'doctor' || uRole == 'nurse' || uRole == 'staff') {
              targetDoc = uDoc;
            }
          } else if (cleanStaffId.contains('@')) {
            final uEmail = await usersRef
                .where('email', isEqualTo: cleanStaffId.toLowerCase())
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 6));
            if (uEmail.docs.isNotEmpty) {
              final uRole =
                  (uEmail.docs.first.data()['role'] ?? '').toString().toLowerCase();
              if (uRole == 'doctor' || uRole == 'nurse' || uRole == 'staff') {
                targetDoc = uEmail.docs.first;
              }
            }
          }
        } catch (e) {
          if (_isPermissionDeniedError(e)) rethrow;
          debugPrint('Users collection fallback note: $e');
        }
      }

      // 6. Employee not found in database
      if (targetDoc == null || !targetDoc.exists || targetDoc.data() == null) {
        return StaffAuthResult.fail(
          'Staff ID "$cleanStaffId" was not found in the hospital database. Please verify your Staff ID or contact your hospital administrator.',
        );
      }

      final data = targetDoc.data()!;

      // 7. Verify Role in database
      final dbRole = (data['role'] ?? '').toString().trim().toLowerCase();
      if (dbRole.isNotEmpty && dbRole != cleanRole) {
        final displayDbRole = dbRole[0].toUpperCase() + dbRole.substring(1);
        final displaySelectedRole =
            cleanRole[0].toUpperCase() + cleanRole.substring(1);
        return StaffAuthResult.fail(
          'Role mismatch: Account "$cleanStaffId" is registered as a $displayDbRole in the hospital database, but $displaySelectedRole was selected.',
        );
      }

      // 8. Verify Password in database
      final dbPassword = (data['password'] ??
              data['pass'] ??
              data['pin'] ??
              data['passwordHash'] ??
              '')
          .toString()
          .trim();
      if (dbPassword.isEmpty) {
        return StaffAuthResult.fail(
          'No password set for staff account "$cleanStaffId". Please contact hospital administration or use Forgot Password.',
        );
      }

      if (dbPassword != cleanPassword) {
        return StaffAuthResult.fail(
          'Incorrect password for staff account "$cleanStaffId". Please check your password or reset it.',
        );
      }

      // 9. Verify Hospital assignment
      final dbHospName = (data['hospital'] ?? data['hospitalName'] ?? '').toString().trim();
      final dbHospCode = (data['hospitalCode'] ??
              data['hospitalIdentificationNo'] ??
              data['hospitalId'] ??
              '')
          .toString()
          .trim();
      final resolvedDbCode = dbHospCode.isNotEmpty
          ? dbHospCode.toUpperCase()
          : (dbHospName.isNotEmpty ? Hospital.resolveHospitalCode(dbHospName) : '');
      final selectedCode = Hospital.resolveHospitalCode(hospital);

      if (resolvedDbCode.isNotEmpty &&
          selectedCode.isNotEmpty &&
          resolvedDbCode != selectedCode) {
        return StaffAuthResult.fail(
          'Hospital mismatch: Staff member "$cleanStaffId" is registered under "$dbHospName", but "$hospital" was selected. Please select your assigned hospital.',
        );
      }

      // 10. Parse model strictly from real Firestore data
      var staffModel = StaffModel.fromDoc(targetDoc);
      // If hospital wasn't set on doc, associate selected hospital
      if (staffModel.hospital.isEmpty || staffModel.hospital == 'City General Hospital') {
        staffModel = staffModel.copyWith(hospital: hospital);
      }
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

      // 1. Direct document ID lookup in 'staff'
      final docUpper = await staffRef.doc(cleanInput.toUpperCase()).get();
      if (docUpper.exists && docUpper.data() != null) {
        found = StaffModel.fromDoc(docUpper);
      } else {
        final docDirect = await staffRef.doc(cleanInput).get();
        if (docDirect.exists && docDirect.data() != null) {
          found = StaffModel.fromDoc(docDirect);
        }
      }

      // 2. Query email in 'staff'
      if (found == null && cleanInput.contains('@')) {
        final snapshot = await staffRef
            .where('email', isEqualTo: cleanInput.toLowerCase())
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          found = StaffModel.fromDoc(snapshot.docs.first);
        }
      }

      // 3. Query candidate ID fields in 'staff'
      if (found == null) {
        final candidateFields = ['staffId', 'employeeId', 'staff_id', 'id'];
        for (final field in candidateFields) {
          final snapUpper = await staffRef
              .where(field, isEqualTo: cleanInput.toUpperCase())
              .limit(1)
              .get();
          if (snapUpper.docs.isNotEmpty) {
            found = StaffModel.fromDoc(snapUpper.docs.first);
            break;
          }
          final snap = await staffRef
              .where(field, isEqualTo: cleanInput)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) {
            found = StaffModel.fromDoc(snap.docs.first);
            break;
          }
        }
      }

      // 4. Lookup in 'doctors' collection
      if (found == null) {
        final docRef = _db.collection('doctors');
        final dUpper = await docRef.doc(cleanInput.toUpperCase()).get();
        if (dUpper.exists && dUpper.data() != null) {
          found = StaffModel.fromDoc(dUpper);
        } else {
          final dDirect = await docRef.doc(cleanInput).get();
          if (dDirect.exists && dDirect.data() != null) {
            found = StaffModel.fromDoc(dDirect);
          }
        }
      }

      // 5. Lookup in 'users' collection
      if (found == null) {
        final uDoc = await _db.collection('users').doc(cleanInput).get();
        if (uDoc.exists && uDoc.data() != null) {
          found = StaffModel.fromDoc(uDoc);
        } else if (cleanInput.contains('@')) {
          final uEmail = await _db
              .collection('users')
              .where('email', isEqualTo: cleanInput.toLowerCase())
              .limit(1)
              .get();
          if (uEmail.docs.isNotEmpty) {
            found = StaffModel.fromDoc(uEmail.docs.first);
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
