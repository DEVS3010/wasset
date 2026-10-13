import 'package:waseet/features/advertisement/domain/entities/verify_license_entity.dart';

class VerifyLocationModel extends VerifyLocationEntity {
  VerifyLocationModel({
    super.region,
    super.regionCode,
    super.city,
    super.cityCode,
    super.district,
    super.districtCode,
    super.street,
    super.postalCode,
    super.buildingNumber,
    super.additionalNumber,
    super.longitude,
    super.latitude,
    super.districtId,
    super.cityId,
    super.regionId,
  });

  factory VerifyLocationModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return VerifyLocationModel();
    return VerifyLocationModel(
      region: _string(map['region']),
      regionCode: _string(map['regionCode']),
      city: _string(map['city']),
      cityCode: _string(map['cityCode']),
      district: _string(map['district']),
      districtCode: _string(map['districtCode']),
      street: _string(map['street']),
      postalCode: _string(map['postalCode']),
      buildingNumber: _string(map['buildingNumber']),
      additionalNumber: _string(map['additionalNumber']),
      longitude: _string(map['longitude']),
      latitude: _string(map['latitude']),
      districtId: _string(map['districtId']),
      cityId: _string(map['cityId']),
      regionId: _string(map['regionId']),
    );
  }
}

class VerifyBordersModel extends VerifyBordersEntity {
  VerifyBordersModel({
    super.northLimitName,
    super.northLimitDescription,
    super.northLimitLengthChar,
    super.eastLimitName,
    super.eastLimitDescription,
    super.eastLimitLengthChar,
    super.westLimitName,
    super.westLimitDescription,
    super.westLimitLengthChar,
    super.southLimitName,
    super.southLimitDescription,
    super.southLimitLengthChar,
  });

  factory VerifyBordersModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return VerifyBordersModel();
    return VerifyBordersModel(
      northLimitName: _string(map['northLimitName']),
      northLimitDescription: _string(map['northLimitDescription']),
      northLimitLengthChar: _string(map['northLimitLengthChar']),
      eastLimitName: _string(map['eastLimitName']),
      eastLimitDescription: _string(map['eastLimitDescription']),
      eastLimitLengthChar: _string(map['eastLimitLengthChar']),
      westLimitName: _string(map['westLimitName']),
      westLimitDescription: _string(map['westLimitDescription']),
      westLimitLengthChar: _string(map['westLimitLengthChar']),
      southLimitName: _string(map['southLimitName']),
      southLimitDescription: _string(map['southLimitDescription']),
      southLimitLengthChar: _string(map['southLimitLengthChar']),
    );
  }
}

class VerifyLicenseModel extends VerifyLicenseEntity {
  VerifyLicenseModel({
    super.advertiserId,
    super.adLicenseNumber,
    super.deedNumber,
    super.advertiserName,
    super.responsibleEmployeeName,
    super.responsibleEmployeePhoneNumber,
    super.phoneNumber,
    super.brokerageAndMarketingLicenseNumber,
    super.isConstrained,
    super.isPawned,
    super.isHalted,
    super.isTestment,
    super.rerConstraints,
    super.streetWidth,
    super.propertyArea,
    super.propertyPrice,
    super.landTotalPrice,
    super.landTotalAnnualRent,
    super.numberOfRooms,
    super.propertyType,
    super.propertyAge,
    super.advertisementType,
    super.location,
    super.propertyFace,
    super.planNumber,
    super.landNumber,
    super.obligationsOnTheProperty,
    super.guaranteesAndTheirDuration,
    super.complianceWithTheSaudiBuildingCode,
    super.channels,
    super.propertyUsages,
    super.mainLandUseTypeName,
    super.redZoneTypeName,
    super.propertyUtilities,
    super.creationDate,
    super.endDate,
    super.adLicenseUrl,
    super.adSource,
    super.titleDeedTypeName,
    super.locationDescriptionOnMOJDeed,
    super.notes,
    super.borders,
    super.rerBorders,
    super.ownershipTransferFeeType,
  });

  factory VerifyLicenseModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return VerifyLicenseModel();
    // The Wasset envelope wraps payloads in `data`, while NHC payloads may
    // nest the advertisement under `result.advertisement`. Unwrap both so the
    // Wasset wrapper is never confused with the NHC advertisement object.
    final payload = _advertisementPayload(map);
    return VerifyLicenseModel(
      advertiserId: _string(payload['advertiserId']),
      adLicenseNumber: _string(payload['adLicenseNumber']),
      deedNumber: _string(payload['deedNumber']),
      advertiserName: _string(payload['advertiserName']),
      responsibleEmployeeName: _string(payload['responsibleEmployeeName']),
      responsibleEmployeePhoneNumber:
          _string(payload['responsibleEmployeePhoneNumber']),
      phoneNumber: _string(payload['phoneNumber']),
      brokerageAndMarketingLicenseNumber:
          _string(payload['brokerageAndMarketingLicenseNumber']),
      isConstrained: payload['isConstrained'] as bool?,
      isPawned: payload['isPawned'] as bool?,
      isHalted: payload['isHalted'] as bool?,
      isTestment: payload['isTestment'] as bool?,
      rerConstraints: payload['rerConstraints'],
      streetWidth: _num(payload['streetWidth']),
      propertyArea: _num(payload['propertyArea']),
      propertyPrice: _num(payload['propertyPrice']),
      landTotalPrice: _num(payload['landTotalPrice']),
      landTotalAnnualRent: _num(payload['landTotalAnnualRent']),
      numberOfRooms: _int(payload['numberOfRooms']),
      propertyType: _string(payload['propertyType']),
      propertyAge: _string(payload['propertyAge']),
      advertisementType: _string(payload['advertisementType']),
      location:
          VerifyLocationModel.fromMap(_map(payload['location'])),
      propertyFace: _string(payload['propertyFace']),
      planNumber: _string(payload['planNumber']),
      landNumber: _string(payload['landNumber']),
      obligationsOnTheProperty: _string(payload['obligationsOnTheProperty']),
      guaranteesAndTheirDuration:
          _string(payload['guaranteesAndTheirDuration']),
      complianceWithTheSaudiBuildingCode:
          payload['complianceWithTheSaudiBuildingCode'] as bool?,
      channels: _stringList(payload['channels']),
      propertyUsages: payload['propertyUsages'] is List
          ? payload['propertyUsages'] as List<dynamic>
          : null,
      mainLandUseTypeName: _string(payload['mainLandUseTypeName']),
      redZoneTypeName: _string(payload['redZoneTypeName']),
      propertyUtilities: _stringList(payload['propertyUtilities']),
      creationDate: _string(payload['creationDate']),
      endDate: _string(payload['endDate']),
      adLicenseUrl: _string(payload['adLicenseUrl']),
      adSource: _string(payload['adSource']),
      titleDeedTypeName: _string(payload['titleDeedTypeName']),
      locationDescriptionOnMOJDeed:
          _string(payload['locationDescriptionOnMOJDeed']),
      notes: _string(payload['notes']),
      borders: VerifyBordersModel.fromMap(_map(payload['borders'])),
      rerBorders: payload['rerBorders'] is List
          ? payload['rerBorders'] as List<dynamic>
          : null,
      ownershipTransferFeeType: _string(payload['ownershipTransferFeeType']),
    );
  }

  static Map<String, dynamic> _advertisementPayload(Map<String, dynamic> map) {
    if (map.containsKey('adLicenseNumber') ||
        map.containsKey('advertiserId')) {
      return map;
    }
    final advertisement = _map(map['advertisement']);
    if (advertisement != null) return _advertisementPayload(advertisement);
    final result = _map(map['result']);
    if (result != null) return _advertisementPayload(result);
    final data = _map(map['data']);
    if (data != null) return _advertisementPayload(data);
    return map;
  }
}

String? _string(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

num? _num(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim());
  return null;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

List<String> _stringList(Object? value) {
  if (value is! List) return [];
  return value
      .map((e) => e?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
}

Map<String, dynamic>? _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
