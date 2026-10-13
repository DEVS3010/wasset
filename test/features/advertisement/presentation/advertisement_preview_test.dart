import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:waseet/features/advertisement/data/models/ad_failure.dart';
import 'package:waseet/features/advertisement/domain/entities/ad_entity.dart';
import 'package:waseet/features/advertisement/domain/entities/verify_license_entity.dart';
import 'package:waseet/features/advertisement/domain/repositories/ad_repository.dart';
import 'package:waseet/features/advertisement/presentation/advertiser_check/advertiser_check_page.dart';
import 'package:waseet/res/api_failure.dart';
import 'package:waseet/res/resource.dart';

class PreviewRepository extends Mock implements AdRepository {}

void main() {
  setUpAll(() => registerFallbackValue(<File>[]));

  Future<void> showPreview(
    WidgetTester tester,
    AdRepository repository,
    VerifyLicenseEntity verification,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => RepositoryProvider<AdRepository>.value(
          value: repository,
          child: MaterialApp(
            home: AdvertisementPreviewPage(verify: verification),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('تأكيد ونشر الإعلان'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد ونشر الإعلان'));
    await tester.pumpAndSettle();
  }

  for (final message in [
    duplicateLicenseMessage,
    'الرخصة منتهية الصلاحية',
    'رقم الرخصة غير صالح',
    'يرجى مراجعة بيانات الترخيص',
    ApiFailure.fallback,
  ]) {
    testWidgets('active publication UI displays $message and stays usable',
        (tester) async {
      final repository = PreviewRepository();
      when(
        () => repository.createAdWithVerification(
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async => ResourceError<AdEntity?>(message));
      await showPreview(
        tester,
        repository,
        VerifyLicenseEntity(
          advertiserId: '123456',
          adLicenseNumber: '654321',
        ),
      );
      expect(find.text(message), findsOneWidget);
      expect(find.byType(AdvertisementPreviewPage), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'تأكيد ونشر الإعلان'),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
      verify(
        () => repository.createAdWithVerification(
          '123456',
          '654321',
          '',
          any(),
        ),
      ).called(1);
    });
  }

  testWidgets('partial verification cannot submit empty license identifiers',
      (tester) async {
    final repository = PreviewRepository();
    await showPreview(tester, repository, VerifyLicenseEntity());
    expect(
      find.text(
        'بيانات الترخيص غير مكتملة. يرجى التحقق من الرخصة مجددًا.',
      ),
      findsOneWidget,
    );
    verifyNever(
      () => repository.createAdWithVerification(
        any(),
        any(),
        any(),
        any(),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
