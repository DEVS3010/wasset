import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:waseet/features/advertisement/data/datasources/ad_datasource.dart';
import 'package:waseet/features/advertisement/data/models/ad_failure.dart';
import 'package:waseet/features/advertisement/data/repositories/ad_repository_impl.dart';
import 'package:waseet/features/advertisement/domain/entities/ad_entity.dart';
import 'package:waseet/features/advertisement/domain/entities/request/add_ad_request.dart';
import 'package:waseet/features/advertisement/domain/repositories/ad_repository.dart';
import 'package:waseet/features/advertisement/presentation/add_new_ad/cubit/add_new_ad_cubit.dart';
import 'package:waseet/features/advertisement/presentation/advertisements/cubit/advertisements_cubit.dart';
import 'package:waseet/features/user/domain/repositories/complaints_repository.dart';
import 'package:waseet/features/user/domain/repositories/home_repository.dart';
import 'package:waseet/res/api_service.dart';
import 'package:waseet/res/resource.dart';

class MockHome extends Mock implements HomeRepository {}

class MockAd extends Mock implements AdRepository {}

class MockComplaints extends Mock implements ComplaintRepository {}

class MockApi extends Mock implements ApiService {}

void main() {
  late MockHome home;
  setUpAll(() => registerFallbackValue(AddAdRequest.empty));
  setUp(() {
    home = MockHome();
    when(() => home.getCities(pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => Resource.success([]));
    when(() => home.getCategories())
        .thenAnswer((_) async => Resource.success([]));
    when(() => home.getNeighborhood(any()))
        .thenAnswer((_) async => Resource.success([]));
  });
  test('HTTP 200 minimal creators reach listing loaded state', () async {
    final api = MockApi();
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
    final cubit = AdvertisementsCubit(
      adRepository:
          AdRepositoryImpl(adDatasource: AdDatasource(apiService: api)),
      homeRepository: home,
      complaintRepository: MockComplaints(),
    );
    await cubit.stream
        .firstWhere((s) => s.status != AdvertisementsStatus.loading);
    expect(cubit.state.status, AdvertisementsStatus.loaded);
    expect(cubit.state.ads.length, 2);
    await cubit.close();
  });
  for (final success in [true, false]) {
    test('creation ${success ? 'success' : 'failure'} and concurrent guard',
        () async {
      final repo = MockAd();
      final pending = Completer<Resource<AdEntity?>>();
      when(() => repo.createAd(any())).thenAnswer((_) => pending.future);
      final cubit = AddNewAdCubit(homeRepository: home, adRepository: repo);
      await cubit.stream.firstWhere((s) => s.status == AddNewAdStatus.loaded);
      final states = <AddNewAdState>[];
      final subscription = cubit.stream.listen(states.add);
      final first = cubit.addNewAd();
      await cubit.addNewAd();
      expect(cubit.state.status, AddNewAdStatus.submitting);
      pending.complete(
        success
            ? Resource.success(AdEntity(id: 1))
            : Resource.error(duplicateLicenseMessage),
      );
      await first;
      await Future<void>.delayed(Duration.zero);
      verify(() => repo.createAd(any())).called(1);
      expect(
        states.any(
          (s) =>
              s.status ==
              (success ? AddNewAdStatus.success : AddNewAdStatus.error),
        ),
        isTrue,
      );
      if (!success) {
        expect(
          states
              .firstWhere((s) => s.status == AddNewAdStatus.error)
              .errorMessage,
          duplicateLicenseMessage,
        );
      }
      expect(cubit.state.status, AddNewAdStatus.loaded);
      await subscription.cancel();
      await cubit.close();
    });
  }
}
