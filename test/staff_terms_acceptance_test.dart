import 'package:flutter_test/flutter_test.dart';
import 'package:healthq/services/staff_auth_service.dart';
import 'package:healthq/common Screens/terms_screen.dart';

void main() {
  group('Staff Terms & Conditions Acceptance Tests', () {
    test('New staff registrations have termsAccepted set to false by default', () {
      final newDoc = StaffModel(
        staffId: 'DOC1001-0001',
        name: 'Dr. S. Perera',
        email: 'dr.perera@health.gov.lk',
        contactNo: '+94771234567',
        role: 'doctor',
        hospital: 'Government Hospital — Colombo',
      );

      expect(newDoc.termsAccepted, isFalse);
      expect(newDoc.termsAcceptedAt, isNull);
      expect(newDoc.toMap()['termsAccepted'], isFalse);
    });

    test('Staff accepting terms preserves acceptance state and timestamp via copyWith', () {
      final doc = StaffModel(
        staffId: 'DOC1001-0001',
        name: 'Dr. S. Perera',
        email: 'dr.perera@health.gov.lk',
        contactNo: '+94771234567',
        role: 'doctor',
        hospital: 'Government Hospital — Colombo',
      );

      final acceptedTime = DateTime.parse('2026-10-12T10:00:00.000Z');
      final updated = doc.copyWith(
        termsAccepted: true,
        termsAcceptedAt: acceptedTime,
      );

      expect(updated.termsAccepted, isTrue);
      expect(updated.termsAcceptedAt, equals(acceptedTime));
      final map = updated.toMap();
      expect(map['termsAccepted'], isTrue);
      expect(map['termsAcceptedAt'], contains('2026-10-12'));
    });

    test('TermsScreen widget initializes with proper default role', () {
      const widget = TermsScreen(role: 'doctor');
      expect(widget.role, 'doctor');
    });
  });
}
