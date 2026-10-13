import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:waseet/features/advertisement/data/datasources/ad_datasource.dart';
import 'package:waseet/features/advertisement/data/models/ad_failure.dart';
import 'package:waseet/features/advertisement/data/models/ad_model.dart';
import 'package:waseet/res/api_failure.dart';
import 'package:waseet/res/api_service.dart';
import 'package:waseet/res/resource.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  test('Arabic duplicate wording produces the exact requested message', () {
    final failure = adFailure<Object?>(
      ApiFailure.fromBody({
        'message': 'هذه الرخصة مستخدمة بالفعل',
      }),
    );
    expect(failure.message, 'هذه الرخصة مرتبطة بإعلان موجود بالفعل.');
  });
  test('nullable city image preserves required identity', () {
    final ad = AdModel.fromJson({
      'id': 1,
      'city': {'id': 2, 'name': 'City', 'image': null},
    }).toEntity();
    expect(ad.city?.image, '');
    expect(
      () => AdModel.fromJson({'name': 'Missing identity'}),
      throwsFormatException,
    );
  });
  test('global interceptor retains 422 status and validation details', () {
    final body = {
      'message': null,
      'errors': {
        'adLicenseNumber': ['Expired license'],
      },
    };
    final request = RequestOptions(path: '/advertisements');
    expect(
      () => ApiService().errorInterceptor(
        DioException(
          requestOptions: request,
          response: Response<Object?>(
            requestOptions: request,
            statusCode: 422,
            data: body,
          ),
        ),
      ),
      throwsA(
        isA<ApiFailure>()
            .having((e) => e.statusCode, 'status', 422)
            .having((e) => e.message, 'message', 'Expired license')
            .having((e) => e.errors, 'errors', body['errors']),
      ),
    );
  });
  late MockApiService api;
  late AdDatasource source;
  setUp(() {
    api = MockApiService();
    source = AdDatasource(apiService: api);
  });

  for (final creator in <Map<String, dynamic>?>[
    null,
    {},
    {'id': 111},
    {'name': 'User'},
    {'id': 111, 'name': 'User'},
    {
      'id': 111,
      'name': 'User',
      'email': 'u@example.com',
      'phone': '0500000000',
      'profile': {'name': 'Legacy', 'profile_image': null},
    },
  ]) {
    test('creator $creator converts without authenticated-user requirements',
        () {
      final ad = AdModel.fromJson({
        'id': 1,
        'created_by': creator,
        'attechments': [
          null,
          {'url': null},
          'image.jpg',
        ],
      }).toEntity();
      expect(ad.id, 1);
      expect(ad.createdBy?.id, creator?['id']);
      expect(ad.createdBy?.name, creator?['name']);
      expect(ad.images, ['image.jpg']);
    });
  }
  test('missing creator and optional presentation data', () {
    expect(AdModel.fromJson({'id': 1}).toEntity().createdBy, isNull);
  });

  Future<Resource<Object?>> create() =>
      source.createAdWithVerification('123456', '654321', '', []);

  test('valid license creates advertisement with minimal creator', () async {
    when(
      () => api.post<Map<String, dynamic>>(
        any(),
        data: any<Object>(named: 'data'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer(
      (_) async => {
        'data': {
          'id': 10,
          'created_by': {'id': 111, 'name': 'User'},
        },
      },
    );
    final result = await create();
    expect(result, isA<ResourceSuccess<Object?>>());
  });

  final bodies = <String, Object?>{
    'custom': {'message': 'يرجى مراجعة بيانات الترخيص'},
    'duplicate': {
      'message': 'Validation failed',
      'errors': {
        'adLicenseNumber': ['The license has already been taken.'],
      },
    },
    'expired': {'message': 'الرخصة منتهية الصلاحية'},
    'invalid': {
      'message': 'رقم الرخصة غير صالح',
      'errors': {
        'adLicenseNumber': ['رقم الرخصة غير صالح'],
      },
    },
    'service': {'message': 'خدمة التحقق غير متاحة حالياً'},
    'nullable': {'message': null, 'data': null, 'errors': null},
    'empty': null,
    'malformed': '<html>error</html>',
  };
  test('same owner can create two ads using different valid licenses',
      () async {
    final submittedLicenses = <String>[];
    when(
      () => api.post<Map<String, dynamic>>(
        any(),
        data: any<Object>(named: 'data'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer((invocation) async {
      final body = invocation.namedArguments[#data] as FormData;
      final license = body.fields
          .singleWhere((field) => field.key == 'adLicenseNumber')
          .value;
      submittedLicenses.add(license);
      return {
        'data': {
          'id': submittedLicenses.length,
          'created_by': {'id': 111, 'name': 'Same owner'},
        },
      };
    });
    for (final license in ['654321', '654322']) {
      expect(
        await source.createAdWithVerification('123456', license, '', []),
        isA<ResourceSuccess<Object?>>(),
      );
    }
    expect(submittedLicenses, ['654321', '654322']);
  });
  for (final entry in bodies.entries) {
    test('422 ${entry.key} reaches safe failure', () async {
      final failure = ApiFailure.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/advertisements'),
          response: Response<Object?>(
            requestOptions: RequestOptions(),
            statusCode: 422,
            data: entry.value,
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      when(
        () => api.post<Map<String, dynamic>>(
          any(),
          data: any<Object>(named: 'data'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(failure);
      final result = await create();
      expect(result, isA<ResourceError<Object?>>());
      expect(
        result.message,
        entry.key == 'duplicate' ? duplicateLicenseMessage : failure.message,
      );
      if (entry.key != 'duplicate') {
        expect(result.message, isNot(duplicateLicenseMessage));
      }
    });
  }
  test('network failure has user-safe fallback', () async {
    final failure = ApiFailure.fromDio(
      DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      ),
    );
    when(
      () => api.post<Map<String, dynamic>>(
        any(),
        data: any<Object>(named: 'data'),
        headers: any(named: 'headers'),
      ),
    ).thenThrow(failure);
    expect((await create()).message, ApiFailure.fallback);
  });
  for (final body in <Map<String, dynamic>?>[
    null,
    <String, dynamic>{'message': null},
    <String, dynamic>{'data': <Object?>[]},
  ]) {
    test('incomplete success payload $body is a failure', () async {
      when(
        () => api.post<Map<String, dynamic>>(
          any(),
          data: any<Object>(named: 'data'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => body);
      expect(await create(), isA<ResourceError<Object?>>());
    });
  }
  test('HTTP 200 list with multiple minimal creators converts successfully', () async {
    when(
      () => api.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => {
        'data': [
          {
            'id': 1,
            'created_by': {'id': 111, 'name': 'User'},
          },
          {
            'id': 2,
            'created_by': {'id': 111, 'name': 'User'},
          },
        ],
      },
    );
    final result = await source.getAds();
    expect(result, isA<ResourceSuccess<Object?>>());
    expect(result.data?.length, 2);
  });
  test('verifyLicense unwraps the NHC result.advertisement envelope', () async {
    when(
      () => api.post<Map<String, dynamic>>(
        any(),
        data: any<Object>(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => {
        'message': 'تم التحقق من الرخصة بنجاح',
        'data': {
          'result': {
            'advertisement': {
              'adLicenseNumber': '654321',
              'advertiserId': '123456',
              'responsibleEmployeeName': 'مسؤول الإعلان',
              'responsibleEmployeePhoneNumber': '0500000000',
              'streetWidth': '20',
              'numberOfRooms': '3',
              'propertyArea': 300,
              'channels': [1, 'منصة'],
              'propertyUtilities': ['كهرباء', 2],
              'location': {'region': 'الرياض', 'city': 'الرياض'},
            },
          },
        },
      },
    );
    final result = await source.verifyLicense('123456', '654321');
    expect(result, isA<ResourceSuccess<Object?>>());
    final verification = result.data;
    expect(verification?.adLicenseNumber, '654321');
    expect(verification?.advertiserId, '123456');
    expect(verification?.responsibleEmployeeName, 'مسؤول الإعلان');
    expect(verification?.streetWidth, 20);
    expect(verification?.numberOfRooms, 3);
    expect(verification?.propertyArea, 300);
    expect(verification?.channels, ['1', 'منصة']);
    expect(verification?.propertyUtilities, ['كهرباء', '2']);
    expect(verification?.location?.region, 'الرياض');
  });
  test('verifyLicense coerces numeric identifiers in a flat payload', () async {
    when(
      () => api.post<Map<String, dynamic>>(
        any(),
        data: any<Object>(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => {
        'message': 'تم التحقق من الرخصة بنجاح',
        'data': {
          'adLicenseNumber': 654321,
          'advertiserId': 123456,
          'endDate': '2027-01-01',
        },
      },
    );
    final result = await source.verifyLicense('123456', '654321');
    expect(result, isA<ResourceSuccess<Object?>>());
    expect(result.data?.adLicenseNumber, '654321');
    expect(result.data?.endDate, '2027-01-01');
  });
  for (final body in <Map<String, dynamic>?>[
    {'message': 'لا توجد بيانات', 'data': null},
    {'message': 'لا توجد بيانات'},
    {
      'message': 'تم التحقق من الرخصة بنجاح',
      'data': {'unrelated': 'shape'},
    },
  ]) {
    test('verifyLicense without identifiers is a failure for $body', () async {
      when(
        () => api.post<Map<String, dynamic>>(
          any(),
          data: any<Object>(named: 'data'),
        ),
      ).thenAnswer((_) async => body);
      expect(
        await source.verifyLicense('123456', '654321'),
        isA<ResourceError<Object?>>(),
      );
    });
  }
  test('city without identity maps to a null city instead of throwing', () {
    final ad = AdModel.fromJson({
      'id': 1,
      'city': {'name': 'City without id'},
      'created_at': null,
    }).toEntity();
    expect(ad.city, isNull);
  });
  test('malformed city date does not fail advertisement conversion', () {
    final ad = AdModel.fromJson({
      'id': 1,
      'city': {'id': 2, 'name': 'City', 'created_at': 'not-a-date'},
    }).toEntity();
    expect(ad.city?.id, 2);
  });
  test('listing skips malformed entries instead of failing the page',
      () async {
    when(
      () => api.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => {
        'data': [
          {
            'id': 1,
            'created_by': {'id': 111, 'name': 'User'},
          },
          'malformed-entry',
          42,
          {
            'id': 2,
            'created_by': {'id': 111, 'name': 'User'},
          },
        ],
      },
    );
    final result = await source.getAds();
    expect(result, isA<ResourceSuccess<Object?>>());
    expect(result.data?.length, 2);
  });
  test('advertisement with category as a list degrades instead of throwing',
      () {
    final ad = AdModel.fromJson({
      'id': 7,
      'created_by': {'id': 111, 'name': 'User'},
      'category': ['unexpected', 'list'],
    }).toEntity();
    expect(ad.id, 7);
    expect(ad.category, isNull);
    expect(ad.createdBy?.id, 111);
    expect(ad.createdBy?.name, 'User');
  });
  test('advertisement with wrong-typed nested objects degrades to nulls', () {
    final ad = AdModel.fromJson({
      'id': 8,
      'created_by': ['not', 'a', 'map'],
      'city': 'Riyadh',
      'neighborhood': 42,
      'attechments': {'url': 'image.jpg'},
    }).toEntity();
    expect(ad.id, 8);
    expect(ad.createdBy, isNull);
    expect(ad.city, isNull);
    expect(ad.neighborhood, isNull);
    expect(ad.images, isEmpty);
  });
  test('mixed list keeps valid and degraded ads while skipping unusable ones',
      () async {
    when(
      () => api.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => {
        'data': [
          {
            'id': 1,
            'created_by': {'id': 111, 'name': 'User'},
            'price': 500000,
          },
          {
            // Wrong-typed nested category: ad is kept, category degrades.
            'id': 2,
            'created_by': {'id': 111, 'name': 'User'},
            'category': ['unexpected'],
          },
          {
            // No usable identity: item is skipped, page still succeeds.
            'created_by': {'id': 111, 'name': 'User'},
          },
          {
            'id': 3,
            'price': null,
            'warranties': null,
          },
        ],
      },
    );
    final result = await source.getAds();
    expect(result, isA<ResourceSuccess<Object?>>());
    expect(result.data?.length, 3);
    expect(result.data?[0].createdBy?.id, 111);
    expect(result.data?[0].createdBy?.name, 'User');
    expect(result.data?[1].category, isNull);
    expect(result.data?[2].warranties, isNull);
  });
}
