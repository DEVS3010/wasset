class RegaLocationEntity {
  const RegaLocationEntity({
    this.region,
    this.district,
    this.city,
    this.latitude,
    this.longitude,
  });

  final String? region;
  final String? district;
  final String? city;
  final double? latitude;
  final double? longitude;
}

class RegaPropertyEntity {
  const RegaPropertyEntity({
    this.propertyPrice,
    this.propertyType,
    this.propertyAge,
    this.numberOfRooms,
    this.propertyArea,
    this.propertyFace,
    this.streetWidth,
    this.landTotalPrice,
  });

  final num? propertyPrice;
  final String? propertyType;
  final dynamic propertyAge; // String or num
  final int? numberOfRooms;
  final num? propertyArea;
  final String? propertyFace;
  final num? streetWidth;
  /// Documented total price (e.g. total land price). When present alongside
  /// [propertyPrice], the latter is the per-square-meter rate — never the
  /// total. Never computed by multiplication on the client.
  final num? landTotalPrice;
}

class RegaRequiredFieldsEntity {
  const RegaRequiredFieldsEntity({
    this.adLicenseNumber,
    this.endDate,
    this.responsibleEmployeePhoneNumber,
    this.responsibleEmployeeName,
    this.propertyPrice,
    this.propertyType,
    this.planNumber,
    this.propertyAge,
    this.guaranteesAndTheirDuration,
    this.propertyUsages,
    this.landNumber,
    this.numberOfRooms,
    this.obligationsOnTheProperty,
    this.propertyArea,
    this.propertyFace,
    this.streetWidth,
    this.propertyUtilities,
    this.locationDescriptionOnMojDeed,
    this.region,
    this.district,
    this.city,
  });

  final String? adLicenseNumber;
  final String? endDate;
  final String? responsibleEmployeePhoneNumber;
  final String? responsibleEmployeeName;
  final num? propertyPrice;
  final String? propertyType;
  final String? planNumber;
  final dynamic propertyAge; // String or num
  final String? guaranteesAndTheirDuration;
  final List<String>? propertyUsages;
  final String? landNumber;
  final int? numberOfRooms;
  final String? obligationsOnTheProperty;
  final num? propertyArea;
  final String? propertyFace;
  final num? streetWidth;
  final List<String>? propertyUtilities;
  final String? locationDescriptionOnMojDeed;
  final String? region;
  final String? district;
  final String? city;
}

class RegaComplianceEntity {
  const RegaComplianceEntity({
    this.status,
    this.locationWarning,
    this.verifiedAt,
    this.expiresAt,
    this.adLicenseNumber,
    this.advertiserName,
    this.endDate,
    this.licenseUrl,
    this.property,
    this.location,
    this.requiredFields,
    this.requiredFieldStatus,
    this.authorityData,
  });

  final String? status;
  final String? locationWarning;
  final String? verifiedAt;
  final String? expiresAt;
  final String? adLicenseNumber;
  final String? advertiserName;
  final String? endDate;
  final String? licenseUrl;
  final RegaPropertyEntity? property;
  final RegaLocationEntity? location;
  final RegaRequiredFieldsEntity? requiredFields;
  final Map<String, dynamic>? requiredFieldStatus;
  final dynamic authorityData;
}
