import 'package:flutter_test/flutter_test.dart';
import 'package:healthq/services/staff_auth_service.dart';
import 'package:healthq/services/booking_service.dart';

void main() {
  group('Staff Real Database Authentication Tests', () {
    test('StaffModel parses real Firestore document fields flexibly', () {
      final realDocData = <String, dynamic>{
        'staffId': 'DOC2024-0042',
        'fullName': 'Dr. Nimal Jayawardena',
        'email': 'nimal.j@health.gov.lk',
        'contactNo': '+94771234567',
        'role': 'doctor',
        'hospital': 'National Hospital of Sri Lanka',
        'hospitalCode': 'WP00001',
        'department': 'Cardiology Unit',
        'specialty': 'Consultant Cardiologist',
        'room': 'Consultation Room 04',
        'shift': 'Day Shift (08:00 - 16:00)',
      };

      final staff = StaffModel.fromMap(realDocData, docId: 'DOC2024-0042');
      expect(staff.staffId, 'DOC2024-0042');
      expect(staff.name, 'Dr. Nimal Jayawardena');
      expect(staff.email, 'nimal.j@health.gov.lk');
      expect(staff.contactNo, '+94771234567');
      expect(staff.role, 'doctor');
      expect(staff.hospital, 'National Hospital of Sri Lanka');
      expect(staff.hospitalCode, 'WP00001');
      expect(staff.department, 'Cardiology Unit');
      expect(staff.specialty, 'Consultant Cardiologist');
    });

    test('StaffModel handles alternative database field keys (employeeId, mobile, doctorName)', () {
      final altDocData = <String, dynamic>{
        'employeeId': 'NUR-COL-009',
        'nurseName': 'Sister Kamala Silva',
        'mail': 'kamala.nurse@colombo.health.lk',
        'mobile': '0719876543',
        'hospitalName': 'Colombo South Teaching Hospital',
        'unit': 'OPD Triage',
      };

      final staff = StaffModel.fromMap(altDocData);
      expect(staff.staffId, 'NUR-COL-009');
      expect(staff.name, 'Sister Kamala Silva');
      expect(staff.email, 'kamala.nurse@colombo.health.lk');
      expect(staff.contactNo, '0719876543');
      expect(staff.role, 'nurse');
      expect(staff.hospital, 'Colombo South Teaching Hospital');
      expect(staff.department, 'OPD Triage');
    });

    test('Hospital code resolution matches database hospital to dropdown selection', () {
      final colomboCode = Hospital.resolveHospitalCode('National Hospital of Sri Lanka');
      final kandyCode = Hospital.resolveHospitalCode('Teaching Hospital Kandy');

      expect(colomboCode, isNotEmpty);
      expect(kandyCode, isNotEmpty);
      expect(colomboCode, isNot(equals(kandyCode)));
    });

    test('Staff authentication result fail captures descriptive database error messages', () {
      final notFound = StaffAuthResult.fail('Staff ID "STF999" was not found in the hospital database.');
      expect(notFound.success, isFalse);
      expect(notFound.errorMessage, contains('not found in the hospital database'));

      final wrongPass = StaffAuthResult.fail('Incorrect password for staff account "DOC100".');
      expect(wrongPass.success, isFalse);
      expect(wrongPass.errorMessage, contains('Incorrect password'));
    });

    test('StaffModel parses termsAccepted default (false) for new registrations', () {
      final newStaffData = <String, dynamic>{
        'staffId': 'DOC2026-NEW',
        'name': 'Dr. First Registration',
        'email': 'new.doc@health.gov.lk',
        'contactNo': '+94710000000',
        'role': 'doctor',
        'hospital': 'National Hospital of Sri Lanka',
      };

      final staff = StaffModel.fromMap(newStaffData);
      expect(staff.termsAccepted, isFalse);
      expect(staff.termsAcceptedAt, isNull);
      expect(staff.toMap()['termsAccepted'], isFalse);
    });

    test('StaffModel parses termsAccepted true and timestamp for existing accepted staff', () {
      final acceptedStaffData = <String, dynamic>{
        'staffId': 'DOC2026-OLD',
        'name': 'Dr. Accepted Doctor',
        'email': 'accepted.doc@health.gov.lk',
        'contactNo': '+94711111111',
        'role': 'doctor',
        'hospital': 'Colombo South Teaching Hospital',
        'termsAccepted': true,
        'termsAcceptedAt': '2026-10-10T08:30:00.000Z',
      };

      final staff = StaffModel.fromMap(acceptedStaffData);
      expect(staff.termsAccepted, isTrue);
      expect(staff.termsAcceptedAt, isNotNull);
      expect(staff.toMap()['termsAccepted'], isTrue);
      expect(staff.toMap()['termsAcceptedAt'], contains('2026-10-10'));
    });
  });
}
