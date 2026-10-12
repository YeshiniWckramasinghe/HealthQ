import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthq/OPD Management Screens/opd_queue_management_screen.dart';
import 'package:healthq/OPD Management Screens/opd_queue_patient_details_screen.dart';

void main() {
  group('OPD Queue Management & Patient Details Tests', () {
    testWidgets('Renders Queue Management screen with Currently Serving and Queue Order', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OpdQueueManagementScreen(
            hospital: 'City General Hospital',
            initialDoctorFilter: 'Dr. R. Fernando',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Queue Management'), findsOneWidget);
      expect(find.text('CURRENTLY SERVING'), findsOneWidget);
      expect(find.text('QUEUE ORDER'), findsOneWidget);
      expect(find.text('Doctor: '), findsOneWidget);
      expect(find.text('Dr. R. Fernando'), findsWidgets);
    });

    testWidgets('Doctor filter dialog opens and shows All Doctors option', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OpdQueueManagementScreen(
            hospital: 'City General Hospital',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final doctorFilterRow = find.text('Doctor: ');
      expect(doctorFilterRow, findsOneWidget);

      await tester.tap(doctorFilterRow);
      await tester.pumpAndSettle();

      expect(find.text('Filter by Doctor'), findsOneWidget);
      expect(find.text('All Doctors'), findsWidgets);
    });

    testWidgets('Renders OpdQueuePatientDetailsScreen with patient info and status options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OpdQueuePatientDetailsScreen(
            token: 'T-002',
            patientName: 'Nimali Bandara',
            nic: '917654321V',
            phone: '071-987-6543',
            department: 'General Medicine OPD',
            doctor: 'Dr. R. Fernando',
            scheduledTime: '08:45 AM',
            currentStatus: 'Next',
            hospital: 'City General Hospital',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Patient Verification Profile'), findsOneWidget);
      expect(find.text('T-002'), findsOneWidget);
      expect(find.text('Nimali Bandara'), findsOneWidget);
      expect(find.text('917654321V'), findsOneWidget);
      expect(find.text('071-987-6543'), findsOneWidget);
      expect(find.text('Confirm Status Update'), findsOneWidget);
    });
  });
}
