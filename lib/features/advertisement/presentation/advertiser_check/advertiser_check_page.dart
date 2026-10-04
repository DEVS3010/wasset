import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waseet/common_widgets/wasset_app_bar.dart';
import 'package:waseet/common_widgets/wasset_text_field.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:waseet/core/utils/image_compress.dart';

import 'package:waseet/features/advertisement/domain/entities/ad_entity.dart';
import 'package:waseet/features/advertisement/domain/entities/verify_license_entity.dart';
import 'package:waseet/features/advertisement/domain/entities/request/add_ad_request.dart';
import 'package:waseet/features/advertisement/domain/repositories/ad_repository.dart';
import 'package:waseet/res/resource.dart';
import 'package:waseet/res/res.dart';
import 'package:waseet/res/helper_method.dart';

/// A simple pre-wizard page to search an existing ad by advertiserId and license number
class AdvertiserCheckPage extends StatefulWidget {
  const AdvertiserCheckPage({super.key});

  @override
  State<AdvertiserCheckPage> createState() => _AdvertiserCheckPageState();
}

class _AdvertiserCheckPageState extends State<AdvertiserCheckPage> {
  final _formKey = GlobalKey<FormState>();
  final _advertiserController = TextEditingController();
  final _licenseController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _advertiserController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_submitting) return;
    final advertiserId = _advertiserController.text.trim();
    final license = _licenseController.text.trim();
    if (advertiserId.isEmpty || license.isEmpty) {
      HelperMethod.showSnackBar(
        context,
        'الحقول مطلوبة',
        type: SnackBarType.error,
      );
      return;
    }
    if (!RegExp(r'^\d{6,}$').hasMatch(advertiserId) ||
        !RegExp(r'^\d{6,}$').hasMatch(license)) {
      // be flexible but prefer numeric IDs
      // allow proceed but show warning
    }
    setState(() => _submitting = true);
    final repo = context.read<AdRepository>();
    // Use verification endpoint only (returns the full dataset)
    final verifyRes = await repo.verifyLicense(advertiserId, license);
    if (!mounted) return;
    if (verifyRes is ResourceSuccess<VerifyLicenseEntity?>) {
      final ver = verifyRes.data;
      setState(() => _submitting = false);
      if (ver != null) {
        Navigator.of(context).push(
          MaterialPageRoute<Widget>(
            builder: (_) => AdvertisementPreviewPage(verify: ver),
          ),
        );
        return;
      }
      HelperMethod.showSnackBar(
        context,
        'لم يتم العثور على بيانات الترخيص',
        type: SnackBarType.error,
      );
      return;
    }
    setState(() => _submitting = false);
    final message = verifyRes.message;
    log('AdvertiserCheckPage: verifyLicense error: $message');
    HelperMethod.showSnackBar(
      context,
      message ?? 'حدث خطأ',
      type: SnackBarType.error,
    );
  }

  // validation is done inline before calling API

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WassetAppBar(title: 'البحث عن الإعلان'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  WassetTextField(
                    title: 'رقم الهوية / المنشأة',
                    hintText: 'أدخل رقم الهوية / المنشأة',
                    keyboardType: TextInputType.number,
                    controller: _advertiserController,
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 12),
                  WassetTextField(
                    title: 'رقم الترخيص',
                    hintText: 'أدخل رقم الترخيص',
                    keyboardType: TextInputType.number,
                    controller: _licenseController,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submitting ? null : _search,
                child: _submitting
                    ? const CircularProgressIndicator.adaptive()
                    : const Text(
                        'التالي',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdvertisementPreviewPage extends StatefulWidget {
  const AdvertisementPreviewPage({super.key, this.ad, this.verify});

  final AdEntity? ad;
  final VerifyLicenseEntity? verify;

  @override
  State<AdvertisementPreviewPage> createState() =>
      _AdvertisementPreviewPageState();
}

class _AdvertisementPreviewPageState extends State<AdvertisementPreviewPage> {
  final _extraController = TextEditingController();
  final List<File> _attachments = [];
  bool _submitting = false;

  @override
  void dispose() {
    _extraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verify = widget.verify;
    final title = verify != null ? 'معاينة بيانات الترخيص' : 'معاينة الإعلان';
    return Scaffold(
      appBar: WassetAppBar(title: title),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionCard('بيانات الإعلان', [
                  _verticalKV(
                      'رقم رخصة الإعلان', verify?.adLicenseNumber ?? '-',),
                  _verticalKV('نوع الإعلان', verify?.advertisementType ?? '-'),
                  _verticalKV('نوع الصك', verify?.titleDeedTypeName ?? '-'),
                  _verticalKV('اسم المعلن', verify?.advertiserName ?? '-'),
                  _verticalKV('معرف المعلن', verify?.advertiserId ?? '-'),
                  _verticalKV('رقم الصك', verify?.deedNumber ?? '-'),
                  _verticalKV('مصدر الإعلان', verify?.adSource ?? '-'),
                ]),
                _sectionCard('الموقع', [
                  _verticalKV('المنطقة', verify?.location?.region ?? '-'),
                  _verticalKV('المدينة', verify?.location?.city ?? '-'),
                  _verticalKV('الحي', verify?.location?.district ?? '-'),
                  _verticalKV('الشارع', verify?.location?.street ?? '-'),
                  _verticalKV(
                      'رقم المبنى', verify?.location?.buildingNumber ?? '-',),
                  _verticalKV('وصف الموقع في الصك',
                      verify?.locationDescriptionOnMOJDeed ?? '-',),
                ]),
                _sectionCard('الحدود', [
                  _verticalKV('شمالاً', verify?.borders?.northLimitName ?? '-'),
                  _verticalKV('وصف الشمال',
                      verify?.borders?.northLimitDescription ?? '-',),
                  _verticalKV('شرقاً', verify?.borders?.eastLimitName ?? '-'),
                  _verticalKV('وصف الشرق',
                      verify?.borders?.eastLimitDescription ?? '-',),
                  _verticalKV('غرباً', verify?.borders?.westLimitName ?? '-'),
                  _verticalKV('وصف الغرب',
                      verify?.borders?.westLimitDescription ?? '-',),
                  _verticalKV('جنوباً', verify?.borders?.southLimitName ?? '-'),
                  _verticalKV('وصف الجنوب',
                      verify?.borders?.southLimitDescription ?? '-',),
                ]),
                _sectionCard('المساحة والسعر', [
                  _verticalKV(
                      'المساحة (م²)', formatNumber(verify?.propertyArea),),
                  _verticalKV(
                      'سعر العقار', formatNumber(verify?.propertyPrice),),
                  _verticalKV(
                      'إجمالي سعر الأرض', formatNumber(verify?.landTotalPrice),),
                  _verticalKV('الإيجار السنوي',
                      formatNumber(verify?.landTotalAnnualRent),),
                  _verticalKV(
                      'عدد الغرف', verify?.numberOfRooms?.toString() ?? '-',),
                ]),
                _sectionCard('الخصائص والاستخدام', [
                  _verticalKV('نوع العقار', verify?.propertyType ?? '-'),
                  _verticalKV('عمر العقار', verify?.propertyAge ?? '-'),
                  _verticalKV('واجهة العقار', verify?.propertyFace ?? '-'),
                  _verticalKV(
                      'الاستخدام الرئيسي', verify?.mainLandUseTypeName ?? '-',),
                  _verticalKV('منطقة حمراء', verify?.redZoneTypeName ?? '-'),
                  _verticalKV(
                      'المرافق', listToString(verify?.propertyUtilities),),
                ]),
                _sectionCard('الالتزامات والحالة', [
                  _verticalKV('التزامات على العقار',
                      verify?.obligationsOnTheProperty ?? '-',),
                  _verticalKV('الضمانات ومدتها',
                      verify?.guaranteesAndTheirDuration ?? '-',),
                    _verticalKV('مطابقة الكود السعودي للبناء',
                      boolToYesNo(verify?.complianceWithTheSaudiBuildingCode),),
                  _verticalKV('مقيد', boolToYesNo(verify?.isConstrained)),
                  _verticalKV('مرهون', boolToYesNo(verify?.isPawned)),
                  _verticalKV('موقف', boolToYesNo(verify?.isHalted)),
                ]),
                _sectionCard('قنوات وتفاصيل', [
                  _verticalKV('القنوات', listToString(verify?.channels)),
                  _verticalKV(
                      'أنواع الاستخدام', listToString(verify?.propertyUsages),),
                  _verticalKV('تاريخ الإنشاء', verify?.creationDate ?? '-'),
                  _verticalKV('تاريخ الانتهاء', verify?.endDate ?? '-'),
                ]),
                
                _sectionCard('جهة الاتصال', [
                  _verticalKV(
                      'اسم المسؤول', verify?.advertiserName ?? '-',),
                  _verticalKV('هاتف المسؤول',
                      verify?.phoneNumber ?? '-',),
                  _verticalKV('رقم الجوال', verify?.phoneNumber ?? '-'),
                ]),
                _sectionCard('ملاحظات ومرفقات التراخيص', [
                  _verticalKV('ملاحظات التحقق', verify?.notes ?? '-'),
                  _verticalKV('رابط رخصة الإعلان', verify?.adLicenseUrl ?? '-'),
                  _verticalKV('نوع رسم نقل الملكية',
                      verify?.ownershipTransferFeeType ?? '-',),
                ]),
                _sectionCard('المرفقات', [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إضافة مرفقات',
                          style: TextStyle(color: AppColors.secondaryTextColor),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                  final result = await FilePicker.platform.pickFiles(
                                    allowMultiple: true,
                                    type: FileType.image,
                                  );
                                  if (result == null) return;

                                  const maxBytes = 2 * 1024 * 1024;

                                  for (final f in result.files) {
                                    if (f.path == null) continue;
                                    final raw = File(f.path!);
                                    if (!await raw.exists()) continue;

                                    final originalSize = await raw.length();
                                    log('image selected: ${raw.path} originalSize: $originalSize');

                                    var toAdd = raw;
                                    if (originalSize > maxBytes) {
                                      final compressed = await compressToUnder2MB(raw);
                                      final compressedSize = await compressed.length();
                                      log('compressed: ${compressed.path} size: $compressedSize');
                                      if (compressedSize > maxBytes) {
                                        HelperMethod.showSnackBar(
                                          context,
                                          'الملف ${p.basename(raw.path)} أكبر من 2MB بعد الضغط وتم تجاهله',
                                          type: SnackBarType.error,
                                        );
                                        continue;
                                      }
                                      toAdd = compressed;
                                    }

                                    if (!mounted || !context.mounted) return;
                                    setState(() => _attachments.add(toAdd));
                                  }
                                },
                              child: const Text('اختر ملفات'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _attachments.isEmpty
                                    ? 'لا توجد ملفات'
                                    : '${_attachments.length} ملف',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._attachmentsPreview(),
                      ],
                    ),
                  ),
                ]),
                _sectionCard('معلومات إضافية', [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      controller: _extraController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: 'اكتب معلومات إضافية أو طريقة تواصل',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _submitting
                        ? null
                        : () async {
                            if (_submitting) return;
                            setState(() => _submitting = true);
                            final repo = context.read<AdRepository>();
                            final verify = widget.verify;
                            final advertiserId = verify?.advertiserId ?? '';
                            final adLicenseNumber =
                                verify?.adLicenseNumber ?? '';
                            final extra = _extraController.text.trim();
                            final res = await repo.createAdWithVerification(
                              advertiserId,
                              adLicenseNumber,
                              extra,
                              _attachments,
                            );
                            if (!mounted || !context.mounted) return;
                            setState(() => _submitting = false);
                            if (res is ResourceSuccess<AdEntity?>) {
                              HelperMethod.showSnackBar(
                                context,
                                'تم النشر بنجاح',
                                type: SnackBarType.success,
                              );
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            } else {
                              final msg = res.message;
                              HelperMethod.showSnackBar(
                                context,
                                msg ?? 'خطأ في النشر',
                                type: SnackBarType.error,
                              );
                            }
                          },
                    child: _submitting
                        ? const CircularProgressIndicator.adaptive()
                        : const Text(
                            'تأكيد ونشر الإعلان',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String formatNumber(num? n) {
    if (n == null) return '-';
    // represent without trailing .0 when integer
    final s = (n % 1 == 0) ? n.toInt().toString() : n.toString();
    return _withThousandsSeparator(s);
  }

  String _withThousandsSeparator(String s) {
    // handle decimal part if present
    if (s.contains('.')) {
      final parts = s.split('.');
      return '${_withThousandsSeparator(parts[0])}.${parts[1]}';
    }
    final buf = StringBuffer();
    var count = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) buf.write(',');
    }
    return buf.toString().split('').reversed.join();
  }

  String listToString(List<dynamic>? l) {
    if (l == null || l.isEmpty) return '-';
    final items =
        l.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
    return items.isEmpty ? '-' : items.join('، ');
  }

  String boolToYesNo(bool? v) {
    if (v == null) return '-';
    return v ? 'نعم' : 'لا';
  }

  List<Widget> _attachmentsPreview() {
    return _attachments.map((f) {
      final fileName = f.path.split(Platform.pathSeparator).last;
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                f,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  width: 64,
                  height: 64,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(fileName)),
            GestureDetector(
              onTap: () => setState(() => _attachments.remove(f)),
              child: const Icon(Icons.delete, color: AppColors.primaryColor),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// ... used helpers are below

Widget _verticalKV(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, color: AppColors.secondaryTextColor,),
        ),
        const SizedBox(height: 6),
        Text(
          value ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

Widget _sectionCard(String title, List<Widget> children) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}
