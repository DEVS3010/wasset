import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:waseet/res/api_failure.dart';
import 'package:waseet/res/resource.dart';

/// A license field error alone is insufficient evidence of a duplicate.
ResourceError<T> adFailure<T>(Object? error) {
  final failure = error is ApiFailure ? error : ApiFailure.fromBody(error);
  if (kDebugMode) {
    log(
      'Advertisement request failed: type=${error.runtimeType}, '
      'status=${failure.statusCode}',
      name: 'Advertisement',
    );
  }
  final fields = failure.errors;
  final licenseError =
      fields?['adLicenseNumber'] ?? fields?['advertising_license_number'];
  final text = ApiFailure.usefulMessage(licenseError) ?? failure.message;
  final lower = text.toLowerCase();
  final mentionsLicense = licenseError != null ||
      lower.contains('license') ||
      lower.contains('رخصة') ||
      lower.contains('الرخصة') ||
      lower.contains('ترخيص');
  final duplicate = mentionsLicense &&
      (lower.contains('already used') ||
          lower.contains('already been used') ||
          lower.contains('already in use') ||
          lower.contains('already taken') ||
          lower.contains('already been taken') ||
          lower.contains('already associated') ||
          lower.contains('already linked') ||
          lower.contains('duplicate') ||
          lower.contains('مستخدمة بالفعل') ||
          lower.contains('مستخدم بالفعل') ||
          lower.contains('مرتبطة بإعلان') ||
          lower.contains('مستخدمة مسبقاً'));
  return ResourceError<T>(
    duplicate ? duplicateLicenseMessage : text,
    null,
    failure.errors,
  );
}

const duplicateLicenseMessage = 'هذه الرخصة مرتبطة بإعلان موجود بالفعل.';
