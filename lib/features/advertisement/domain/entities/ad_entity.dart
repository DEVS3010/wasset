// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:waseet/features/advertisement/domain/entities/ad_creator_summary.dart';
import 'package:waseet/features/user/domain/entities/category/category_entity.dart';
import 'package:waseet/features/user/domain/entities/cities_entity.dart';
import 'package:waseet/features/user/domain/entities/neighborhood_entity.dart';

import 'package:waseet/features/advertisement/domain/entities/rega_compliance_entity.dart';

class AdEntity {
  int? id;
  AdCreatorSummary? createdBy;
  String? typeOfAdvertisement;
  String? typeOfAdvertisementExtra;
  CategoryEntity? category;
  CitiesEntity? city;
  NeighborhoodEntity? neighborhood;
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
  List<String>? images;
  bool isFav;
  RegaComplianceEntity? regaCompliance;
  AdEntity({
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
    this.images,
    this.isFav = false,
    this.regaCompliance,
  });
}

