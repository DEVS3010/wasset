import 'package:waseet/features/advertisement/domain/entities/ad_entity.dart';

/// Where the resolved main advertisement price comes from.
enum AdPriceSource {
  /// Legacy root-level `price` — always wins when valid.
  rootPrice,

  /// Documented `rega_compliance.property.land_total_price`.
  regaLandTotal,

  /// `required_fields.property_price` (fallback: `property.property_price`).
  regaPropertyPrice,

  /// No usable price in any supported field.
  none,
}

/// Resolved, clearly labeled pricing for one advertisement.
///
/// Business rules (see [AdvertisementPriceResolver]):
/// - A valid legacy root `price` is never overridden.
/// - A documented land total is the main price; the accompanying
///   `property_price` is then the per-square-meter rate, never the total.
/// - Rental amounts never gain an invented billing period.
/// - Null, zero, negative, and non-finite amounts are "unknown", never zero.
class AdvertisementPrice {
  const AdvertisementPrice({
    required this.total,
    required this.unitPerMeter,
    required this.source,
    required this.isRental,
  });

  /// Main display amount in Saudi Riyal, or null when unknown.
  final num? total;

  /// Per-square-meter rate, only set when a separate documented total
  /// exists (land advertisements). Null otherwise — never inferred.
  final num? unitPerMeter;

  final AdPriceSource source;

  /// True when `type_of_advertisement` is `rent`. The billing period is
  /// unknown unless a dedicated API field confirms it, so no period suffix
  /// is ever attached by the resolver.
  final bool isRental;

  bool get hasTotal => total != null;
}

/// Single source of truth for advertisement price display.
///
/// Precedence: valid root `price` → documented `land_total_price` (with
/// `property_price` as the per-m² rate) → regulatory `property_price` →
/// unknown. No multiplication, no category-name matching, no `extra_info`
/// parsing, no null-to-zero conversion.
class AdvertisementPriceResolver {
  const AdvertisementPriceResolver._();

  static AdvertisementPrice resolve(AdEntity ad) {
    final root = _validAmount(ad.price);
    final requiredFields = ad.regaCompliance?.requiredFields;
    final property = ad.regaCompliance?.property;
    final landTotal = _validAmount(property?.landTotalPrice);
    final officialUnit = _validAmount(requiredFields?.propertyPrice) ??
        _validAmount(property?.propertyPrice);
    final isRental = ad.typeOfAdvertisement == 'rent';

    if (root != null) {
      return AdvertisementPrice(
        total: root,
        unitPerMeter: null,
        source: AdPriceSource.rootPrice,
        isRental: isRental,
      );
    }
    if (landTotal != null) {
      return AdvertisementPrice(
        total: landTotal,
        unitPerMeter: officialUnit,
        source: AdPriceSource.regaLandTotal,
        isRental: isRental,
      );
    }
    if (officialUnit != null) {
      return AdvertisementPrice(
        total: officialUnit,
        unitPerMeter: null,
        source: AdPriceSource.regaPropertyPrice,
        isRental: isRental,
      );
    }
    return AdvertisementPrice(
      total: null,
      unitPerMeter: null,
      source: AdPriceSource.none,
      isRental: isRental,
    );
  }

  /// A monetary amount is usable only when it is a finite positive number.
  /// Zero and negatives are business-invalid as selling prices and stay
  /// "unknown" instead of rendering as `0` or a misleading amount.
  static num? _validAmount(num? value) {
    if (value == null) return null;
    final asDouble = value.toDouble();
    if (!asDouble.isFinite || asDouble <= 0) return null;
    return value;
  }
}

/// Formats a monetary amount with thousands separators while preserving
/// meaningful decimals (`450000` → `450,000`; `2000007.62` → `2,000,007.62`;
/// `3584.5` → `3,584.5`). Pure Dart; RTL-safe plain digits.
String formatAdPriceAmount(num value) {
  final negative = value < 0;
  var text = value.abs().toString();
  if (text.contains('e') || text.contains('E')) {
    text = value.abs().toStringAsFixed(2);
  }
  final parts = text.split('.');
  final grouped = _groupThousands(parts[0]);
  var result = grouped;
  if (parts.length > 1) {
    final fraction = parts[1].replaceAll(RegExp(r'0+$'), '');
    if (fraction.isNotEmpty) result = '$grouped.$fraction';
  }
  return negative ? '-$result' : result;
}

String _groupThousands(String digits) {
  final buffer = StringBuffer();
  var count = 0;
  for (var i = digits.length - 1; i >= 0; i--) {
    buffer.write(digits[i]);
    count++;
    if (count % 3 == 0 && i != 0) buffer.write(',');
  }
  return buffer.toString().split('').reversed.join();
}
