import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthq/OPD Management Screens/opd_header_banner.dart';

void main() {
  group('OPD Header Banner Nurse Profile Avatar Tests', () {
    testWidgets('Renders preset nurse avatar correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OpdHeaderBanner(
              title: 'Nurse Perera',
              hospital: 'City General Hospital (WC00001)',
              department: 'OPD Ward A',
              photoUrl: 'preset:nurse_teal',
            ),
          ),
        ),
      );

      expect(find.text('Nurse Perera'), findsOneWidget);
      expect(find.text('City General Hospital (WC00001)'), findsOneWidget);
      expect(find.text('OPD Ward A'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.medical_services_rounded), findsOneWidget);
    });

    testWidgets('Renders fallback initials when no photo provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OpdHeaderBanner(
              title: 'Sunil Silva',
              hospital: 'Karapitiya Hospital',
              photoUrl: null,
              photoBase64: null,
            ),
          ),
        ),
      );

      expect(find.text('Sunil Silva'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
    });

    testWidgets('Tapping avatar triggers onAvatarTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpdHeaderBanner(
              title: 'Nurse Kamala',
              hospital: 'City General Hospital',
              photoUrl: 'preset:nurse_blue',
              onAvatarTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      final avatarFinder = find.byType(CircleAvatar);
      expect(avatarFinder, findsOneWidget);

      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
