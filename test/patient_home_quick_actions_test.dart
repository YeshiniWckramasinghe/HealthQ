import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthq/Patient Management Screens/home_screen.dart';
import 'package:healthq/services/booking_service.dart';

void main() {
  group('Patient Home Screen Quick Actions (2x2 Grid Layout Tests)', () {
    testWidgets('Renders 4 main section cards arranged in 2 rows with 2 cards each',
        (tester) async {
      final apptController = StreamController<List<AppointmentRecord>>.broadcast();
      final profileController = StreamController<UserProfile>.broadcast();

      bool findHospitalTapped = false;
      bool bookTapped = false;
      bool historyTapped = false;
      bool liveQueueTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTab(
              appointments: apptController.stream,
              profile: profileController.stream,
              onFindHospital: () => findHospitalTapped = true,
              onBook: () => bookTapped = true,
              onHistory: () => historyTapped = true,
              onNotifications: () {},
              onLiveQueue: (list) => liveQueueTapped = true,
            ),
          ),
        ),
      );

      // Emit empty appointment list and profile
      apptController.add([]);
      profileController.add(
        const UserProfile(
          fullName: 'Jane Doe',
          email: 'jane@example.com',
          contact: '0771234567',
          nic: '200012345678',
        ),
      );
      await tester.pumpAndSettle();

      // Check section header
      expect(find.text('MAIN SERVICES'), findsOneWidget);

      // Check all 4 cards exist
      expect(find.text('Find Hospital'), findsOneWidget);
      expect(find.text('Search OPD hospitals'), findsOneWidget);

      expect(find.text('Book Appointment'), findsOneWidget);
      expect(find.text('Reserve doctor slot'), findsOneWidget);

      expect(find.text('My Appointments'), findsOneWidget);
      expect(find.text('History & bookings'), findsOneWidget);

      expect(find.text('Live Queue'), findsOneWidget);
      expect(find.text('Track waiting & turn'), findsOneWidget);

      // Verify that Row 1 has Find Hospital and Book Appointment
      final findHospitalFinder = find.text('Find Hospital');
      final bookAppointmentFinder = find.text('Book Appointment');
      final myAppointmentsFinder = find.text('My Appointments');
      final liveQueueFinder = find.text('Live Queue');

      final hospitalTop = tester.getTopLeft(findHospitalFinder).dy;
      final bookTop = tester.getTopLeft(bookAppointmentFinder).dy;
      final historyTop = tester.getTopLeft(myAppointmentsFinder).dy;
      final queueTop = tester.getTopLeft(liveQueueFinder).dy;

      // Card 1 & Card 2 share the same vertical Y position (Row 1)
      expect((hospitalTop - bookTop).abs(), lessThan(5.0));

      // Card 3 & Card 4 share the same vertical Y position (Row 2)
      expect((historyTop - queueTop).abs(), lessThan(5.0));

      // Row 2 is positioned below Row 1
      expect(historyTop, greaterThan(hospitalTop + 30.0));

      // Tap tests
      await tester.tap(findHospitalFinder);
      await tester.pump();
      expect(findHospitalTapped, isTrue);

      await tester.tap(bookAppointmentFinder);
      await tester.pump();
      expect(bookTapped, isTrue);

      await tester.tap(myAppointmentsFinder);
      await tester.pump();
      expect(historyTapped, isTrue);

      await tester.tap(liveQueueFinder);
      await tester.pump();
      expect(liveQueueTapped, isTrue);

      await apptController.close();
      await profileController.close();
    });
  });
}
