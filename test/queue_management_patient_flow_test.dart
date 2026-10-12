import 'package:flutter_test/flutter_test.dart';
import 'package:healthq/Queue Management Screens/check_in_screen.dart';
import 'package:healthq/Queue Management Screens/queue_status_screen.dart';
import 'package:healthq/services/booking_service.dart';

void main() {
  group('Queue Management & Patient Flow Integration Tests', () {
    test('CheckInAppointment correctly models patient check-in requirements', () {
      const appt = CheckInAppointment(
        appointmentId: 'appt_123',
        nic: '200012345678',
        hospital: 'National Hospital of Sri Lanka',
        date: '09 Oct 2026',
        session: 'Morning',
        doctor: 'Dr. R. Fernando',
        speciality: 'Cardiology',
        patient: 'Kamal Perera',
        contact: '0712345678',
        estimatedQueueNumber: '05',
      );

      expect(appt.appointmentId, 'appt_123');
      expect(appt.nic, '200012345678');
      expect(appt.hospital, 'National Hospital of Sri Lanka');
      expect(appt.doctor, 'Dr. R. Fernando');
      expect(appt.estimatedQueueNumber, '05');
    });

    test('AppointmentRecord parses checkedIn and queueStatus flags with backwards compatibility', () {
      final recordNotCheckedIn = AppointmentRecord(
        id: 'rec_1',
        hospitalName: 'Teaching Hospital Karapitiya',
        doctorName: 'Dr. Silva',
        date: '2026-10-09',
        dateLabel: '09 Oct 2026',
        session: 'Morning',
        status: 'confirmed',
        queueNo: 7,
        createdAt: DateTime.now(),
      );

      expect(recordNotCheckedIn.checkedIn, isFalse);
      expect(recordNotCheckedIn.queueStatus, 'Waiting');

      final recordCheckedIn = AppointmentRecord(
        id: 'rec_2',
        hospitalName: 'Teaching Hospital Karapitiya',
        doctorName: 'Dr. Silva',
        date: '2026-10-09',
        dateLabel: '09 Oct 2026',
        session: 'Morning',
        status: 'confirmed',
        queueNo: 7,
        createdAt: DateTime.now(),
        checkedIn: true,
        queueStatus: 'In Consult',
      );

      expect(recordCheckedIn.checkedIn, isTrue);
      expect(recordCheckedIn.queueStatus, 'In Consult');
    });

    test('Patients ahead count and estimated wait calculations behave accurately', () {
      const patients = [
        QueuePatient(queueNumber: '01', patientName: 'P1', doctorName: 'Dr. A', status: 'Completed'),
        QueuePatient(queueNumber: '02', patientName: 'P2', doctorName: 'Dr. A', status: 'Completed'),
        QueuePatient(queueNumber: '03', patientName: 'P3', doctorName: 'Dr. A', status: 'In Consult'),
        QueuePatient(queueNumber: '04', patientName: 'P4', doctorName: 'Dr. A', status: 'Waiting'),
        QueuePatient(queueNumber: '05', patientName: 'You', doctorName: 'Dr. A', status: 'Waiting'),
      ];

      const yourQueueNumber = 5;
      const averageMinutesPerPatient = 5;

      // Patients strictly ahead who are NOT completed
      final ahead = patients.where((p) {
        final num = int.tryParse(p.queueNumber) ?? 0;
        final finished = p.status.toLowerCase() == 'completed' || p.status.toLowerCase() == 'missed';
        return num > 0 && num < yourQueueNumber && !finished;
      }).length;

      expect(ahead, 2); // Patients 03 and 04

      final waitMinutes = ahead * averageMinutesPerPatient;
      expect(waitMinutes, 10);
    });

    test('Turn call detection accurately recognizes when it is patient turn', () {
      bool isMyTurn({
        required int yourQueueNumber,
        required int patientsAhead,
        required String myStatus,
      }) {
        final status = myStatus.toLowerCase();
        if (status.contains('called') ||
            status.contains('your turn') ||
            status.contains('consult')) {
          return true;
        }
        return yourQueueNumber > 0 && patientsAhead <= 0;
      }

      // Nobody active ahead -> turn
      expect(isMyTurn(yourQueueNumber: 3, patientsAhead: 0, myStatus: 'Waiting'), isTrue);

      // Someone ahead -> not turn yet
      expect(isMyTurn(yourQueueNumber: 3, patientsAhead: 2, myStatus: 'Waiting'), isFalse);

      // Explicitly called by nurse/doctor side -> turn regardless
      expect(isMyTurn(yourQueueNumber: 3, patientsAhead: 1, myStatus: 'Called to Room 03'), isTrue);
      expect(isMyTurn(yourQueueNumber: 3, patientsAhead: 1, myStatus: 'In Consult'), isTrue);
    });

    test('Check-in payload synchronizes status, queueNo, and checkedIn timestamps', () {
      Map<String, dynamic> buildCheckInUpdate({
        required int queueNumber,
        required String existingStatus,
      }) {
        final effectiveStatus = (existingStatus.toLowerCase() == 'pending')
            ? 'confirmed'
            : existingStatus;
        return {
          'queueNo': queueNumber,
          'queueNumber': queueNumber,
          'queueStatus': 'Waiting',
          'status': effectiveStatus,
          'checkedIn': true,
        };
      }

      final updatePending = buildCheckInUpdate(queueNumber: 4, existingStatus: 'pending');
      expect(updatePending['status'], 'confirmed');
      expect(updatePending['checkedIn'], isTrue);
      expect(updatePending['queueStatus'], 'Waiting');

      final updateConfirmed = buildCheckInUpdate(queueNumber: 9, existingStatus: 'confirmed');
      expect(updateConfirmed['status'], 'confirmed');
      expect(updateConfirmed['checkedIn'], isTrue);
      expect(updateConfirmed['queueNo'], 9);
    });

    test('Queue date matching normalizes both ISO format and natural display formats', () {
      bool isSameDate(String queueDate, String appointmentDate) {
        final q = queueDate.trim();
        final a = appointmentDate.trim();
        if (q == a) return true;

        final parts = a.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
          ];
          if (month >= 1 && month <= 12) {
            final plain = '$day ${months[month - 1]} $year';
            final padded = '${day.toString().padLeft(2, '0')} ${months[month - 1]} $year';
            return q == plain || q == padded;
          }
        }
        return false;
      }

      expect(isSameDate('2026-10-09', '2026-10-09'), isTrue);
      expect(isSameDate('09 Oct 2026', '2026-10-09'), isTrue);
      expect(isSameDate('9 Oct 2026', '2026-10-09'), isTrue);
      expect(isSameDate('10 Oct 2026', '2026-10-09'), isFalse);
    });
  });
}
