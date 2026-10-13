import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:waseet/common_widgets/broker_item_icon.dart';
import 'package:waseet/common_widgets/images_banner.dart';
import 'package:waseet/features/advertisement/domain/entities/ad_entity.dart';
import 'package:waseet/features/advertisement/domain/entities/advertisement_price.dart';
import 'package:waseet/features/advertisement/presentation/ad_details/cubit/cubit.dart';
import 'package:waseet/features/advertisement/presentation/ad_details/widgets/ad_regulatory_details.dart';
import 'package:waseet/res/assets/assets.gen.dart';
import 'package:waseet/res/helper_method.dart';
import 'package:waseet/res/res.dart';
import 'package:waseet/common_widgets/adaptive_image.dart';
import 'package:waseet/router/screens.dart';

/// {@template ad_details_body}
/// Body of the AdDetailsPage.
///
/// Add what it does
/// {@endtemplate}
class AdDetailsBody extends StatelessWidget {
  /// {@macro ad_details_body}
  const AdDetailsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdDetailsCubit, AdDetailsState>(
      builder: (context, state) {
        if (state.status == AdDetailsStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state.status == AdDetailsStatus.error) {
          return Center(
            child: Text(state.message),
          );
        }

        final ad = state.ad;
        if (ad == null) return const SizedBox.shrink();
        final creatorId = ad.createdBy?.id;
        final phone = ad.contactPhone ??
            ad.createdBy?.profile?.phone ??
            ad.createdBy?.phone;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10).r,
            child: Column(
              children: [
                Column(
                  children: [
                    if (ad.images?.isNotEmpty ?? false)
                      Container(
                        height: 0.25.sh,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.5),
                          ),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: ImagesBanner(
                          images: ad.images!.map((e) => e).toList(),
                        ),
                      ),
                    Row(
                      children: [
                        Assets.icons.apartment.svg(),
                        SizedBox(width: 10.w),
                        Text(
                          'نوع العقار',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ).r,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        ad.category?.name ?? unavailableAdValue,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.primaryColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        [ad.city?.name, ad.neighborhood?.name]
                            .whereType<String>()
                            .where((name) => name.isNotEmpty)
                            .join('، '),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.w),
                Row(
                  children: [
                    Assets.icons.dollar.svg(
                      color: AppColors.primaryColor,
                      width: 16.w,
                      height: 16.h,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _headerPriceText(ad),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      ad.negotiable == null
                          ? unavailableAdValue
                          : ad.negotiable!
                              ? 'قابل للتفاوض'
                              : 'غير قابل للتفاوض',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                AdRegulatoryDetails(ad: ad),
                SizedBox(height: 16.h),
                Column(
                  children: [
                    Row(
                      children: [
                        Assets.icons.paperDetails.svg(
                          color: AppColors.primaryColor,
                          width: 16.w,
                          height: 16.h,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'تفاصيل الإعلان',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ).r,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10).r,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        ad.extraInfo ?? '',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Column(
                  children: [
                    Row(
                      children: [
                        Assets.icons.messageEmpty.svg(
                          color: AppColors.primaryColor,
                          width: 16.w,
                          height: 16.h,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'بيانات التواصل',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    InkWell(
                      onTap: creatorId == null
                          ? null
                          : () {
                              context.pushNamed(
                                Screens.myPersonalOffice.name,
                                extra: {
                                  'brokerId': ad.createdBy?.id,
                                },
                              );
                            },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ).r,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10).r,
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20.w,
                              backgroundImage:
                                  ad.createdBy?.profile?.profileImage != null
                                      ? adaptiveImageProvider(
                                          ad.createdBy?.profile?.profileImage,
                                        )
                                      : null,
                              backgroundColor:
                                  ad.createdBy?.profile?.profileImage == null
                                      ? AppColors.primaryColor
                                      : null,
                              child: ad.createdBy?.profile?.profileImage == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ad.createdBy?.profile?.name ??
                                        ad.createdBy?.name ??
                                        unavailableAdValue,
                                  ),
                                  Text(phone ?? unavailableAdValue),
                                ],
                              ),
                            ),
                            SizedBox(width: 10.w),
                            // TODO: add call and message functionality
                            BrokerItemIcon(
                              onTap: () {
                                if (ad.communicationMethod == 'call' &&
                                    phone != null &&
                                    phone.isNotEmpty) {
                                  HelperMethod.openCall(
                                    phone,
                                  );
                                } else if (ad.communicationMethod ==
                                        'whatsapp' &&
                                    phone != null &&
                                    phone.isNotEmpty) {
                                  HelperMethod.openWhatsapp(
                                    phone,
                                  );
                                } else if (ad.communicationMethod != 'call' &&
                                    ad.communicationMethod != 'whatsapp' &&
                                    creatorId != null) {
                                  HelperMethod.createChatRoom(
                                    creatorId,
                                    context,
                                  );
                                }
                              },
                              icon: ad.communicationMethod == 'call'
                                  ? Icons.call
                                  : Icons.message,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Header price resolved through [AdvertisementPriceResolver]: legacy root
/// price when valid, otherwise the authoritative regulatory price (land
/// total for land ads, official property price otherwise). Rental amounts
/// never gain an invented billing period.
String _headerPriceText(AdEntity ad) {
  final price = AdvertisementPriceResolver.resolve(ad);
  if (!price.hasTotal) return unavailableAdValue;
  return '${formatAdPriceAmount(price.total!)} ريال';
}
