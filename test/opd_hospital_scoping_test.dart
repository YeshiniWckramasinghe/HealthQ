import 'package:flutter_test/flutter_test.dart';
import 'package:healthq/services/booking_service.dart';

void main() {
  group('Hospital Identification & Code Resolution Tests', () {
    test('Resolves correct code for each Sri Lankan hospital', () {
      expect(Hospital.resolveHospitalCode('City General Hospital'), 'WC00001');
      expect(Hospital.resolveHospitalCode('Government Hospital Colombo'), 'WC00001');
      expect(Hospital.resolveHospitalCode('WC00001'), 'WC00001');

      expect(Hospital.resolveHospitalCode('District Hospital'), 'WG00002');
      expect(Hospital.resolveHospitalCode('Negombo General Hospital'), 'WG00002');
      expect(Hospital.resolveHospitalCode('WG00002'), 'WG00002');

      expect(Hospital.resolveHospitalCode('Teaching Hospital'), 'CK00003');
      expect(Hospital.resolveHospitalCode('Kandy Hospital'), 'CK00003');
      expect(Hospital.resolveHospitalCode('CK00003'), 'CK00003');

      expect(Hospital.resolveHospitalCode('Karapitiya Hospital'), 'SG00004');
      expect(Hospital.resolveHospitalCode('Teaching Hospital Karapitiya'), 'SG00004');
      expect(Hospital.resolveHospitalCode('SG00004'), 'SG00004');

      expect(Hospital.resolveHospitalCode('Jaffna Base Hospital'), 'NJ00005');
      expect(Hospital.resolveHospitalCode('NJ00005'), 'NJ00005');

      expect(Hospital.resolveHospitalCode('Kurunegala Hospital'), 'NK00006');
      expect(Hospital.resolveHospitalCode('NK00006'), 'NK00006');
    });

    test('Strict hospital matching accepts same hospital and rejects different hospitals', () {
      // 1. Karapitiya Nurse vs Karapitiya Appointment
      expect(
        Hospital.matchesHospital(
          targetHospital: 'Karapitiya Hospital',
          targetCode: 'SG00004',
          itemHospital: 'Teaching Hospital Karapitiya',
          itemCode: 'SG00004',
        ),
        isTrue,
      );

      // 2. Karapitiya Nurse vs Colombo Appointment -> REJECT!
      expect(
        Hospital.matchesHospital(
          targetHospital: 'Karapitiya Hospital',
          targetCode: 'SG00004',
          itemHospital: 'City General Hospital',
          itemCode: 'WC00001',
        ),
        isFalse,
      );

      // 3. Karapitiya Nurse vs Kandy Teaching Hospital Appointment -> REJECT!
      expect(
        Hospital.matchesHospital(
          targetHospital: 'Karapitiya Hospital',
          targetCode: 'SG00004',
          itemHospital: 'Teaching Hospital',
          itemCode: 'CK00003',
        ),
        isFalse,
      );

      // 4. District Hospital Negombo vs District Hospital Negombo -> ACCEPT!
      expect(
        Hospital.matchesHospital(
          targetHospital: 'District Hospital',
          targetCode: 'WG00002',
          itemHospital: 'District Hospital Negombo',
          itemCode: 'WG00002',
        ),
        isTrue,
      );

      // 5. District Hospital vs Kurunegala -> REJECT!
      expect(
        Hospital.matchesHospital(
          targetHospital: 'District Hospital',
          targetCode: 'WG00002',
          itemHospital: 'Kurunegala Hospital',
          itemCode: 'NK00006',
        ),
        isFalse,
      );

      // 6. City General Nurse (WC00001) vs Patient booked appointment with slug 'city_general' -> ACCEPT!
      expect(
        Hospital.matchesHospital(
          targetHospital: 'City General Hospital',
          targetCode: 'WC00001',
          itemHospital: 'City General Hospital',
          itemCode: 'city_general',
        ),
        isTrue,
      );

      // 7. Kandy Nurse (CK00003) vs Patient booked appointment with slug 'teaching_hospital' -> ACCEPT!
      expect(
        Hospital.matchesHospital(
          targetHospital: 'Teaching Hospital',
          targetCode: 'CK00003',
          itemHospital: 'Teaching Hospital Kandy',
          itemCode: 'teaching_hospital',
        ),
        isTrue,
      );

      // 8. Staff has targetHospital name only, appointment has official code -> ACCEPT!
      expect(
        Hospital.matchesHospital(
          targetHospital: 'City General Hospital',
          itemHospital: 'City General Hospital',
          itemCode: 'WC00001',
        ),
        isTrue,
      );

      // 9. Staff has official code, appointment has no code but matching name -> ACCEPT!
      expect(
        Hospital.matchesHospital(
          targetHospital: 'City General Hospital',
          targetCode: 'WC00001',
          itemHospital: 'City General Hospital',
          itemCode: '',
        ),
        isTrue,
      );

      // 10. City General (WC00001) vs Negombo appointment with slug 'district_hospital' -> REJECT!
      expect(
        Hospital.matchesHospital(
          targetHospital: 'City General Hospital',
          targetCode: 'WC00001',
          itemHospital: 'District Hospital Negombo',
          itemCode: 'district_hospital',
        ),
        isFalse,
      );
    });

    test('Doctor scoping only returns doctors belonging to target hospital', () {
      final bookingService = BookingService.instance;

      // Doctors for Karapitiya
      final karapitiyaDocs = bookingService.getSampleDoctorsForHospital('Karapitiya Hospital');
      expect(karapitiyaDocs.isNotEmpty, isTrue);
      for (final doc in karapitiyaDocs) {
        expect(doc.hospitalId, 'SG00004');
        expect(doc.hospital.toLowerCase(), contains('karapitiya'));
      }

      // Doctors for Teaching Hospital Kandy
      final kandyDocs = bookingService.getSampleDoctorsForHospital('Teaching Hospital');
      expect(kandyDocs.isNotEmpty, isTrue);
      for (final doc in kandyDocs) {
        expect(doc.hospitalId, 'CK00003');
      }

      // Verify no doctor cross-leak
      final kandyDocNames = kandyDocs.map((d) => d.name).toSet();
      final karapitiyaDocNames = karapitiyaDocs.map((d) => d.name).toSet();
      expect(kandyDocNames.intersection(karapitiyaDocNames), isEmpty);
    });
  });
}
