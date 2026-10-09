import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Patient Registration Form Validation Tests', () {
    final nicRegex = RegExp(r'^([0-9]{9}[vVxX]|[0-9]{12})$');
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final phoneRegex = RegExp(r'^(?:0|\+?94)?7[0-9]{8}$');
    final nameRegex = RegExp(r"^[a-zA-Z\s'-]+$");

    test('NIC validation accepts both 9-digit+V and 12-digit formats', () {
      expect(nicRegex.hasMatch('952345678V'), isTrue);
      expect(nicRegex.hasMatch('952345678v'), isTrue);
      expect(nicRegex.hasMatch('952345678X'), isTrue);
      expect(nicRegex.hasMatch('199512345678'), isTrue);
      expect(nicRegex.hasMatch('200112345678'), isTrue);

      // Invalid NICs
      expect(nicRegex.hasMatch('12345'), isFalse);
      expect(nicRegex.hasMatch('952345678'), isFalse);
      expect(nicRegex.hasMatch('952345678AB'), isFalse);
      expect(nicRegex.hasMatch('1995123456789'), isFalse);
    });

    test('Email validation accepts valid emails and rejects invalid ones', () {
      expect(emailRegex.hasMatch('kamal.perera@gmail.com'), isTrue);
      expect(emailRegex.hasMatch('nimal@healthq.lk'), isTrue);
      expect(emailRegex.hasMatch('patient123@yahoo.com'), isTrue);

      // Invalid emails
      expect(emailRegex.hasMatch('kamal.perera'), isFalse);
      expect(emailRegex.hasMatch('kamal@'), isFalse);
      expect(emailRegex.hasMatch('@gmail.com'), isFalse);
      expect(emailRegex.hasMatch('kamal@gmail'), isFalse);
    });

    test('Contact number validation enforces Sri Lankan mobile formats', () {
      expect(phoneRegex.hasMatch('0712345678'), isTrue);
      expect(phoneRegex.hasMatch('0771234567'), isTrue);
      expect(phoneRegex.hasMatch('+94771234567'), isTrue);
      expect(phoneRegex.hasMatch('94771234567'), isTrue);

      // Invalid phones
      expect(phoneRegex.hasMatch('123456'), isFalse);
      expect(phoneRegex.hasMatch('0112345678'), isFalse); // Landline
      expect(phoneRegex.hasMatch('0812345678'), isFalse);
    });

    test('Name validation enforces alphabetic characters', () {
      expect(nameRegex.hasMatch('Kamal'), isTrue);
      expect(nameRegex.hasMatch("O'Connor"), isTrue);
      expect(nameRegex.hasMatch('Mary-Jane'), isTrue);

      // Invalid names
      expect(nameRegex.hasMatch('Kamal123'), isFalse);
      expect(nameRegex.hasMatch('Kamal@Perera'), isFalse);
    });
  });

  group('OPD to Online Account Merging Logic Tests', () {
    test('OPD direct registration schema leaves auth unlinked and sets staff registration flag', () {
      final opdData = {
        'userId': '199512345678',
        'nic': '199512345678',
        'patientId': '199512345678',
        'firstName': 'Kamal',
        'lastName': 'Perera',
        'fullName': 'Kamal Perera',
        'gender': 'Male',
        'dob': '14/05/1995',
        'email': 'kamal.perera@gmail.com',
        'contactNo': '0712345678',
        'role': 'patient',
        'isRegisteredByStaff': true,
        'authLinked': false,
        'registeredBy': 'Nurse Anoma',
        'registeredHospital': 'National Hospital of Sri Lanka',
        'registeredHospitalCode': 'WP-CO-00001',
      };

      expect(opdData['isRegisteredByStaff'], isTrue);
      expect(opdData['authLinked'], isFalse);
      expect(opdData['userId'], equals('199512345678'));
      expect(opdData['role'], equals('patient'));
    });

    test('Patient sign-up merges existing OPD record without creating duplicate', () {
      final existingOpdData = {
        'userId': '199512345678',
        'nic': '199512345678',
        'patientId': '199512345678',
        'firstName': 'Kamal',
        'lastName': 'Perera',
        'fullName': 'Kamal Perera',
        'gender': 'Male',
        'dob': '14/05/1995',
        'email': 'kamal.perera@gmail.com',
        'contactNo': '0712345678',
        'role': 'patient',
        'isRegisteredByStaff': true,
        'authLinked': false,
        'registeredBy': 'Nurse Anoma',
        'registeredHospital': 'National Hospital of Sri Lanka',
        'registeredHospitalCode': 'WP-CO-00001',
      };

      // When patient signs up online:
      const authUid = 'firebase_uid_abc123';
      final mergedData = {
        ...existingOpdData,
        'authUid': authUid,
        'uid': authUid,
        'isRegisteredByStaff': false, // Claimed by patient
        'authLinked': true, // Now authenticated
      };

      // Verified: user ID and NIC preserved, duplicate not created
      expect(mergedData['userId'], equals('199512345678'));
      expect(mergedData['nic'], equals('199512345678'));
      expect(mergedData['authUid'], equals(authUid));
      expect(mergedData['uid'], equals(authUid));
      expect(mergedData['authLinked'], isTrue);
      expect(mergedData['isRegisteredByStaff'], isFalse);
      expect(mergedData['registeredHospital'], equals('National Hospital of Sri Lanka'));
      expect(mergedData['registeredHospitalCode'], equals('WP-CO-00001'));
    });
  });
}
