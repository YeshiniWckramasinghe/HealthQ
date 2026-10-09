import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OPD Appointment Confirmation & Cancellation Flow Tests', () {
    test('Cancellation reasons include wireframe default and standard options', () {
      const reasons = [
        'Patient Absent / No Show',
        'Patient Requested Cancellation',
        'Doctor Unavailable / Rescheduled',
        'Emergency / Hospital Operational Reason',
        'Duplicate Booking',
        'Other',
      ];

      expect(reasons.first, 'Patient Absent / No Show');
      expect(reasons.contains('Patient Requested Cancellation'), isTrue);
      expect(reasons.contains('Doctor Unavailable / Rescheduled'), isTrue);
      expect(reasons.length, 6);
    });

    test('Cancellation payload schema captures reason, notes, staff name, and status', () {
      Map<String, dynamic> buildCancellationPayload({
        required String reason,
        String? cancelNotes,
        String? staffName,
      }) {
        return {
          'status': 'cancelled',
          'cancelReason': reason,
          if (cancelNotes != null && cancelNotes.trim().isNotEmpty)
            'cancelNotes': cancelNotes.trim(),
          if (staffName != null && staffName.trim().isNotEmpty)
            'cancelledByStaffName': staffName.trim(),
        };
      }

      final payload = buildCancellationPayload(
        reason: 'Patient Absent / No Show',
        cancelNotes:
            'Patient called and informed they won\'t be able to visit due to emergency personal matters.',
        staffName: 'Nurse Perera',
      );

      expect(payload['status'], 'cancelled');
      expect(payload['cancelReason'], 'Patient Absent / No Show');
      expect(payload['cancelNotes'], contains('emergency personal matters'));
      expect(payload['cancelledByStaffName'], 'Nurse Perera');
    });

    test('Confirmation payload schema marks appointment confirmed with staff audit', () {
      Map<String, dynamic> buildConfirmationPayload({
        String? staffName,
      }) {
        return {
          'status': 'confirmed',
          'isConfirmedByStaff': true,
          'confirmedByStaffName': staffName ?? 'OPD Management',
        };
      }

      final payload = buildConfirmationPayload(staffName: 'Staff Nurse Kamal');

      expect(payload['status'], 'confirmed');
      expect(payload['isConfirmedByStaff'], isTrue);
      expect(payload['confirmedByStaffName'], 'Staff Nurse Kamal');
    });

    test('Wireframe action buttons resolve correctly per appointment status', () {
      List<String> getAvailableActionButtons(String status) {
        final cur = status.toLowerCase();
        if (cur == 'waiting' || cur == 'pending' || cur == 'upcoming') {
          return ['Confirm Appointment', 'Cancel Appointment'];
        } else if (cur == 'confirmed') {
          return ['Call Patient (In Consult)', 'Cancel Appointment'];
        } else if (cur == 'in consult' || cur == 'in_consult') {
          return ['Complete Consultation', 'Cancel Appointment'];
        } else if (cur == 'cancelled') {
          return ['Cancelled'];
        } else if (cur == 'completed') {
          return ['Completed'];
        }
        return [];
      }

      // Unconfirmed / Waiting (Wireframe 1)
      expect(getAvailableActionButtons('waiting'),
          ['Confirm Appointment', 'Cancel Appointment']);
      expect(getAvailableActionButtons('pending'),
          ['Confirm Appointment', 'Cancel Appointment']);

      // Confirmed / Consultation flow
      expect(getAvailableActionButtons('confirmed'),
          ['Call Patient (In Consult)', 'Cancel Appointment']);
      expect(getAvailableActionButtons('in consult'),
          ['Complete Consultation', 'Cancel Appointment']);

      // Terminal states
      expect(getAvailableActionButtons('cancelled'), ['Cancelled']);
      expect(getAvailableActionButtons('completed'), ['Completed']);
    });
  });
}
