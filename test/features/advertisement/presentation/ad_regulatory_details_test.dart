import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:waseet/features/advertisement/data/models/ad_model.dart';
import 'package:waseet/features/advertisement/domain/entities/ad_entity.dart';
import 'package:waseet/features/advertisement/domain/repositories/ad_repository.dart';
import 'package:waseet/features/advertisement/presentation/ad_details/cubit/ad_details_cubit.dart';
import 'package:waseet/features/advertisement/presentation/ad_details/widgets/ad_details_body.dart';
import 'package:waseet/features/advertisement/presentation/ad_details/widgets/ad_regulatory_details.dart';

class UnusedDetailsRepository extends Fake implements AdRepository {}

void main() {
  testWidgets(
      'published details tolerate minimal creator and long contact text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final ad = AdModel.fromJson({
      'id': 1,
      'created_by': {'id': 111, 'name': 'اسم طويل ' * 12},
      'city': {'id': 1, 'name': 'اسم مدينة طويل ' * 12},
      'contact_phone': '0501234567',
      'price': 123456789012345,
    }).toEntity();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          home: BlocProvider(
            create: (_) => AdDetailsCubit(
              adRepository: UnusedDetailsRepository(),
              ad: ad,
            ),
            child: const Scaffold(body: AdDetailsBody()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AdRegulatoryDetails), findsOneWidget);
    await tester.ensureVisible(find.text('بيانات التواصل'));
    await tester.pumpAndSettle();
    expect(find.textContaining('null'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('missing service and warranty values remain unknown', () {
    final ad = AdModel.fromJson({'id': 1}).toEntity();
    expect(ad.electricityMeter, isNull);
    expect(ad.waterMeter, isNull);
    expect(ad.sewerage, isNull);
    expect(ad.warranties, isNull);
    expect(ad.propertyDispute, isNull);
    for (final entry in {
      true: true,
      false: false,
      '1': true,
      '0': false,
      1: true,
      0: false,
    }.entries) {
      expect(
        AdModel.fromJson({'id': 1, 'electricity_meter': entry.key})
            .toEntity()
            .electricityMeter,
        entry.value,
      );
    }
  });

  test('map uses property coordinates and rejects missing or invalid values',
      () {
    expect(
      AdRegulatoryDetails.propertyPosition(
        AdEntity(latitude: 24.7, longitude: 46.7),
      ),
      const LatLng(24.7, 46.7),
    );
    for (final ad in [
      AdEntity(),
      AdEntity(latitude: 0, longitude: 0),
      AdEntity(latitude: double.nan, longitude: 46),
      AdEntity(latitude: 91, longitude: 46),
      AdEntity(latitude: 24, longitude: 181),
      AdEntity(latitude: 24, longitude: double.infinity),
    ]) {
      expect(AdRegulatoryDetails.propertyPosition(ad), isNull);
    }
  });

  testWidgets('required labels and nullable values render in narrow RTL layout',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdRegulatoryDetails(
              ad: AdEntity(
                advertisingLicenseNumber: 123456789,
                price: 500000,
                propertyAge: 5,
                landSpace: 300,
                facade: 'north',
                advertiserName: 'معلن',
                contactPhone: '0501234567',
              ),
            ),
          ),
        ),
      ),
    );
    for (final label in [
      'رقم ترخيص الإعلان',
      'تاريخ انتهاء رخصة الإعلان',
      'اسم مسؤول الإعلان',
      'رقم جوال مسؤول الإعلان',
      'عنوان العقار',
      'سعر الوحدة',
      'نوع العقار',
      'رقم المخطط',
      'عمر العقار',
      'الضمانات ومدتها',
      'استخدام العقار',
      'رقم القطعة',
      'عدد الغرف',
      'الالتزامات الأخرى على العقار',
      'مساحة العقار',
      'واجهة العقار',
      'عرض الشارع',
      'خدمات العقار',
      'المنطقة',
      'المدينة',
      'الحي',
      'وصف موقع العقار حسب الصك',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('123456789'), findsOneWidget);
    expect(find.text('500,000 ريال'), findsOneWidget);
    expect(find.text('300 م²'), findsOneWidget);
    expect(find.text(unavailableAdValue), findsWidgets);
    expect(find.textContaining('null'), findsNothing);
    expect(find.byType(GoogleMap), findsNothing);
    final description = find.text('وصف موقع العقار حسب الصك');
    final warning = find.text(adLocationWarning);
    final mapFallback = find.text('موقع العقار غير متوفر');
    expect(
      tester.getTopLeft(description).dy,
      lessThan(tester.getTopLeft(warning).dy),
    );
    expect(
      tester.getTopLeft(warning).dy,
      lessThan(tester.getTopLeft(mapFallback).dy),
    );
    await tester.ensureVisible(mapFallback);
    await tester.pumpAndSettle();
    expect(Directionality.of(tester.element(warning)), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}
