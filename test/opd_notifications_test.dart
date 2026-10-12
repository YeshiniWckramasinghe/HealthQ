import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthq/OPD Management Screens/opd_notifications_screen.dart';

void main() {
  group('OPD Notifications & Alerts Screen Tests', () {
    final sampleNotifications = [
      OpdNotificationItem(
        id: 'notif_1',
        title: 'Queue Delayed - Room 04',
        message: 'Dr. A. B. Perera session is delayed by 15 mins due to emergency case.',
        timeAgo: '10 mins ago',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        type: 'Urgent',
        isRead: false,
      ),
      OpdNotificationItem(
        id: 'notif_2',
        title: 'New Patient Arrival',
        message: 'Patient Kamala Silva (Token A-08) checked in at triage desk.',
        timeAgo: '25 mins ago',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        type: 'Queue',
        token: 'A-08',
        isRead: false,
      ),
      OpdNotificationItem(
        id: 'notif_3',
        title: 'Daily Duty Roster Published',
        message: 'Morning shift OPD allocations have been updated for Ward A.',
        timeAgo: '1 hour ago',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: 'Info',
        isRead: true,
      ),
    ];

    testWidgets('Renders notifications screen with sample items and category pills', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OpdNotificationsScreen(
            hospital: 'City General Hospital',
            initialNotifications: sampleNotifications,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Real-Time Clinic & Patient Dispatch Feed'), findsOneWidget);
      expect(find.text('Queue Delayed - Room 04'), findsOneWidget);
      expect(find.text('New Patient Arrival'), findsOneWidget);
      expect(find.text('Daily Duty Roster Published'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
      expect(find.byIcon(Icons.format_list_numbered_rounded), findsWidgets);
      expect(find.byIcon(Icons.notifications_none_rounded), findsWidgets);
      expect(find.text('Token: A-08'), findsOneWidget);
    });

    testWidgets('Empty notification list renders friendly empty state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OpdNotificationsScreen(
            hospital: 'City General Hospital',
            initialNotifications: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No notifications at this time.'), findsOneWidget);
    });

    testWidgets('Refresh button is present in AppBar and tap works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OpdNotificationsScreen(
            hospital: 'City General Hospital',
            initialNotifications: sampleNotifications,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final refreshBtn = find.byIcon(Icons.refresh_rounded);
      expect(refreshBtn, findsOneWidget);

      await tester.tap(refreshBtn);
      await tester.pump();
    });
  });
}
