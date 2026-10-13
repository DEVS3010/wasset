import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:waseet/features/advertisement/data/models/ad_model.dart';
import 'package:waseet/features/advertisement/data/models/rega_compliance_model.dart';
import 'package:waseet/features/advertisement/domain/entities/ad_entity.dart';
import 'package:waseet/features/advertisement/domain/entities/rega_compliance_entity.dart';
import 'package:waseet/features/advertisement/presentation/ad_details/widgets/ad_regulatory_details.dart';

const syntheticRegaJson = {
  'id': 1,
  'advertising_license_number': '7100000001',
  'rega_compliance': {
    'status': 'verified',
    'location_warning':
        'نأمل مطابقة الموقع أدناه مع الموقع المذكور في وصف موقع العقار المكتوب',
    'verified_at': '2026-10-02T10:00:00+00:00',
    'expires_at': '2099-01-01T20:59:59+00:00',
    'ad_license_number': '7100000001',
    'advertiser_name': 'Synthetic advertiser',
    'end_date': '01/01/2099',
    'property': {
      'property_price': 250000,
      'property_type': 'Synthetic property',
      'property_age': 'جديد',
      'number_of_rooms': 4,
      'property_area': 150,
      'property_face': 'شمالية',
      'street_width': 20
    },
    'location': {
      'region': 'Synthetic region',
      'district': 'Synthetic district',
      'city': 'Synthetic city',
      'latitude': 24.7,
      'longitude': 46.7
    },
    'required_fields': {
      'ad_license_number': '7100000001',
      'end_date': '01/01/2099',
      'responsible_employee_phone_number': '0500000001',
      'responsible_employee_name': 'Synthetic employee',
      'property_price': 250000,
      'property_type': 'Synthetic property',
      'plan_number': 'SYNTHETIC-PLAN',
      'property_age': 'جديد',
      'guarantees_and_their_duration': 'ضمان إنشائي لمدة 10 سنوات',
      'property_usages': ['سكني'],
      'land_number': 'SYNTHETIC-LAND',
      'number_of_rooms': 4,
      'obligations_on_the_property': null,
      'property_area': 150,
      'property_face': 'شمالية',
      'street_width': 20,
      'property_utilities': [],
      'location_description_on_moj_deed': 'Synthetic deed location',
      'region': 'Synthetic region',
      'district': 'Synthetic district',
      'city': 'Synthetic city'
    },
    'required_field_status': {}
  }
};

void main() {
  group('REGA Compliance Model & Entity Tests', () {
    test('1. Full rega_compliance parsing and serialization', () {
      final model = AdModel.fromJson(syntheticRegaJson);
      expect(model.id, 1);
      expect(model.advertisingLicenseNumber, 7100000001);
      final rega = model.regaCompliance;
      expect(rega, isNotNull);
      expect(rega!.status, 'verified');
      expect(rega.locationWarning,
          'نأمل مطابقة الموقع أدناه مع الموقع المذكور في وصف موقع العقار المكتوب');
      expect(rega.verifiedAt, '2026-10-02T10:00:00+00:00');
      expect(rega.expiresAt, '2099-01-01T20:59:59+00:00');
      expect(rega.adLicenseNumber, '7100000001');
      expect(rega.advertiserName, 'Synthetic advertiser');
      expect(rega.endDate, '01/01/2099');

      // Location
      expect(rega.location?.region, 'Synthetic region');
      expect(rega.location?.district, 'Synthetic district');
      expect(rega.location?.city, 'Synthetic city');
      expect(rega.location?.latitude, 24.7);
      expect(rega.location?.longitude, 46.7);

      // Property
      expect(rega.property?.propertyPrice, 250000);
      expect(rega.property?.propertyType, 'Synthetic property');
      expect(rega.property?.propertyAge, 'جديد');
      expect(rega.property?.numberOfRooms, 4);
      expect(rega.property?.propertyArea, 150);
      expect(rega.property?.propertyFace, 'شمالية');
      expect(rega.property?.streetWidth, 20);

      // Serialization round-trip
      final json = rega.toJson();
      expect(json['status'], 'verified');
      expect(json['required_fields'], isNotNull);
    });

    test('2. All 21 required fields mapping in RegaRequiredFieldsModel & Entity', () {
      final adEntity = AdModel.fromJson(syntheticRegaJson).toEntity();
      final req = adEntity.regaCompliance?.requiredFields;
      expect(req, isNotNull);

      // Verify all 21 fields
      expect(req!.adLicenseNumber, '7100000001'); // 1
      expect(req.endDate, '01/01/2099'); // 2
      expect(req.responsibleEmployeePhoneNumber, '0500000001'); // 3
      expect(req.responsibleEmployeeName, 'Synthetic employee'); // 4
      expect(req.propertyPrice, 250000); // 5
      expect(req.propertyType, 'Synthetic property'); // 6
      expect(req.planNumber, 'SYNTHETIC-PLAN'); // 7
      expect(req.propertyAge, 'جديد'); // 8
      expect(req.guaranteesAndTheirDuration, 'ضمان إنشائي لمدة 10 سنوات'); // 9
      expect(req.propertyUsages, ['سكني']); // 10
      expect(req.landNumber, 'SYNTHETIC-LAND'); // 11
      expect(req.numberOfRooms, 4); // 12
      expect(req.obligationsOnTheProperty, isNull); // 13
      expect(req.propertyArea, 150); // 14
      expect(req.propertyFace, 'شمالية'); // 15
      expect(req.streetWidth, 20); // 16
      expect(req.propertyUtilities, isEmpty); // 17
      expect(req.locationDescriptionOnMojDeed, 'Synthetic deed location'); // 18
      expect(req.region, 'Synthetic region'); // 19
      expect(req.district, 'Synthetic district'); // 20
      expect(req.city, 'Synthetic city'); // 21
    });

    test('3. rega_compliance null preserves normal AdEntity creation', () {
      final ad = AdModel.fromJson({'id': 100}).toEntity();
      expect(ad.id, 100);
      expect(ad.regaCompliance, isNull);
    });

    test('4. required_fields null degrades safely', () {
      final ad = AdModel.fromJson({
        'id': 101,
        'rega_compliance': {
          'status': 'verified',
          'required_fields': null,
        }
      }).toEntity();
      expect(ad.regaCompliance?.status, 'verified');
      expect(ad.regaCompliance?.requiredFields, isNull);
    });

    test('5. Missing individual fields remain null without crashing', () {
      final model = RegaRequiredFieldsModel.fromJson({
        'ad_license_number': '123',
      });
      expect(model.adLicenseNumber, '123');
      expect(model.endDate, isNull);
      expect(model.responsibleEmployeeName, isNull);
      expect(model.propertyPrice, isNull);
    });

    test('6. Wrong-type nested objects degrade gracefully', () {
      final model = AdModel.fromJson({
        'id': 102,
        'rega_compliance': 'wrong_string_type',
      });
      expect(model.regaCompliance, isNull);

      final regaModel = RegaComplianceModel.fromJson({
        'property': 'not_a_map',
        'location': 12345,
        'required_fields': false,
      });
      expect(regaModel.property, isNull);
      expect(regaModel.location, isNull);
      expect(regaModel.requiredFields, isNull);
    });

    test('7. Numeric and string value conversions where supported', () {
      final model = RegaRequiredFieldsModel.fromJson({
        'property_price': '350000.5',
        'number_of_rooms': '6',
        'property_area': '220',
        'street_width': '15.5',
        'property_age': 3,
      });
      expect(model.propertyPrice, 350000.5);
      expect(model.numberOfRooms, 6);
      expect(model.propertyArea, 220);
      expect(model.streetWidth, 15.5);
      expect(model.propertyAge, 3);
    });

    test('8. Empty property_usages handled cleanly', () {
      final model = RegaRequiredFieldsModel.fromJson({
        'property_usages': <String>[],
      });
      expect(model.propertyUsages, isEmpty);
    });

    test('9. Multiple property_usages parsed correctly', () {
      final model = RegaRequiredFieldsModel.fromJson({
        'property_usages': ['سكني', 'تجاري'],
      });
      expect(model.propertyUsages, ['سكني', 'تجاري']);
    });

    test('10. Empty property_utilities handled cleanly', () {
      final model = RegaRequiredFieldsModel.fromJson({
        'property_utilities': <String>[],
      });
      expect(model.propertyUtilities, isEmpty);
    });

    test('11. Multiple property_utilities parsed correctly', () {
      final model = RegaRequiredFieldsModel.fromJson({
        'property_utilities': ['كهرباء', 'مياه', 'صرف صحي', 'ألياف بصرية'],
      });
      expect(model.propertyUtilities,
          ['كهرباء', 'مياه', 'صرف صحي', 'ألياف بصرية']);
    });

    test('12. Zero numeric values are preserved, not converted to null', () {
      final model = RegaRequiredFieldsModel.fromJson({
        'property_price': 0,
        'number_of_rooms': 0,
        'property_area': 0,
        'street_width': 0,
      });
      expect(model.propertyPrice, 0);
      expect(model.numberOfRooms, 0);
      expect(model.propertyArea, 0);
      expect(model.streetWidth, 0);
    });

    test('13. Null obligations handled gracefully', () {
      final model = RegaRequiredFieldsModel.fromJson({
        'obligations_on_the_property': null,
      });
      expect(model.obligationsOnTheProperty, isNull);
    });

    test('14. Date formatting values preserved as received', () {
      final model = RegaRequiredFieldsModel.fromJson({
        'end_date': '01/01/2099',
      });
      expect(model.endDate, '01/01/2099');
    });

    test('15. Verified and unknown status handling', () {
      final verified = RegaComplianceModel.fromJson({'status': 'verified'});
      expect(verified.status, 'verified');

      final unknown = RegaComplianceModel.fromJson({'status': 'custom_unknown_state'});
      expect(unknown.status, 'custom_unknown_state');
    });

    test('16. Coordinates from rega_compliance.location prioritized', () {
      final ad = AdEntity(
        latitude: 10.0,
        longitude: 20.0,
        regaCompliance: const RegaComplianceEntity(
          location: RegaLocationEntity(
            latitude: 24.7136,
            longitude: 46.6753,
          ),
        ),
      );
      final pos = AdRegulatoryDetails.propertyPosition(ad);
      expect(pos, const LatLng(24.7136, 46.6753));
    });

    test('17. Invalid or missing coordinates degrade gracefully', () {
      final ad1 = AdEntity(
        regaCompliance: const RegaComplianceEntity(
          location: RegaLocationEntity(
            latitude: 95.0, // Invalid latitude > 90
            longitude: 46.0,
          ),
        ),
      );
      expect(AdRegulatoryDetails.propertyPosition(ad1), isNull);

      final ad2 = AdEntity(
        regaCompliance: const RegaComplianceEntity(
          location: RegaLocationEntity(
            latitude: 0,
            longitude: 0,
          ),
        ),
      );
      expect(AdRegulatoryDetails.propertyPosition(ad2), isNull);
    });

    test('18. Legacy advertisement without regulatory data falls back to ad coordinates', () {
      final ad = AdEntity(
        latitude: 21.5433,
        longitude: 39.1728,
      );
      final pos = AdRegulatoryDetails.propertyPosition(ad);
      expect(pos, const LatLng(21.5433, 39.1728));
    });

    test('19. Conflicting official and legacy values: official values preferred', () {
      final ad = AdModel.fromJson({
        'id': 1,
        'price': 100000,
        'land_space': 100,
        'property_age': 1,
        'rega_compliance': {
          'required_fields': {
            'property_price': 500000,
            'property_area': 350,
            'property_age': 10,
          }
        }
      }).toEntity();

      expect(ad.price, 100000); // Legacy preserved on root
      expect(ad.regaCompliance?.requiredFields?.propertyPrice, 500000); // Official preserved
      expect(ad.regaCompliance?.requiredFields?.propertyArea, 350);
      expect(ad.regaCompliance?.requiredFields?.propertyAge, 10);
    });

    test('20. Mixed advertisement list with and without rega_compliance survives pagination', () {
      final listJson = [
        {'id': 1, 'price': 100},
        syntheticRegaJson,
        {'id': 3, 'price': 300},
      ];
      final ads = listJson.map((e) => AdModel.fromJson(e).toEntity()).toList();
      expect(ads.length, 3);
      expect(ads[0].regaCompliance, isNull);
      expect(ads[1].regaCompliance, isNotNull);
      expect(ads[1].regaCompliance?.requiredFields?.planNumber, 'SYNTHETIC-PLAN');
      expect(ads[2].regaCompliance, isNull);
    });
  });

  group('REGA Compliance UI Widget Tests', () {
    testWidgets('Renders all 21 synthetic regulatory fields with exact values in Arabic',
        (tester) async {
      tester.view.physicalSize = const Size(375, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ad = AdModel.fromJson(syntheticRegaJson).toEntity();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdRegulatoryDetails(ad: ad),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Acceptance criterion:
      // When required_fields.plan_number = "SYNTHETIC-PLAN",
      // UI displays SYNTHETIC-PLAN, not "غير متوفر"
      expect(find.text('SYNTHETIC-PLAN'), findsOneWidget);
      expect(find.text('SYNTHETIC-LAND'), findsOneWidget);
      expect(find.text('Synthetic employee'), findsOneWidget);
      expect(find.text('0500000001'), findsOneWidget);
      expect(find.text('01/01/2099'), findsOneWidget);
      expect(find.text('7100000001'), findsOneWidget); // License number
      expect(find.text('250,000 ريال'), findsOneWidget); // Property price
      expect(find.text('Synthetic property'), findsOneWidget); // Property type
      expect(find.text('جديد'), findsOneWidget); // Property age
      expect(find.text('ضمان إنشائي لمدة 10 سنوات'), findsOneWidget); // Guarantees
      expect(find.text('سكني'), findsOneWidget); // Usages chip
      expect(find.text('4'), findsOneWidget); // Rooms
      expect(find.text('150 م²'), findsOneWidget); // Area
      expect(find.text('شمالية'), findsOneWidget); // Face
      expect(find.text('20 م'), findsOneWidget); // Street width
      expect(find.text('Synthetic deed location'), findsOneWidget); // Deed location
      expect(find.text('Synthetic region'), findsOneWidget); // Region
      expect(find.text('Synthetic district'), findsOneWidget); // District
      expect(find.text('Synthetic city'), findsOneWidget); // City
      expect(find.text('تم التحقق'), findsOneWidget); // Status verified

      // Obligations was null in synthetic payload -> displays غير متوفر
      expect(find.text(unavailableAdValue), findsWidgets);

      // Warning text
      expect(
        find.text('نأمل مطابقة الموقع أدناه مع الموقع المذكور في وصف موقع العقار المكتوب'),
        findsOneWidget,
      );

      // Map is rendered because coordinates are 24.7, 46.7
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('Location order: Region -> City -> District -> Deed -> Warning -> Map',
        (tester) async {
      tester.view.physicalSize = const Size(375, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ad = AdModel.fromJson(syntheticRegaJson).toEntity();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdRegulatoryDetails(ad: ad),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final regionFinder = find.text('المنطقة');
      final cityFinder = find.text('المدينة');
      final districtFinder = find.text('الحي');
      final deedFinder = find.text('وصف موقع العقار حسب الصك');
      final warningFinder = find.text(
        'نأمل مطابقة الموقع أدناه مع الموقع المذكور في وصف موقع العقار المكتوب',
      );
      final mapFinder = find.byType(GoogleMap);

      expect(tester.getTopLeft(regionFinder).dy,
          lessThan(tester.getTopLeft(cityFinder).dy));
      expect(tester.getTopLeft(cityFinder).dy,
          lessThan(tester.getTopLeft(districtFinder).dy));
      expect(tester.getTopLeft(districtFinder).dy,
          lessThan(tester.getTopLeft(deedFinder).dy));
      expect(tester.getTopLeft(deedFinder).dy,
          lessThan(tester.getTopLeft(warningFinder).dy));
      expect(tester.getTopLeft(warningFinder).dy,
          lessThan(tester.getTopLeft(mapFinder).dy));
    });

    testWidgets('Displays multiple utility chips in services section',
        (tester) async {
      final json = Map<String, dynamic>.from(syntheticRegaJson);
      final regaMap = Map<String, dynamic>.from(json['rega_compliance'] as Map);
      final reqMap = Map<String, dynamic>.from(regaMap['required_fields'] as Map);
      reqMap['property_utilities'] = ['كهرباء', 'مياه', 'ألياف بصرية'];
      regaMap['required_fields'] = reqMap;
      json['rega_compliance'] = regaMap;

      final ad = AdModel.fromJson(json).toEntity();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdRegulatoryDetails(ad: ad),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('كهرباء'), findsOneWidget);
      expect(find.text('مياه'), findsOneWidget);
      expect(find.text('ألياف بصرية'), findsOneWidget);
    });

    testWidgets('Displays long responsible person names and descriptions cleanly',
        (tester) async {
      final json = Map<String, dynamic>.from(syntheticRegaJson);
      final regaMap = Map<String, dynamic>.from(json['rega_compliance'] as Map);
      final reqMap = Map<String, dynamic>.from(regaMap['required_fields'] as Map);
      reqMap['responsible_employee_name'] = 'عبدالرحمن بن عبدالعزيز بن محمد آل سعود الوسيط العقاري المعتمد';
      reqMap['location_description_on_moj_deed'] =
          'يقع العقار في الجزء الشمالي من الحي على امتداد شارع الملك فهد متفرعا من الطريق الدائري ومحاذيا للمخطط المعتمد رقم 505';
      regaMap['required_fields'] = reqMap;
      json['rega_compliance'] = regaMap;

      final ad = AdModel.fromJson(json).toEntity();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdRegulatoryDetails(ad: ad),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('عبدالرحمن بن عبدالعزيز بن محمد آل سعود الوسيط العقاري المعتمد'),
        findsOneWidget,
      );
      expect(
        find.text('يقع العقار في الجزء الشمالي من الحي على امتداد شارع الملك فهد متفرعا من الطريق الدائري ومحاذيا للمخطط المعتمد رقم 505'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
