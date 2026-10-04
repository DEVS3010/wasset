import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:waseet/features/advertisement/domain/entities/ad_entity.dart';
import 'package:waseet/features/advertisement/domain/repositories/ad_repository.dart';
import 'package:waseet/features/brokers/domain/entities/request/get_ads_param.dart';
import 'package:waseet/features/user/domain/entities/category/category_entity.dart';
import 'package:waseet/features/user/domain/entities/cities_entity.dart';
import 'package:waseet/features/user/domain/entities/neighborhood_entity.dart';
import 'package:waseet/features/user/domain/entities/request/complaint_request.dart';
import 'package:waseet/features/user/domain/repositories/complaints_repository.dart';
import 'package:waseet/features/user/domain/repositories/home_repository.dart';
import 'package:waseet/res/enums/complaint_type.dart';
import 'package:waseet/res/resource.dart';

part 'advertisements_state.dart';

class AdvertisementsCubit extends Cubit<AdvertisementsState> {
  AdvertisementsCubit({
    required AdRepository adRepository,
    required HomeRepository homeRepository,
    required ComplaintRepository complaintRepository,
  })  : _adRepository = adRepository,
        _homeRepository = homeRepository,
        _complaintRepository = complaintRepository,
        super(const AdvertisementsState()) {
    init();
  }
  final ComplaintRepository _complaintRepository;
  final AdRepository _adRepository;
  final HomeRepository _homeRepository;
  List<AdEntity>? adsList;
  List<AdEntity>? favAdsList;
  List<bool>? isSelect;
  List<CategoryEntity>? categoriesList;

  /// A description for yourCustomFunction
  FutureOr<void> init() async {
    try {
      emit(state.copyWith(status: AdvertisementsStatus.loading));
      final cities = await _homeRepository.getCities(pageSize: 100);
      final ads = await _adRepository.getAds(GetAdsParam());
      final favAds = await _adRepository.getFavAds();
      final categories = await _homeRepository.getCategories();

      if (ads is ResourceSuccess &&
          categories is ResourceSuccess &&
          cities is ResourceSuccess &&
          favAds is ResourceSuccess) {
        categoriesList = categories.data;
        isSelect = List.generate(categories.data!.length, (index) => false);
        adsList = ads.data;
        favAdsList = favAds.data;

        favAdsList?.forEach((ad) {
          ad.isFav = true;
        });

        for (final ad in adsList!) {
          for (final favAd in favAdsList!) {
            if (ad.id == favAd.id) {
              ad.isFav = true;
              break;
            }
          }
        }
        emit(
          state.copyWith(
            isSelect: isSelect,
            status: AdvertisementsStatus.loaded,
            ads: ads.data,
            favds: favAdsList,
            categories: categories.data,
            cities: cities.data,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AdvertisementsStatus.error,
            errorMessage: ads.message ?? 'error',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AdvertisementsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> setCity(int city) async {
    try {
      final response = await _homeRepository.getNeighborhood(
        city,
      );
      if (response is ResourceSuccess) {
        final neighborhoods = response.data;
        emit(
          state.copyWith(
            status: AdvertisementsStatus.loaded,
            neighborhoods: neighborhoods,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AdvertisementsStatus.error,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AdvertisementsStatus.error,
        ),
      );
    }
    emit(
      state.copyWith(
        city: city,
      ),
    );
  }

  Future<void> setAdType(String adType) async {
    emit(
      state.copyWith(
        adType: adType,
      ),
    );
  }

  Future<void> setPropertyType(int propertyType) async {
    emit(
      state.copyWith(
        propertyType: propertyType,
      ),
    );
  }

  Future<void> setNeighborhood(String neighborhood) async {
    emit(
      state.copyWith(
        neighborhood: neighborhood,
      ),
    );
  }

  Future<void> setPropertyAge(int propertyAge) async {
    emit(
      state.copyWith(
        propertyAge: propertyAge,
      ),
    );
  }

  Future<void> setPayMethod(String payMethod) async {
    emit(
      state.copyWith(
        payMethod: payMethod,
      ),
    );
  }

  void adsUnfiltering() {
    emit(
      state.copyWith(
        ads: adsList,
      ),
    );
  }

  void filteringByCategories(int index) {
    emit(
      state.copyWith(
        status: AdvertisementsStatus.loading,
      ),
    );
    isSelect![index] = !isSelect![index];
    final categoryFiltringResult = <CategoryEntity>[];
    for (var i = 0; i < categoriesList!.length; i++) {
      if (isSelect![i] == true) {
        categoryFiltringResult.add(categoriesList![i]);
      }
    }
    final ads = <AdEntity>[];
    if (categoryFiltringResult.isEmpty) {
      ads.addAll(adsList!);
    } else {
      adsList?.forEach((element) {
        if (categoryFiltringResult.contains(element.category)) {
          ads.add(element);
        }
      });
    }
    emit(
      state.copyWith(
        status: AdvertisementsStatus.loaded,
        ads: ads,
        isSelect: isSelect,
      ),
    );
  }

  void adsFiltering() {
    var adsFilteringResult = adsList;

    if (state.adType != null) {
      adsFilteringResult = adsFilteringResult!.where((ad) {
        return ad.typeOfAdvertisement == state.adType;
      }).toList();
    }
    if (state.propertyType != null) {
      adsFilteringResult = adsFilteringResult!.where((ad) {
        return ad.category?.id == state.propertyType;
      }).toList();
    }
    if (state.neighborhood != null) {
      adsFilteringResult = adsFilteringResult!.where((ad) {
        return ad.neighborhood?.name == state.neighborhood;
      }).toList();
    }
    if (state.city != null) {
      adsFilteringResult = adsFilteringResult!.where((ad) {
        return ad.city?.id == state.city;
      }).toList();
    }
    if (state.propertyAge != null) {
      adsFilteringResult = adsFilteringResult!.where((ad) {
        return ad.propertyAge == state.propertyAge;
      }).toList();
    }
    if (state.payMethod != null) {
      adsFilteringResult = adsFilteringResult!.where((ad) {
        return ad.paymentMethod == state.payMethod;
      }).toList();
    }
    isSelect = List.generate(isSelect!.length, (index) => false);
    emit(
      state.copyWith(
        ads: adsFilteringResult,
        status: AdvertisementsStatus.loaded,
        isSelect: isSelect,
      ),
    );
  }

  Future<void> addFavAd(int adId) async {
    try {
      emit(
        state.copyWith(
          status: AdvertisementsStatus.addLoading,
        ),
      );
      final response = await _adRepository.addFavAd(adId);
      if (response is ResourceSuccess) {
        for (final ad in adsList!) {
          if (ad.id == adId) {
            ad.isFav = true;
            favAdsList!.add(ad);
          }
        }
        emit(
          state.copyWith(
            status: AdvertisementsStatus.addAndRemoveSuccess,
            addAndRemoveMessage: response.message,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AdvertisementsStatus.addAndRemoveError,
            errorMessage: response.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AdvertisementsStatus.addAndRemoveError,
          errorMessage: e.toString(),
        ),
      );
    }
    emit(
      state.copyWith(
        status: AdvertisementsStatus.loaded,
      ),
    );
  }

  Future<void> removeFavAd(int adId) async {
    try {
      emit(
        state.copyWith(
          status: AdvertisementsStatus.removeLoading,
        ),
      );
      final removeMessage = await _adRepository.removeFavAd(adId);
      if (removeMessage is ResourceSuccess) {
        favAdsList!.removeWhere((ad) => ad.id == adId);
        for (final ad in adsList!) {
          if (ad.id == adId) {
            ad.isFav = false;
          }
        }

        emit(
          state.copyWith(
            status: AdvertisementsStatus.addAndRemoveSuccess,
            addAndRemoveMessage: removeMessage.message,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AdvertisementsStatus.addAndRemoveError,
            errorMessage: removeMessage.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AdvertisementsStatus.addAndRemoveError,
          errorMessage: e.toString(),
        ),
      );
    }
    emit(
      state.copyWith(
        status: AdvertisementsStatus.loaded,
        errorMessage: '',
      ),
    );
  }

  void setDescription(String description) {
    emit(state.copyWith(description: description));
  }

  Future<void> createComplaint({
    required int adId,
  }) async {
    try {
      emit(state.copyWith(status: AdvertisementsStatus.processLoading));
      final response = await _complaintRepository.createComplaint(
        ComplaintRequest(
          description: state.description ?? '',
          type: ComplaintType.advertisement.name,
          advertisementId: adId,
        ),
      );
      if (response is ResourceSuccess) {
        emit(
          state.copyWith(
            status: AdvertisementsStatus.processSuccess,
            processMessage: response.data,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AdvertisementsStatus.processFailure,
            processMessage: response.message ?? 'حدث خطأ ما',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AdvertisementsStatus.processFailure,
          processMessage: 'حدث خطأ ما',
          //e.toString(),
        ),
      );
    }
    emit(
      state.copyWith(
        status: AdvertisementsStatus.loaded,
        processMessage: '',
      ),
    );
  }

  void setSearchKey(String name) {
    emit(state.copyWith(name: name));
  }

  void searchByName() {
    var adSearchResult = adsList;
    if (state.name != null) {
      adSearchResult = adSearchResult?.where((ad) {
        return ad.city?.name.contains(state.name ?? '') ?? false;
      }).toList();
    }
    emit(
      state.copyWith(
        ads: adSearchResult,
        status: AdvertisementsStatus.loaded,
      ),
    );
  }
}
