import 'package:flutter_test/flutter_test.dart';
import 'package:healthq/services/booking_service.dart';

void main() {
  group('Staff Appointments View & Scoping Tests', () {
    test('Date comparison matches ISO, slash, dash, and today keywords', () {
      bool matchesDate(String docDate, String docDateLabel, DateTime targetDate) {
        final clean = docDate.trim();
        final targetIso =
            '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
        if (clean == targetIso || clean.startsWith(targetIso)) return true;

        final slashTarget =
            '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}';
        final dashTarget =
            '${targetDate.day.toString().padLeft(2, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.year}';
        if (clean == slashTarget || clean == dashTarget) return true;

        final parsed = DateTime.tryParse(clean);
        if (parsed != null) {
          if (parsed.year == targetDate.year &&
              parsed.month == targetDate.month &&
              parsed.day == targetDate.day) {
            return true;
          }
        }

        final now = DateTime.now();
        final isTodayTarget = targetDate.year == now.year &&
            targetDate.month == now.month &&
            targetDate.day == now.day;
        if (isTodayTarget) {
          final lDate = clean.toLowerCase();
          final lLabel = docDateLabel.toLowerCase();
          if (lDate.contains('today') || lLabel.contains('today')) {
            return true;
          }
        }

        return false;
      }

      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));

      // ISO matching
      final todayIso =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      expect(matchesDate(todayIso, 'Today', today), isTrue);

      // Slash format matching
      final slashTomorrow =
          '${tomorrow.day.toString().padLeft(2, '0')}/${tomorrow.month.toString().padLeft(2, '0')}/${tomorrow.year}';
      expect(matchesDate(slashTomorrow, 'Tomorrow', tomorrow), isTrue);

      // Dash format matching
      final dashTomorrow =
          '${tomorrow.day.toString().padLeft(2, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.year}';
      expect(matchesDate(dashTomorrow, 'Tomorrow', tomorrow), isTrue);

      // Tomorrow date should not match today target
      expect(matchesDate(slashTomorrow, 'Tomorrow', today), isFalse);

      // Today keyword matching
      expect(matchesDate('', 'Today Session', today), isTrue);
    });

    test('Status filtering correctly handles Pending, Confirmed, Waiting, and All', () {
      bool matchesStatus(String selectedFilter, String docStatus) {
        if (selectedFilter == 'All') return true;
        final sel = selectedFilter.toLowerCase();
        final cur = docStatus.toLowerCase();
        if (sel == 'pending') {
          return cur == 'pending';
        } else if (sel == 'confirmed') {
          return cur == 'confirmed' || cur == 'waiting' || cur == 'upcoming';
        } else if (sel == 'waiting') {
          return cur == 'waiting' || cur == 'confirmed' || cur == 'upcoming';
        }
        return cur == sel;
      }

      // Filter: 'All' matches all
      expect(matchesStatus('All', 'pending'), isTrue);
      expect(matchesStatus('All', 'confirmed'), isTrue);
      expect(matchesStatus('All', 'waiting'), isTrue);
      expect(matchesStatus('All', 'In Consult'), isTrue);
      expect(matchesStatus('All', 'Completed'), isTrue);

      // Filter: 'Pending' strictly matches 'pending' appointments awaiting OPD staff confirmation
      expect(matchesStatus('Pending', 'pending'), isTrue);
      expect(matchesStatus('Pending', 'waiting'), isFalse);
      expect(matchesStatus('Pending', 'confirmed'), isFalse);

      // Filter: 'Confirmed' matches confirmed / waiting / upcoming appointments
      expect(matchesStatus('Confirmed', 'confirmed'), isTrue);
      expect(matchesStatus('Confirmed', 'waiting'), isTrue);
      expect(matchesStatus('Confirmed', 'pending'), isFalse);

      // Filter: 'Waiting' matches waiting queue
      expect(matchesStatus('Waiting', 'waiting'), isTrue);
      expect(matchesStatus('Waiting', 'pending'), isFalse);
    });

    test('Hospital resolution handles both object fallback and official codes', () {
      const h1 = Hospital(
        id: 'city_general',
        name: 'City General Hospital',
        province: 'Western',
        district: 'Colombo',
        city: 'Colombo',
        status: 'open',
        slotsLeft: 10,
        identificationNo: 'WC00001',
      );

      final code1 = h1.identificationNo.isNotEmpty &&
              RegExp(r'^[A-Za-z]{2}\d{5}$').hasMatch(h1.identificationNo.trim())
          ? h1.identificationNo.trim().toUpperCase()
          : Hospital.resolveHospitalCode('${h1.id}_${h1.name}');
      expect(code1, 'WC00001');

      // Fallback with empty identificationNo
      const h2 = Hospital(
        id: 'teaching_hospital',
        name: 'Teaching Hospital Kandy',
        province: 'Central',
        district: 'Kandy',
        city: 'Kandy',
        status: 'open',
        slotsLeft: 5,
        identificationNo: '',
      );

      final code2 = h2.identificationNo.isNotEmpty &&
              RegExp(r'^[A-Za-z]{2}\d{5}$').hasMatch(h2.identificationNo.trim())
          ? h2.identificationNo.trim().toUpperCase()
          : Hospital.resolveHospitalCode('${h2.id}_${h2.name}');
      expect(code2, 'CK00003');
    });
  });
}
