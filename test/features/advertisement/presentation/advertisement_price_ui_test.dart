import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:waseet/features/advertisement/data/models/ad_model.dart';
import 'package:waseet/features/advertisement/domain/entities/ad_entity.dart';
import 'package:waseet/features/advertisement/domain/repositories/ad_repository.dart';
import 'package:waseet/features/advertisement/presentation/ad_details/cubit/ad_details_cubit.dart';
import 'package:waseet/features/advertisement/presentation/ad_details/widgets/ad_details_body.dart';
import 'package:waseet/features/advertisement/presentation/advertisements/cubit/advertisements_cubit.dart';
import 'package:waseet/features/advertisement/presentation/my_ads/widgets/ad_card.dart';

class _DetailsRepository extends Fake implements AdRepository {}

class MockAdvertisementsCubit extends Mock implements AdvertisementsCubit {}

AdEntity adFromJson(Map<String, dynamic> json) =>
    AdModel.fromJson(json).toEntity();

Future<void> pumpDetails(WidgetTester tester, AdEntity ad) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        home: BlocProvider(
          create: (_) => AdDetailsCubit(
            adRepository: _DetailsRepository(),
            ad: ad,
          ),
          child: const Scaffold(body: AdDetailsBody()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpCard(
  WidgetTester tester,
  MockAdvertisementsCubit cubit,
  AdEntity ad,
) async {
  // 600px: the pre-existing AdFeature chips row (ad_card.dart) has fixed
  // content that overflows narrow viewports regardless of price text —
  // tracked as a separate unrelated UI issue, so the wide viewport isolates
  // the price assertions under test.
  tester.view.physicalSize = const Size(600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        home: BlocProvider<AdvertisementsCubit>.value(
          value: cubit,
          child: Scaffold(body: AdCard(ad: ad)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Advertisement price UI consistency', () {
    testWidgets('416: header and regulatory section agree on 450,000 ريال',
        (tester) async {
      final ad = adFromJson({
        'id': 416,
        'type_of_advertisement': 'buy',
        'category': {'id': 1, 'name': 'شقة'},
        'price': null,
        'meter_price': null,
        'advertising_license_number': 7100326529,
        'rega_compliance': {
          'status': 'verified',
          'required_fields': {
            'property_price': 450000,
            'property_type': 'شقة',
            'number_of_rooms': 4,
            'property_area': 900,
          },
        },
      });
      await pumpDetails(tester, ad);

      // Header and regulatory property section show the identical grouped
      // official price.
      expect(find.text('450,000 ريال'), findsNWidgets(2));
      expect(find.text('سعر الوحدة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('land: total and per-m² are never confused', (tester) async {
      final ad = adFromJson({
        'id': 415,
        'type_of_advertisement': 'buy',
        'category': {'id': 2, 'name': 'ارض'},
        'price': null,
        'meter_price': null,
        'rega_compliance': {
          'status': 'verified',
          'property': {'land_total_price': 449990},
          'required_fields': {
            'property_price': 1000,
            'property_type': 'ارض',
            'property_area': 449.99,
          },
        },
      });
      await pumpDetails(tester, ad);

      // Header carries the documented total, not the 1,000 unit rate.
      expect(find.text('449,990 ريال'), findsNWidgets(2));
      expect(find.text('إجمالي سعر الأرض'), findsOneWidget);
      expect(find.text('سعر المتر المربع'), findsOneWidget);
      expect(find.text('1,000 ريال/م²'), findsOneWidget);
      // Official unit value keeps its own row/meaning.
      expect(find.text('سعر الوحدة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rental: amount shown with no invented period',
        (tester) async {
      final ad = adFromJson({
        'id': 412,
        'type_of_advertisement': 'rent',
        'category': {'id': 1, 'name': 'شقة'},
        'price': null,
        'rega_compliance': {
          'status': 'verified',
          'required_fields': {'property_price': 42000},
        },
      });
      await pumpDetails(tester, ad);

      expect(find.text('42,000 ريال'), findsNWidgets(2));
      expect(find.textContaining('شهري'), findsNothing);
      expect(find.textContaining('سنوي'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('cards match details pricing for sale, land, and legacy',
        (tester) async {
      final cubit = MockAdvertisementsCubit();
      const state = AdvertisementsState();
      when(() => cubit.state).thenReturn(state);
      when(() => cubit.stream).thenAnswer((_) => Stream.value(state));
      when(() => cubit.isClosed).thenReturn(false);

      final sale = adFromJson({
        'id': 416,
        'type_of_advertisement': 'buy',
        'category': {'id': 1, 'name': 'شقة'},
        'price': null,
        'rega_compliance': {
          'status': 'verified',
          'required_fields': {'property_price': 450000},
        },
      });
      await pumpCard(tester, cubit, sale);
      expect(find.text('450,000'), findsOneWidget);
      expect(find.text('null'), findsNothing);

      final legacy = adFromJson({'id': 7, 'price': 300000});
      await pumpCard(tester, cubit, legacy);
      expect(find.text('300,000'), findsOneWidget);
    });
  });
}
