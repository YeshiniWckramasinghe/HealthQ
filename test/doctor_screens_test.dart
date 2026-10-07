import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthq/Doctor Management Screens/doctor_dashboard_screen.dart';
import 'package:healthq/Doctor Management Screens/today_appointments_screen.dart';
import 'package:healthq/Doctor Management Screens/consultation_queue_screen.dart';
import 'package:healthq/Doctor Management Screens/patient_details_screen.dart';
import 'package:healthq/Doctor Management Screens/patient_medical_history_screen.dart';
import 'package:healthq/Doctor Management Screens/consultation_screen.dart';
import 'package:healthq/Doctor Management Screens/doctor_profile_screen.dart';
import 'package:healthq/Doctor Management Screens/available_time_slots_screen.dart';
import 'package:healthq/Doctor Management Screens/availability_requests_screen.dart';
import 'package:healthq/Doctor Management Screens/request_availability_change_screen.dart';
import 'package:healthq/Doctor Management Screens/request_details_screen.dart';
import 'package:healthq/Doctor Management Screens/request_submitted_screen.dart';
import 'package:healthq/services/doctor_service.dart';

void main() {
  group('DoctorService Queue & Business Logic Tests', () {
    final service = DoctorService.instance;

    setUp(() {
      service.resetData();
    });

    test('Initial queue state is properly seeded matching Figma', () {
      expect(service.currentConsulting, isNotNull);
      expect(service.currentConsulting!.name, 'Kasun Fernando');
      expect(service.nextPatient, isNotNull);
      expect(service.nextPatient!.name, 'Nimal Perera');
      expect(service.waitingQueue.length, 3);
      expect(service.totalAppointmentsCount, 12);
    });

    test('Calling next patient advances queue automatically', () {
      final initialCurrentName = service.currentConsulting?.name;
      final initialNextName = service.nextPatient?.name;
      final initialWaitingLength = service.waitingQueue.length;

      service.callNextPatient();

      // The previous next patient should now be currently consulting
      expect(service.currentConsulting?.name, initialNextName);
      expect(service.currentConsulting?.name, isNot(initialCurrentName));
      // The waiting queue length should have decremented
      expect(service.waitingQueue.length, initialWaitingLength - 1);
    });

    test('Completing consultation updates appointment record and advances queue', () {
      final cur = service.currentConsulting!;
      service.completeConsultation(
        patientId: cur.id,
        notes: 'Patient responded well to treatment.',
        diagnosis: 'Essential Hypertension',
        prescription: 'Continue current dose.',
      );

      final completedAppt = service.appointments.firstWhere((a) => a.id == cur.id);
      expect(completedAppt.status, 'Completed');
      expect(completedAppt.consultationNotes, 'Patient responded well to treatment.');
      expect(completedAppt.diagnosis, 'Essential Hypertension');
    });

    test('Completing consultation saves attachments into patient medical history', () {
      final cur = service.currentConsulting!;
      const testAttachment = MedicalAttachmentModel(
        id: 'TEST-ATT-1',
        name: 'New_Chest_XRay.png',
        type: 'X-ray',
        date: '20 Sep 2026',
        fileSize: '3.1 MB',
        findings: 'Normal chest radiograph.',
      );

      service.completeConsultation(
        patientId: cur.id,
        notes: 'Follow-up consultation with new X-ray review.',
        diagnosis: 'Bronchitis - Resolving',
        prescription: 'Salbutamol inhaler as needed.',
        attachments: [testAttachment],
      );

      final patient = service.appointments.firstWhere((a) => a.id == cur.id);
      expect(patient.status, 'Completed');
      expect(patient.pastConsultations.first.diagnosis, 'Bronchitis - Resolving');
      expect(patient.pastConsultations.first.attachments.first.name, 'New_Chest_XRay.png');
      expect(patient.pastAttachments.any((a) => a.id == 'TEST-ATT-1'), isTrue);
    });

    test('Availability requests can be submitted and cancelled', () {
      final req = service.submitAvailabilityRequest(
        targetDate: '25 Sep 2026',
        timeSlot: '10:00 - 11:00',
        requestedStatus: 'Unavailable',
        reason: 'Special surgery rotation',
        currentStatus: 'Available',
      );

      expect(req.status, 'Pending');
      expect(service.requests.first.id, req.id);

      // Cancel the request
      service.cancelRequest(req.id);
      expect(service.requests.any((r) => r.id == req.id), isFalse);
    });
  });

  group('Doctor UI Widget & Screen Tests', () {
    testWidgets('DoctorDashboardScreen renders all key elements and stats', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorDashboardScreen(
            doctorName: 'Dr. S. Perera',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good Morning, Dr. S. Perera'), findsOneWidget);
      expect(find.text('Total Appointments'), findsOneWidget);
      expect(find.text('Waiting Patients'), findsOneWidget);
      expect(find.text('In Consultation'), findsOneWidget);
      expect(find.text('Completed Tasks'), findsOneWidget);
      expect(find.text("Today's Overview"), findsOneWidget);
      expect(find.text('Next Patient'), findsOneWidget);
      expect(find.text('Today Appointment'), findsOneWidget);
    });

    testWidgets('TodayAppointmentsScreen renders filter chips and appointment cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TodayAppointmentsScreen(showBottomNav: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Today's Appointments"), findsOneWidget);
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('ConsultationQueueScreen renders Now Consulting, Next Patient and Waiting list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConsultationQueueScreen(showBottomNav: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Consultation Queue'), findsOneWidget);
      expect(find.text('NOW CONSULTING'), findsOneWidget);
      expect(find.text('NEXT PATIENT'), findsOneWidget);
      expect(find.textContaining('Waiting List'), findsOneWidget);
    });

    testWidgets('PatientDetailsScreen renders personal info and medical history', (tester) async {
      final samplePatient = DoctorService.instance.appointments.first;
      await tester.pumpWidget(
        MaterialApp(
          home: PatientDetailsScreen(patient: samplePatient),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Patient Details'), findsOneWidget);
      expect(find.text(samplePatient.name), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Personal Info'), findsOneWidget);
      expect(find.text('Start Consultation'), findsOneWidget);
    });

    testWidgets('PatientMedicalHistoryScreen renders condition categories', (tester) async {
      final samplePatient = DoctorService.instance.appointments.first;
      await tester.pumpWidget(
        MaterialApp(
          home: PatientMedicalHistoryScreen(patient: samplePatient),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Patient Medical History'), findsOneWidget);
      expect(find.text('Allergies'), findsOneWidget);
      expect(find.text('Previous Conditions'), findsOneWidget);
      expect(find.text('Previous Visits'), findsOneWidget);
      expect(find.text('Current Medications'), findsOneWidget);
      expect(find.text('Start Consultation'), findsOneWidget);
    });

    testWidgets('ConsultationScreen renders notes, diagnosis dropdown, attachments and prescription', (tester) async {
      final samplePatient = DoctorService.instance.appointments.first;
      await tester.pumpWidget(
        MaterialApp(
          home: ConsultationScreen(patient: samplePatient),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Consultation'), findsOneWidget);
      expect(find.text('Consultation Notes'), findsOneWidget);
      expect(find.text('Consultation Attachments'), findsOneWidget);
      expect(find.text('Attach'), findsOneWidget);
      expect(find.text('Diagnosis'), findsWidgets);
      expect(find.text('Prescription / Medication'), findsWidgets);
      expect(find.text('Complete Consultation'), findsWidgets);
    });

    testWidgets('PatientMedicalHistoryScreen renders past consultations and attachments', (tester) async {
      final kasun = DoctorService.instance.appointments.firstWhere((p) => p.name == 'Kasun Fernando');
      await tester.pumpWidget(
        MaterialApp(
          home: PatientMedicalHistoryScreen(patient: kasun),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Previous Consultations & Clinical Notes'), findsOneWidget);
      expect(find.text('Previous Attachments & Scans'), findsOneWidget);
      expect(find.text('Chest_XRay_PA_View.png'), findsWidgets);
    });

    testWidgets('DoctorProfileScreen renders profile card and availability slots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorProfileScreen(showBottomNav: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Availability Summary'), findsOneWidget);
      expect(find.text('My Availability'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
      expect(find.text('Request Availability Change'), findsOneWidget);
    });

    testWidgets('AvailableTimeSlotsScreen renders slots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AvailableTimeSlotsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Available Time Slots'), findsOneWidget);
      expect(find.text('20 September 2026 - Sunday'), findsOneWidget);
      expect(find.text('Request Status Change'), findsOneWidget);
    });

    testWidgets('AvailabilityRequestsScreen renders requests list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AvailabilityRequestsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Availability Requests'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
    });

    testWidgets('RequestAvailabilityChangeScreen and RequestSubmittedScreen render properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RequestAvailabilityChangeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request Change'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Time Slot'), findsOneWidget);
      expect(find.text('Send Request to Hospital Staff'), findsOneWidget);

      final sampleReq = DoctorService.instance.requests.first;
      await tester.pumpWidget(
        MaterialApp(
          home: RequestDetailsScreen(request: sampleReq),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request Details'), findsOneWidget);
      expect(find.text(sampleReq.id), findsOneWidget);
      expect(find.text('Request Progress'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: RequestSubmittedScreen(request: sampleReq),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request Submitted!'), findsOneWidget);
      expect(find.text('View My Requests'), findsOneWidget);
      expect(find.text('Back to Profile'), findsOneWidget);
    });
  });
}
