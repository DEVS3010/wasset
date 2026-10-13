// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waseet/common_widgets/broker_item_icon.dart';
import 'package:waseet/common_widgets/images_banner.dart';
import 'package:waseet/features/advertisement/domain/entities/ad_entity.dart';
import 'package:waseet/features/advertisement/domain/entities/advertisement_price.dart';
import 'package:waseet/features/advertisement/presentation/ad_details/widgets/ad_regulatory_details.dart';
import 'package:waseet/features/advertisement/presentation/advertisements/cubit/advertisements_cubit.dart';
import 'package:waseet/features/advertisement/presentation/advertisements/widgets/advertisement_popup_menu_button.dart';
import 'package:waseet/res/helper_method.dart';
import 'package:waseet/res/res.dart';
import 'package:waseet/router/screens.dart';

class AdCard extends StatelessWidget {
  const AdCard({
    super.key,
    required this.ad,
  });
  final AdEntity ad;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          Screens.adDetails.name,
          extra: ad,
        );
      },
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8).r,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        //TODO : ممكن اضافة صورة لاتوجد صور في حالة ماف صورة بدل يكون فاضي ؟

        height: ad.images != null && ad.images!.isNotEmpty ? 279.h : 129.h,
        child: Column(
          children: [
            if (ad.images != null && ad.images!.isNotEmpty)
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ImagesBanner(
                        images: ad.images!,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4).r,
                        color: Colors.black.withOpacity(0.5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ad.category?.name ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                              ),
                            ),
                            Text(
                              //TODO : set real time
                              DateFormat('yyyy-MM-dd').format(DateTime.now()),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              flex: 3,
              child: Container(
                // color: Colors.grey,
                padding: const EdgeInsets.all(8).r,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: const Color.fromRGBO(116, 50, 255, 1),
                                size: 15.sp,
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  '${ad.city?.name ?? ''} - ${ad.neighborhood?.name ?? ''}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16.w),
                        // price
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.attach_money,
                                color: AppColors.primaryColor,
                                size: 15.sp,
                              ),
                              Flexible(
                                child: Text(
                                  _cardPriceText(ad),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'ريال',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 3 icons(chat, share, delete) with rounded container
                        // and opacity of primary color
                        SizedBox(width: 8.w),
                        Stack(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                BrokerItemIcon(
                                  onTap: () {
                                    final creatorId = ad.createdBy?.id;
                                    if (creatorId != null) {
                                      HelperMethod.createChatRoom(
                                        creatorId, context,
                                      );
                                    }
                                  },
                                  icon: Icons.message,
                                ),
                                BrokerItemIcon(
                                  onTap: () {
                                    ad.isFav == true
                                        ? context
                                            .read<AdvertisementsCubit>()
                                            .removeFavAd(ad.id!)
                                        : context
                                            .read<AdvertisementsCubit>()
                                            .addFavAd(ad.id!);
                                  },
                                  icon: ad.isFav == true
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                                SizedBox(
                                  width: 40.w,
                                ),
                              ],
                            ),
                            Positioned(
                              left: 0,
                              top: -13,
                              child: AdvertisementPopupMenuButton(
                                ad: ad,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    // Horizontally scrollable so fixed feature chips cannot
                    // overflow narrow screens (non-fatal stripe in release,
                    // hard error under widget tests).
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          AdFeature(
                            icon: Icons.align_vertical_center,
                            text: '${ad.landSpace}  م',
                          ),
                          AdFeature(
                            icon: Icons.bed,
                            //TODO : change id with rooms num
                            text: '${ad.id} غرف',
                          ),
                          AdFeature(
                            icon: Icons.bathtub,
                            //TODO : change id with bath num
                            text: '${ad.id} حمام',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    InkWell(
                      onTap: () {
                        context.pushNamed(
                          Screens.myPersonalOffice.name,
                          extra: {
                            'brokerId': ad.createdBy?.id,
                          },
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'انتقال للوسيط',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.primaryColor,
                            size: 15.sp,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdFeature extends StatelessWidget {
  const AdFeature({
    super.key,
    required this.icon,
    required this.text,
  });
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5).r,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ).r,
      decoration: BoxDecoration(
        color: const Color.fromARGB(64, 174, 198, 253),
        borderRadius: BorderRadius.circular(20).r,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryColor,
            size: 15.sp,
          ),
          SizedBox(
            width: 8.w,
          ),
          Text(
            text,
            style: TextStyle(
              color: Colors.black,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card price resolved through [AdvertisementPriceResolver], shared by the
/// advertisements list, favorites, and user ads so every card matches the
/// details header. Rental amounts never gain an invented billing period.
String _cardPriceText(AdEntity ad) {
  final price = AdvertisementPriceResolver.resolve(ad);
  if (!price.hasTotal) return unavailableAdValue;
  return formatAdPriceAmount(price.total!);
}
