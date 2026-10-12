import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthq/OPD Management Screens/opd_doctor_management_screen.dart';
import 'package:healthq/OPD Management Screens/opd_doctor_profile_screen.dart';

void main() {
  group('OPD Doctor Management & Profile Tests', () {
    final sampleDoctors = [
      {
        'id': 'doc_01',
        'name': 'Dr. A. B. Perera',
        'speciality': 'General Medicine',
        'department': 'General OPD',
        'opdDays': 'Mon/Wed/Fri',
        'regNo': 'SLMC-12450',
        'phone': '011-234-5671',
        'email': 'a.perera@govhosp.lk',
        'session': '08:00 - 12:00',
        'designation': 'Senior Medical Officer',
        'room': 'Room 04',
        'hospital': 'Government Hospital Colombo',
      },
      {
        'id': 'doc_02',
        'name': 'Dr. K. Dissanayake',
        'speciality': 'Orthopedics',
        'department': 'Orthopedics OPD',
        'opdDays': 'Tue/Thu/Sat',
        'regNo': 'SLMC-19870',
        'phone': '011-234-5679',
        'email': 'k.dissanayake@govhosp.lk',
        'session': '09:00 - 14:00',
        'designation': 'Consultant Orthopedic Surgeon',
        'room': 'Room 02',
        'hospital': 'Government Hospital Colombo',
      },
    ];

    testWidgets('Renders doctor management screen with doctors list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OpdDoctorManagementScreen(
            hospital: 'Government Hospital Colombo',
            hospitalCode: 'WC00001',
            initialDoctors: sampleDoctors,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Doctor Management'), findsOneWidget);
      expect(find.text('Dr. A. B. Perera'), findsOneWidget);
      expect(find.text('Dr. K. Dissanayake'), findsOneWidget);
      expect(find.textContaining('Mon/Wed/Fri'), findsOneWidget);
      expect(find.textContaining('Tue/Thu/Sat'), findsOneWidget);
      expect(find.text('2 Doctors Registered'), findsOneWidget);
    });

    testWidgets('Filters doctors dynamically using search input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OpdDoctorManagementScreen(
            hospital: 'Government Hospital Colombo',
            hospitalCode: 'WC00001',
            initialDoctors: sampleDoctors,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Ortho');
      await tester.pumpAndSettle();

      expect(find.text('Dr. K. Dissanayake'), findsOneWidget);
      expect(find.text('Dr. A. B. Perera'), findsNothing);
      expect(find.text('1 Doctors Registered'), findsOneWidget);

      // Clear search
      final clearButton = find.byIcon(Icons.cancel_rounded);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Dr. A. B. Perera'), findsOneWidget);
      expect(find.text('Dr. K. Dissanayake'), findsOneWidget);
    });

    testWidgets('Tapping doctor card opens OpdDoctorProfileScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OpdDoctorManagementScreen(
            hospital: 'Government Hospital Colombo',
            hospitalCode: 'WC00001',
            initialDoctors: sampleDoctors,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dr. A. B. Perera'));
      await tester.pumpAndSettle();

      expect(find.byType(OpdDoctorProfileScreen), findsOneWidget);
      expect(find.text('Doctor Profile & OPD Schedule'), findsOneWidget);
      expect(find.text('SLMC-12450'), findsOneWidget);
      expect(find.text('Senior Medical Officer'), findsOneWidget);
    });
  });
}
