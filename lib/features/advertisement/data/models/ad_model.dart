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
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! int) {
      throw const FormatException('Advertisement id must be an integer');
    }
    return AdModel(
      id: json['id'] as int?,
      createdBy: json['created_by'] == null
          ? null
          : AdCreatorSummary.fromJson(
              json['created_by'] as Map<String, dynamic>,
            ),
      typeOfAdvertisement: json['type_of_advertisement'] as String?,
      typeOfAdvertisementExtra: json['type_of_advertisement_extra'] as String?,
    category: json['category'] == null
      ? null
      : CategoryModel.fromMap(json['category'] as Map<String, dynamic>),
    city: json['city'] == null
      ? null
      : CitiesModel.fromJson(json['city'] as Map<String, dynamic>),
      neighborhood: json['neighborhood'] == null
          ? null
          : NeighborhoodModel.fromJson(
              json['neighborhood'] as Map<String, dynamic>,
            ),
      latitude: num.tryParse(json['latitude'].toString())?.toDouble(),
      longitude: num.tryParse(json['longitude'].toString())?.toDouble(),
      landSpace: int.tryParse(json['land_space'].toString()),
      meterPrice: int.tryParse(json['meter_price'].toString()),
      propertyDispute:
          int.tryParse(json['property_dispute'].toString()) == 1 ? true : false,
      propertyAge: int.tryParse(json['property_age'].toString()),
      facade: json['facade'] as String?,
      streetsCount: int.tryParse(json['streets_count'].toString()),
      warranties:
          int.tryParse(json['warranties'].toString()) == 1 ? true : false,
      saudiCode:
          int.tryParse(json['saudi_code'].toString()) == 1 ? true : false,
      electricityMeter: int.tryParse(json['electricity_meter'].toString()) == 1
          ? true
          : false,
      waterMeter:
          int.tryParse(json['water_meter'].toString()) == 1 ? true : false,
      negotiable:
          int.tryParse(json['negotiable'].toString()) == 1 ? true : false,
      sewerage: int.tryParse(json['sewerage'].toString()) == 1 ? true : false,
      price: int.tryParse(json['price'].toString()),
      paymentMethod: json['payment_method'] as String?,
      communicationMethod: json['communication_method'] as String?,
      extraInfo: json['extra_info'] as String?,
      contactPhone: json['contact_phone'] as String?,
      advertiserName: json['advertiser_name'] as String?,
      advertisingLicenseNumber:
          int.tryParse(json['advertising_license_number'].toString()),
      images: (json['attechments'] as List<dynamic>?)?.map((e) {
            if (e == null) return null;
            if (e is String) return e;
            if (e is Map<String, dynamic>) {
              // prefer `url` field if present
              final url = e['url'] ?? e['file'] ?? e['path'];
              if (url is String) return url;
              return url?.toString();
            }
            return e.toString();
          }).whereType<String>().toList() ?? [],
    );
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

  AdEntity toEntity() {
    final adCity = city;
    return AdEntity(
      id: id,
      createdBy: createdBy,
      typeOfAdvertisement: typeOfAdvertisement,
      typeOfAdvertisementExtra: typeOfAdvertisementExtra,
      category: category?.toEntity(),
      city: adCity == null
          ? null
          : CitiesEntity(
              id: adCity.id ??
                  (throw const FormatException('City id is required')),
              name: adCity.name ?? '',
              image: adCity.image ?? '',
            ),
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
    );
  }
}
