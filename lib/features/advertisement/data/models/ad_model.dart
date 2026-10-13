import 'package:waseet/features/advertisement/data/models/rega_compliance_model.dart';
import 'package:waseet/features/advertisement/domain/entities/ad_creator_summary.dart';
import 'package:waseet/features/advertisement/domain/entities/ad_entity.dart';
import 'package:waseet/features/user/data/models/category_model.dart';
import 'package:waseet/features/user/data/models/home/cities_model.dart';
import 'package:waseet/features/user/data/models/home/neighborhood.model.dart';
import 'package:waseet/features/user/domain/entities/cities_entity.dart';

class AdModel {
  AdModel({
    this.id,
    this.createdBy,
    this.typeOfAdvertisement,
    this.typeOfAdvertisementExtra,
    this.category,
    this.city,
    this.neighborhood,
    this.latitude,
    this.longitude,
    this.landSpace,
    this.meterPrice,
    this.propertyDispute,
    this.propertyAge,
    this.facade,
    this.streetsCount,
    this.warranties,
    this.saudiCode,
    this.electricityMeter,
    this.waterMeter,
    this.negotiable,
    this.sewerage,
    this.price,
    this.paymentMethod,
    this.communicationMethod,
    this.extraInfo,
    this.contactPhone,
    this.advertiserName,
    this.advertisingLicenseNumber,
    this.images = const [],
    this.regaCompliance,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! int) {
      throw const FormatException('Advertisement id must be an integer');
    }
    // Wrong-typed nested objects degrade to null so the advertisement itself
    // survives; entries without a usable id still throw and are skipped by
    // the pagination policy (one bad ad never fails the page).
    final createdByMap = _mapOrNull(json['created_by']);
    final categoryMap = _mapOrNull(json['category']);
    final cityMap = _mapOrNull(json['city']);
    final neighborhoodMap = _mapOrNull(json['neighborhood']);
    final regaMap = _mapOrNull(json['rega_compliance']);
    return AdModel(
      id: json['id'] as int?,
      createdBy: createdByMap == null
          ? null
          : AdCreatorSummary.fromJson(createdByMap),
      typeOfAdvertisement: json['type_of_advertisement'] as String?,
      typeOfAdvertisementExtra: json['type_of_advertisement_extra'] as String?,
      category:
          categoryMap == null ? null : CategoryModel.fromMap(categoryMap),
      city: cityMap == null ? null : CitiesModel.fromJson(cityMap),
      neighborhood: neighborhoodMap == null
          ? null
          : NeighborhoodModel.fromJson(neighborhoodMap),
      latitude: num.tryParse(json['latitude'].toString())?.toDouble(),
      longitude: num.tryParse(json['longitude'].toString())?.toDouble(),
      landSpace: int.tryParse(json['land_space'].toString()),
      meterPrice: int.tryParse(json['meter_price'].toString()),
      propertyDispute: _optionalBool(json['property_dispute']),
      propertyAge: int.tryParse(json['property_age'].toString()),
      facade: json['facade'] as String?,
      streetsCount: int.tryParse(json['streets_count'].toString()),
      warranties: _optionalBool(json['warranties']),
      saudiCode: _optionalBool(json['saudi_code']),
      electricityMeter: _optionalBool(json['electricity_meter']),
      waterMeter: _optionalBool(json['water_meter']),
      negotiable: _optionalBool(json['negotiable']),
      sewerage: _optionalBool(json['sewerage']),
      price: int.tryParse(json['price'].toString()),
      paymentMethod: json['payment_method'] as String?,
      communicationMethod: json['communication_method'] as String?,
      extraInfo: json['extra_info'] as String?,
      contactPhone: json['contact_phone'] as String?,
      advertiserName: json['advertiser_name'] as String?,
      advertisingLicenseNumber:
          int.tryParse(json['advertising_license_number'].toString()),
      images: json['attechments'] is List
              ? (json['attechments'] as List<dynamic>)
                  .map((e) {
                    if (e == null) return null;
                    if (e is String) return e;
                    if (e is Map<String, dynamic>) {
                      // prefer `url` field if present
                      final url = e['url'] ?? e['file'] ?? e['path'];
                      if (url is String) return url;
                      return url?.toString();
                    }
                    return e.toString();
                  })
                  .whereType<String>()
                  .toList()
              : [],
      regaCompliance:
          regaMap == null ? null : RegaComplianceModel.fromJson(regaMap),
    );
  }
  static bool? _optionalBool(Object? value) {
    if (value is bool) return value;
    if (value == 1 || value == '1') return true;
    if (value == 0 || value == '0') return false;
    return null;
  }

  static Map<String, dynamic>? _mapOrNull(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  int? id;
  AdCreatorSummary? createdBy;
  String? typeOfAdvertisement;
  String? typeOfAdvertisementExtra;
  CategoryModel? category;
  CitiesModel? city;
  NeighborhoodModel? neighborhood;
  double? latitude;
  double? longitude;
  int? landSpace;
  int? meterPrice;
  bool? propertyDispute;
  int? propertyAge;
  String? facade;
  int? streetsCount;
  bool? warranties;
  bool? saudiCode;
  bool? electricityMeter;
  bool? waterMeter;
  bool? negotiable;
  bool? sewerage;
  int? price;
  String? paymentMethod;
  String? communicationMethod;
  String? extraInfo;
  String? contactPhone;
  String? advertiserName;
  int? advertisingLicenseNumber;
  List<String> images;
  RegaComplianceModel? regaCompliance;

  AdEntity toEntity() {
    final adCity = city;
    // A city object without an id carries no usable identity; drop it
    // instead of failing the whole advertisement conversion.
    final cityEntity = adCity == null || adCity.id == null
        ? null
        : CitiesEntity(
            id: adCity.id!,
            name: adCity.name ?? '',
            image: adCity.image ?? '',
          );
    return AdEntity(
      id: id,
      createdBy: createdBy,
      typeOfAdvertisement: typeOfAdvertisement,
      typeOfAdvertisementExtra: typeOfAdvertisementExtra,
      category: category?.toEntity(),
      city: cityEntity,
      neighborhood: neighborhood?.toEntity(),
      latitude: latitude,
      longitude: longitude,
      landSpace: landSpace,
      meterPrice: meterPrice,
      propertyDispute: propertyDispute,
      propertyAge: propertyAge,
      facade: facade,
      streetsCount: streetsCount,
      warranties: warranties,
      saudiCode: saudiCode,
      electricityMeter: electricityMeter,
      waterMeter: waterMeter,
      negotiable: negotiable,
      sewerage: sewerage,
      price: price,
      paymentMethod: paymentMethod,
      communicationMethod: communicationMethod,
      extraInfo: extraInfo,
      contactPhone: contactPhone,
      advertiserName: advertiserName,
      advertisingLicenseNumber: advertisingLicenseNumber,
      images: images,
      regaCompliance: regaCompliance,
    );
  }
}
