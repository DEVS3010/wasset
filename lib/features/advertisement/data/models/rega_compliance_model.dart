import 'package:waseet/features/advertisement/domain/entities/rega_compliance_entity.dart';

class RegaLocationModel extends RegaLocationEntity {
  const RegaLocationModel({
    super.region,
    super.district,
    super.city,
    super.latitude,
    super.longitude,
  });

  factory RegaLocationModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RegaLocationModel();
    return RegaLocationModel(
      region: _stringOrNull(json['region']),
      district: _stringOrNull(json['district']),
      city: _stringOrNull(json['city']),
      latitude: _numOrNull(json['latitude'])?.toDouble(),
      longitude: _numOrNull(json['longitude'])?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'region': region,
        'district': district,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class RegaPropertyModel extends RegaPropertyEntity {
  const RegaPropertyModel({
    super.propertyPrice,
    super.propertyType,
    super.propertyAge,
    super.numberOfRooms,
    super.propertyArea,
    super.propertyFace,
    super.streetWidth,
    super.landTotalPrice,
  });

  factory RegaPropertyModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RegaPropertyModel();
    return RegaPropertyModel(
      propertyPrice: _numOrNull(json['property_price']),
      propertyType: _stringOrNull(json['property_type']),
      propertyAge: json['property_age'],
      numberOfRooms: _intOrNull(json['number_of_rooms']),
      propertyArea: _numOrNull(json['property_area']),
      propertyFace: _stringOrNull(json['property_face']),
      streetWidth: _numOrNull(json['street_width']),
      landTotalPrice: _numOrNull(json['land_total_price']),
    );
  }

  Map<String, dynamic> toJson() => {
        'property_price': propertyPrice,
        'property_type': propertyType,
        'property_age': propertyAge,
        'number_of_rooms': numberOfRooms,
        'property_area': propertyArea,
        'property_face': propertyFace,
        'street_width': streetWidth,
        'land_total_price': landTotalPrice,
      };
}

class RegaRequiredFieldsModel extends RegaRequiredFieldsEntity {
  const RegaRequiredFieldsModel({
    super.adLicenseNumber,
    super.endDate,
    super.responsibleEmployeePhoneNumber,
    super.responsibleEmployeeName,
    super.propertyPrice,
    super.propertyType,
    super.planNumber,
    super.propertyAge,
    super.guaranteesAndTheirDuration,
    super.propertyUsages,
    super.landNumber,
    super.numberOfRooms,
    super.obligationsOnTheProperty,
    super.propertyArea,
    super.propertyFace,
    super.streetWidth,
    super.propertyUtilities,
    super.locationDescriptionOnMojDeed,
    super.region,
    super.district,
    super.city,
  });

  factory RegaRequiredFieldsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RegaRequiredFieldsModel();
    return RegaRequiredFieldsModel(
      adLicenseNumber: _stringOrNull(json['ad_license_number']),
      endDate: _stringOrNull(json['end_date']),
      responsibleEmployeePhoneNumber:
          _stringOrNull(json['responsible_employee_phone_number']),
      responsibleEmployeeName:
          _stringOrNull(json['responsible_employee_name']),
      propertyPrice: _numOrNull(json['property_price']),
      propertyType: _stringOrNull(json['property_type']),
      planNumber: _stringOrNull(json['plan_number']),
      propertyAge: json['property_age'],
      guaranteesAndTheirDuration:
          _stringOrNull(json['guarantees_and_their_duration']),
      propertyUsages: _stringListOrNull(json['property_usages']),
      landNumber: _stringOrNull(json['land_number']),
      numberOfRooms: _intOrNull(json['number_of_rooms']),
      obligationsOnTheProperty:
          _stringOrNull(json['obligations_on_the_property']),
      propertyArea: _numOrNull(json['property_area']),
      propertyFace: _stringOrNull(json['property_face']),
      streetWidth: _numOrNull(json['street_width']),
      propertyUtilities: _stringListOrNull(json['property_utilities']),
      locationDescriptionOnMojDeed:
          _stringOrNull(json['location_description_on_moj_deed']),
      region: _stringOrNull(json['region']),
      district: _stringOrNull(json['district']),
      city: _stringOrNull(json['city']),
    );
  }

  Map<String, dynamic> toJson() => {
        'ad_license_number': adLicenseNumber,
        'end_date': endDate,
        'responsible_employee_phone_number': responsibleEmployeePhoneNumber,
        'responsible_employee_name': responsibleEmployeeName,
        'property_price': propertyPrice,
        'property_type': propertyType,
        'plan_number': planNumber,
        'property_age': propertyAge,
        'guarantees_and_their_duration': guaranteesAndTheirDuration,
        'property_usages': propertyUsages,
        'land_number': landNumber,
        'number_of_rooms': numberOfRooms,
        'obligations_on_the_property': obligationsOnTheProperty,
        'property_area': propertyArea,
        'property_face': propertyFace,
        'street_width': streetWidth,
        'property_utilities': propertyUtilities,
        'location_description_on_moj_deed': locationDescriptionOnMojDeed,
        'region': region,
        'district': district,
        'city': city,
      };
}

class RegaComplianceModel extends RegaComplianceEntity {
  const RegaComplianceModel({
    super.status,
    super.locationWarning,
    super.verifiedAt,
    super.expiresAt,
    super.adLicenseNumber,
    super.advertiserName,
    super.endDate,
    super.licenseUrl,
    RegaPropertyModel? super.property,
    RegaLocationModel? super.location,
    RegaRequiredFieldsModel? super.requiredFields,
    super.requiredFieldStatus,
    super.authorityData,
  });

  factory RegaComplianceModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RegaComplianceModel();
    final propertyMap = _mapOrNull(json['property']);
    final locationMap = _mapOrNull(json['location']);
    final requiredFieldsMap = _mapOrNull(json['required_fields']);
    final fieldStatusMap = _mapOrNull(json['required_field_status']);

    return RegaComplianceModel(
      status: _stringOrNull(json['status']),
      locationWarning: _stringOrNull(json['location_warning']),
      verifiedAt: _stringOrNull(json['verified_at']),
      expiresAt: _stringOrNull(json['expires_at']),
      adLicenseNumber: _stringOrNull(json['ad_license_number']),
      advertiserName: _stringOrNull(json['advertiser_name']),
      endDate: _stringOrNull(json['end_date']),
      licenseUrl: _stringOrNull(json['license_url']),
      property:
          propertyMap == null ? null : RegaPropertyModel.fromJson(propertyMap),
      location:
          locationMap == null ? null : RegaLocationModel.fromJson(locationMap),
      requiredFields: requiredFieldsMap == null
          ? null
          : RegaRequiredFieldsModel.fromJson(requiredFieldsMap),
      requiredFieldStatus: fieldStatusMap,
      authorityData: json['authority_data'],
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'location_warning': locationWarning,
        'verified_at': verifiedAt,
        'expires_at': expiresAt,
        'ad_license_number': adLicenseNumber,
        'advertiser_name': advertiserName,
        'end_date': endDate,
        'license_url': licenseUrl,
        'property': property is RegaPropertyModel
            ? (property! as RegaPropertyModel).toJson()
            : null,
        'location': location is RegaLocationModel
            ? (location! as RegaLocationModel).toJson()
            : null,
        'required_fields': requiredFields is RegaRequiredFieldsModel
            ? (requiredFields! as RegaRequiredFieldsModel).toJson()
            : null,
        'required_field_status': requiredFieldStatus,
        'authority_data': authorityData,
      };
}

String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}

num? _numOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString().trim());
}

int? _intOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

List<String>? _stringListOrNull(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value
        .map((e) => e?.toString().trim())
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return null;
}

Map<String, dynamic>? _mapOrNull(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
