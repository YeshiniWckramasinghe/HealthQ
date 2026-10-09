import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Patient Inquiry Search & Helper Logic Tests', () {
    test('Calculates patient age accurately from DD/MM/YYYY date strings', () {
      String calculateAge(String? dob) {
        if (dob == null || dob.trim().isEmpty) return '';
        try {
          DateTime? birthDate;
          if (dob.contains('/')) {
            final parts = dob.split('/');
            if (parts.length == 3) {
              final d = int.tryParse(parts[0]);
              final m = int.tryParse(parts[1]);
              final y = int.tryParse(parts[2]);
              if (d != null && m != null && y != null) {
                birthDate = DateTime(y, m, d);
              }
            }
          } else if (dob.contains('-')) {
            birthDate = DateTime.tryParse(dob);
          }

          if (birthDate != null) {
            final now = DateTime.now();
            int age = now.year - birthDate.year;
            if (now.month < birthDate.month ||
                (now.month == birthDate.month && now.day < birthDate.day)) {
              age--;
            }
            return age >= 0 ? '$age Yrs' : '';
          }
        } catch (_) {}
        return '';
      }

      final thisYear = DateTime.now().year;
      final birthYear = thisYear - 30;
      final ageStr = calculateAge('15/01/$birthYear');
      expect(ageStr, contains('Yrs'));
      expect(ageStr, equals('30 Yrs'));
    });

    test('Patient inquiry classifies OPD Direct Record vs Online Portal Account correctly', () {
      String resolveAccountMode({
        required bool isStaffRegistered,
        required bool authLinked,
        required String? authUid,
      }) {
        if (authLinked || (authUid != null && authUid.isNotEmpty)) {
          return 'Online Portal';
        }
        if (isStaffRegistered) {
          return 'OPD Direct Record';
        }
        return 'Standard Patient';
      }

      expect(
        resolveAccountMode(isStaffRegistered: true, authLinked: false, authUid: null),
        equals('OPD Direct Record'),
      );
      expect(
        resolveAccountMode(isStaffRegistered: true, authLinked: true, authUid: 'uid_123'),
        equals('Online Portal'),
      );
      expect(
        resolveAccountMode(isStaffRegistered: false, authLinked: true, authUid: 'uid_456'),
        equals('Online Portal'),
      );
    });

    test('Multi-criteria query matching resolves by NIC, User ID, phone, or name', () {
      final samplePatients = [
        {
          'userId': '199512345678',
          'nic': '199512345678',
          'fullName': 'Kamal Perera',
          'contactNo': '0712345678',
          'email': 'kamal@healthq.lk',
        },
        {
          'userId': '200188899912',
          'nic': '200188899912',
          'fullName': 'Nimal Silva',
          'contactNo': '0779998888',
          'email': 'nimal@gmail.com',
        },
      ];

      List<Map<String, dynamic>> search(String query) {
        final q = query.trim().toLowerCase();
        return samplePatients.where((p) {
          return p['nic']!.toLowerCase().contains(q) ||
              p['userId']!.toLowerCase().contains(q) ||
              p['contactNo']!.contains(q) ||
              p['fullName']!.toLowerCase().contains(q) ||
              p['email']!.toLowerCase().contains(q);
        }).toList();
      }

      // Search by NIC
      expect(search('199512345678').length, equals(1));
      expect(search('199512345678').first['fullName'], equals('Kamal Perera'));

      // Search by Phone
      expect(search('0779998888').length, equals(1));
      expect(search('0779998888').first['fullName'], equals('Nimal Silva'));

      // Search by partial Name
      expect(search('Kamal').length, equals(1));
      expect(search('Silva').length, equals(1));

      // Non-existent search
      expect(search('NonExistent999').isEmpty, isTrue);
    });
  });
}
