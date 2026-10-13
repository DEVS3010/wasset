import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:waseet/features/advertisement/domain/entities/ad_entity.dart';
import 'package:waseet/features/advertisement/domain/entities/advertisement_price.dart';
import 'package:waseet/res/res.dart';

const adLocationWarning =
    'نأمل مطابقة الموقع أدناه مع الموقع المذكور في وصف موقع العقار المكتوب';
const unavailableAdValue = 'غير متوفر';

class AdRegulatoryDetails extends StatelessWidget {
  const AdRegulatoryDetails({required this.ad, super.key});

  final AdEntity ad;

  static LatLng? propertyPosition(AdEntity ad) {
    // Check authoritative verified location first, then legacy advertisement coordinates
    final regaLoc = ad.regaCompliance?.location;
    final latCandidate = regaLoc?.latitude ?? ad.latitude;
    final lngCandidate = regaLoc?.longitude ?? ad.longitude;

    if (latCandidate == null ||
        lngCandidate == null ||
        !latCandidate.isFinite ||
        !lngCandidate.isFinite ||
        latCandidate.abs() > 90 ||
        lngCandidate.abs() > 180 ||
        (latCandidate == 0 && lngCandidate == 0)) {
      return null;
    }
    return LatLng(latCandidate, lngCandidate);
  }

  String _formatValue(Object? value, [String unit = '']) {
    if (value == null) return unavailableAdValue;
    if (value is List) {
      if (value.isEmpty) return unavailableAdValue;
      return value.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).join('، ');
    }
    final text = value.toString().trim();
    if (text.isEmpty) return unavailableAdValue;
    return '$text$unit';
  }

  /// Monetary display with thousands separators; non-numeric values fall
  /// back to [_formatValue]. Never alters the underlying official value.
  String _formatPrice(Object? value, String unit) {
    if (value is num) return '${formatAdPriceAmount(value)}$unit';
    return _formatValue(value, unit);
  }

  String _boolean(bool? value) => value == null
      ? unavailableAdValue
      : value
          ? 'نعم'
          : 'لا';

  Widget _section(String title, Map<String, dynamic> rows) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            for (final row in rows.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.key, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    _buildRowContent(row.value),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _buildRowContent(dynamic value) {
    if (value is List<String>) {
      if (value.isEmpty) {
        return const Text(
          unavailableAdValue,
          style: TextStyle(fontWeight: FontWeight.w500),
        );
      }
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        children: value
            .map(
              (item) => Chip(
                label: Text(
                  item,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
            .toList(),
      );
    }
    return Text(
      value?.toString() ?? unavailableAdValue,
      style: const TextStyle(fontWeight: FontWeight.w500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rega = ad.regaCompliance;
    final req = rega?.requiredFields;
    final position = propertyPosition(ad);

    // 1. License Information
    final licenseNumber = _formatValue(
      req?.adLicenseNumber ?? rega?.adLicenseNumber ?? ad.advertisingLicenseNumber,
    );
    final endDate = _formatValue(req?.endDate ?? rega?.endDate);
    final responsibleName = _formatValue(
      req?.responsibleEmployeeName ??
          (ad.advertiserName != null && req?.responsibleEmployeeName == null
              ? null
              : null),
    );
    final responsiblePhone = _formatValue(req?.responsibleEmployeePhoneNumber);
    final advertiserName = _formatValue(rega?.advertiserName ?? ad.advertiserName);
    final contactPhone = _formatValue(ad.contactPhone);

    // Verification status
    final verificationStatusText = rega?.status == 'verified'
        ? 'تم التحقق'
        : rega?.status != null
            ? _formatValue(rega?.status)
            : null;

    // 2. Property Information
    // Official property price keeps its meaning; only display grouping is
    // applied so header, cards, and regulatory rows read identically.
    final propertyPrice = req?.propertyPrice != null
        ? _formatPrice(req!.propertyPrice, ' ريال')
        : (rega?.property?.propertyPrice != null
            ? _formatPrice(rega!.property!.propertyPrice, ' ريال')
            : _formatPrice(ad.price, ' ريال'));

    // Land pricing: when the backend documents a total land price, it is the
    // main price and the accompanying property_price is the per-m² rate.
    // Totals are never computed by multiplication on the client. Zero and
    // negative totals stay "unknown" instead of rendering a misleading 0.
    final rawLandTotal = rega?.property?.landTotalPrice;
    final landTotal =
        rawLandTotal != null && rawLandTotal > 0 ? rawLandTotal : null;
    final landTotalText =
        landTotal != null ? '${formatAdPriceAmount(landTotal)} ريال' : null;
    final rawLandUnit = landTotal != null
        ? (req?.propertyPrice ?? rega?.property?.propertyPrice)
        : null;
    final landUnit =
        rawLandUnit != null && rawLandUnit > 0 ? rawLandUnit : null;
    final landUnitText =
        landUnit != null ? '${formatAdPriceAmount(landUnit)} ريال/م²' : null;

    final propertyType = _formatValue(
      req?.propertyType ?? rega?.property?.propertyType ?? ad.category?.name,
    );

    final propertyAge = req?.propertyAge != null
        ? _formatValue(
            req!.propertyAge,
            req.propertyAge is num ? ' سنة' : '',
          )
        : (rega?.property?.propertyAge != null
            ? _formatValue(
                rega!.property!.propertyAge,
                rega.property!.propertyAge is num ? ' سنة' : '',
              )
            : _formatValue(ad.propertyAge, ' سنة'));

    final propertyUsages = req?.propertyUsages;
    final numberOfRooms = _formatValue(
      req?.numberOfRooms ?? rega?.property?.numberOfRooms,
    );
    final propertyArea = req?.propertyArea != null
        ? _formatValue(req!.propertyArea, ' م²')
        : (rega?.property?.propertyArea != null
            ? _formatValue(rega!.property!.propertyArea, ' م²')
            : _formatValue(ad.landSpace, ' م²'));

    // 3. Land and Deed Information
    final planNumber = _formatValue(req?.planNumber);
    final landNumber = _formatValue(req?.landNumber);
    final guaranteesAndTheirDuration = _formatValue(req?.guaranteesAndTheirDuration);
    final obligationsOnTheProperty = _formatValue(req?.obligationsOnTheProperty);

    final rawFacade = req?.propertyFace ?? rega?.property?.propertyFace ?? ad.facade;
    final facadeMap = const {
      'north': 'شمالية',
      'south': 'جنوبية',
      'east': 'شرقية',
      'west': 'غربية',
    };
    final propertyFace = _formatValue(facadeMap[rawFacade] ?? rawFacade);

    final streetWidth = req?.streetWidth != null
        ? _formatValue(req!.streetWidth, ' م')
        : (rega?.property?.streetWidth != null
            ? _formatValue(rega!.property!.streetWidth, ' م')
            : unavailableAdValue);

    // 4. Property Services
    final propertyUtilities = req?.propertyUtilities;

    // 5. Property Location
    final region = _formatValue(req?.region ?? rega?.location?.region);
    final city = _formatValue(req?.city ?? rega?.location?.city ?? ad.city?.name);
    final district = _formatValue(req?.district ?? rega?.location?.district ?? ad.neighborhood?.name);
    final locationDescription = _formatValue(req?.locationDescriptionOnMojDeed);

    // Location warning
    final warningText = rega?.locationWarning?.trim().isNotEmpty == true
        ? rega!.locationWarning!
        : adLocationWarning;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('معلومات الترخيص', {
            'رقم ترخيص الإعلان': licenseNumber,
            'تاريخ انتهاء رخصة الإعلان': endDate,
            'اسم مسؤول الإعلان': responsibleName,
            'رقم جوال مسؤول الإعلان': responsiblePhone,
            if (verificationStatusText != null) 'حالة التحقق': verificationStatusText,
            'اسم المعلن': advertiserName,
            'رقم التواصل مع المعلن': contactPhone,
          }),
          _section('معلومات العقار', {
            'عنوان العقار': unavailableAdValue,
            'نوع العقار': propertyType,
            'سعر الوحدة': propertyPrice,
            if (landTotalText != null) 'إجمالي سعر الأرض': landTotalText,
            if (landUnitText != null) 'سعر المتر المربع': landUnitText,
            'عمر العقار': propertyAge,
            'استخدام العقار': propertyUsages ?? unavailableAdValue,
            'عدد الغرف': numberOfRooms,
            'مساحة العقار': propertyArea,
            'سعر المتر': _formatValue(ad.meterPrice, ' ريال'),
            'طريقة الدفع': ad.paymentMethod == 'cash'
                ? 'كاش'
                : ad.paymentMethod == 'financing'
                    ? 'تمويل'
                    : _formatValue(ad.paymentMethod),
          }),
          _section('معلومات الأرض والصك', {
            'رقم المخطط': planNumber,
            'رقم القطعة': landNumber,
            'الضمانات ومدتها': guaranteesAndTheirDuration,
            'الالتزامات الأخرى على العقار': obligationsOnTheProperty,
            'واجهة العقار': propertyFace,
            'عرض الشارع': streetWidth,
            'عدد الشوارع': _formatValue(ad.streetsCount),
            'وجود ضمانات': _boolean(ad.warranties),
            'وجود نزاع على العقار': _boolean(ad.propertyDispute),
            'الكود السعودي': _boolean(ad.saudiCode),
          }),
          _section('الخدمات والمرافق', {
            'خدمات العقار': propertyUtilities ?? unavailableAdValue,
            'عداد الكهرباء': _boolean(ad.electricityMeter),
            'عداد المياه': _boolean(ad.waterMeter),
            'الصرف الصحي': _boolean(ad.sewerage),
          }),
          _section('الموقع', {
            'المنطقة': region,
            'المدينة': city,
            'الحي': district,
            'وصف موقع العقار حسب الصك': locationDescription,
          }),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(warningText, style: const TextStyle(color: Colors.red)),
          ),
          if (position == null)
            const SizedBox(
              height: 80,
              child: Center(child: Text('موقع العقار غير متوفر')),
            )
          else
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: position, zoom: 15),
                  markers: {
                    Marker(
                      markerId: const MarkerId('property'),
                      position: position,
                    ),
                  },
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
