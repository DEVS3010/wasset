import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:waseet/features/advertisement/domain/entities/request/add_ad_request.dart';
import 'package:waseet/features/advertisement/domain/repositories/ad_repository.dart';
import 'package:waseet/features/user/domain/entities/category/category_entity.dart';
import 'package:waseet/features/user/domain/entities/cities_entity.dart';
import 'package:waseet/features/user/domain/entities/neighborhood_entity.dart';
import 'package:waseet/features/user/domain/repositories/home_repository.dart';
import 'package:waseet/res/api_failure.dart';
import 'package:waseet/res/resource.dart';

part 'add_new_ad_state.dart';

class AddNewAdCubit extends Cubit<AddNewAdState> {
  AddNewAdCubit({
    required HomeRepository homeRepository,
    required AdRepository adRepository,
  })  : _homeRepository = homeRepository,
        _adRepository = adRepository,
        super(const AddNewAdInitial()) {
    init();
  }

  final HomeRepository _homeRepository;
  final AdRepository _adRepository;

  Future<void> init() async {
    emit(state.copyWith(status: AddNewAdStatus.loading));
    final cities = await _homeRepository.getCities();
    final categories = await _homeRepository.getCategories();
    final neighborhoods = await _homeRepository.getNeighborhood(1);
    if (neighborhoods is ResourceSuccess) {
      emit(
        state.copyWith(
          status: AddNewAdStatus.loaded,
          cities: cities.data,
          categories: categories.data,
          neighborhoods: neighborhoods.data,
          addAdRequest: state.addAdRequest.copyWith(
            cityId: (cities.data?.isNotEmpty ?? false)
                ? cities.data?.first.id
                : null,
            categoryId: (categories.data?.isNotEmpty ?? false)
                ? categories.data?.first.id
                : null,
            neighborhoodId: (neighborhoods.data?.isNotEmpty ?? false)
                ? neighborhoods.data?.first.id
                : null,
          ),
        ),
      );
    }
    emit(
      state.copyWith(
        status: AddNewAdStatus.loaded,
        cities: cities.data,
        categories: categories.data,
        addAdRequest: state.addAdRequest.copyWith(
          cityId: (cities.data?.isNotEmpty ?? false)
                ? cities.data?.first.id
                : null,
          categoryId: (categories.data?.isNotEmpty ?? false)
                ? categories.data?.first.id
                : null,
        ),
      ),
    );
  }

  Future<void> changeCity(int cityId) async {
    // emit(state.copyWith(status: AddNewAdStatus.loading));
    final neighborhoods = await _homeRepository.getNeighborhood(cityId);
    emit(
      state.copyWith(
        status: AddNewAdStatus.loaded,
        neighborhoods: neighborhoods.data,
        addAdRequest: state.addAdRequest.copyWith(
          cityId: cityId,
          neighborhoodId: (neighborhoods.data?.isNotEmpty ?? false)
                ? neighborhoods.data?.first.id
                : null,
        ),
      ),
    );
  }

  Future<void> changeAdRequest(AddAdRequest addAdRequest) async {
    emit(state.copyWith(addAdRequest: addAdRequest));
  }

  Future<void> addNewAd() async {
    if (state.status == AddNewAdStatus.submitting) return;
    emit(state.copyWith(status: AddNewAdStatus.submitting));
    try {
      final response = await _adRepository.createAd(state.addAdRequest);
      if (response is ResourceSuccess) {
        emit(state.copyWith(status: AddNewAdStatus.success));
      } else if (response is ResourceError) {
        emit(
          state.copyWith(
            status: AddNewAdStatus.error,
            errorMessage: response.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AddNewAdStatus.error,
          errorMessage: ApiFailure.fallback,
        ),
      );
    }
    emit(state.copyWith(status: AddNewAdStatus.loaded));
  }

  void addImage(File image) {
    final images = [...state.addAdRequest.images, image];
    emit(
      state.copyWith(
        addAdRequest: state.addAdRequest.copyWith(images: images),
      ),
    );
  }

  void removeImage(int index) {
    final images = state.addAdRequest.images;
    images.removeAt(index);
    emit(
      state.copyWith(
        addAdRequest: state.addAdRequest.copyWith(images: images),
        errorMessage: DateTime.now().toIso8601String(),
      ),
    );
  }
}
