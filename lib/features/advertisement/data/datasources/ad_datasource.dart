import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:waseet/features/advertisement/data/models/ad_failure.dart';
import 'package:waseet/features/advertisement/data/models/ad_response.dart';
import 'package:waseet/features/advertisement/data/models/verify_license_response.dart';
import 'package:waseet/features/advertisement/data/models/post_response.dart';
import 'package:waseet/features/advertisement/domain/entities/ad_entity.dart';
import 'package:waseet/features/advertisement/domain/entities/post_entity.dart';
import 'package:waseet/features/advertisement/domain/entities/verify_license_entity.dart';
import 'package:waseet/features/advertisement/domain/entities/request/add_ad_request.dart';
import 'package:waseet/features/advertisement/domain/entities/request/add_new_post_request.dart';
import 'package:waseet/features/advertisement/domain/entities/request/get_posts_request.dart';
import 'package:waseet/features/brokers/domain/entities/request/get_ads_param.dart';
import 'package:waseet/res/api_failure.dart';
import 'package:waseet/res/api_service.dart';
import 'package:waseet/res/resource.dart';
import 'package:waseet/res/shared_preferences.dart';

class AdDatasource {
  AdDatasource({required ApiService apiService}) : _apiServices = apiService;
  final ApiService _apiServices;

  Future<Resource<List<AdEntity>?>> getAds({
    int page = 1,
    int pageSize = 10,
    GetAdsParam? param,
  }) async {
    try {
      final response = await _apiServices.get<Map<String, dynamic>>(
        '/advertisements',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (param?.brokerId != null) 'filter[user_id]': param!.brokerId,
        },
      );
      if (response == null || response['data'] == null) {
        return adFailure(ApiFailure.fromBody(response));
      }
      final ad = AdResponse.fromMap(response);
      if (ad.data != null) {
        return Resource.success(ad.data!.map((e) => e.toEntity()).toList());
      }
      return adFailure(ApiFailure.fromBody(response));
    } catch (e) {
      return adFailure(e);
    }
  }

  Future<Resource<List<AdEntity>?>> getFavAds() async {
    try {
      final response = await _apiServices.get<Map<String, dynamic>>(
        '/users/advertisements/favorites',
      );
      if (response == null || response['data'] == null) {
        return adFailure(ApiFailure.fromBody(response));
      }
      final ad = AdResponse.fromMap(response);
      if (ad.data != null) {
        return Resource.success(ad.data!.map((e) => e.toEntity()).toList());
      }
      return adFailure(ApiFailure.fromBody(response));
    } catch (e) {
      return adFailure(e);
    }
  }

  //create ad
  Future<Resource<AdEntity?>> createAd(AddAdRequest adRequest) async {
    try {
      final body = await adRequest.toJson();
      final response = await _apiServices.post<Map<String, dynamic>>(
        '/advertisements',
        data: dio.FormData.fromMap(body),
      );
      if (response == null || response['data'] == null) {
        return adFailure(ApiFailure.fromBody(response));
      }
      final ad = AdResponse.fromMap(response);
      // List<AdModel>
      if (ad.data?.isNotEmpty ?? false) {
        // final images = <dio.MultipartFile>[];
        // for (final image in adRequest.images) {
        //   images.add(
        //     await dio.MultipartFile.fromFile(
        //       image.path,
        //       filename: image.path.split('/').last,
        //     ),
        //   );
        // }
        // final uploadImages = await _apiServices.put<Map<String, dynamic>>(
        //   '/advertisement'
        //   '/${ad.data!.first.id}',
        //   data: dio.FormData.fromMap({
        //     'attechments': images,
        //   }),
        //   headers: {
        //     'Content-Type': 'multipart/form-data',
        //   },
        // );
        return Resource.success(ad.data!.first.toEntity());
      }

      return adFailure(ApiFailure.fromBody(response));
    } catch (e) {
      return adFailure(e);
    }
  }

  Future<Resource<AdEntity?>> createAdWithVerification(
  String advertiserId,
  String adLicenseNumber,
  String extraInfo,
  List<File> files,
) async {
  try {
    // Validate files and build FormData
    final form = dio.FormData();

    // Fields
    if (adLicenseNumber.trim().isNotEmpty) {
      form.fields.add(MapEntry('adLicenseNumber', adLicenseNumber.trim()));
    }
    if (advertiserId.trim().isNotEmpty) {
      form.fields.add(MapEntry('advertiserId', advertiserId.trim()));
    }
    if (extraInfo.trim().isNotEmpty) {
      form.fields.add(MapEntry('extra_info', extraInfo.trim()));
    }

    // Files (match Postman: attachment_files[0], attachment_files[1], ...)
    for (var i = 0; i < files.length; i++) {
      final f = files[i];

      if (!f.existsSync()) {
        return Resource.error('تعذر قراءة المرفق. يرجى اختياره مرة أخرى.');
      }

      final fileName = f.uri.pathSegments.isNotEmpty
          ? f.uri.pathSegments.last
          : f.path.split(Platform.pathSeparator).last;

      form.files.add(
        MapEntry(
          'attachment_files[$i]',
          await dio.MultipartFile.fromFile(
            f.path,
            filename: fileName,
          ),
        ),
      );
    }

    final response = await _apiServices.post<Map<String, dynamic>>(
      '/advertisements/create-with-verification',
      data: form,
      headers: {
        'Accept': 'application/json',
        // IMPORTANT: do NOT set Content-Type manually for multipart
      },
    );

    if (response == null || response['data'] == null) {
      return adFailure(ApiFailure.fromBody(response));
    }
    final ad = AdResponse.fromMap(response);

    if (ad.data != null && ad.data!.isNotEmpty) {
      return Resource.success(ad.data!.first.toEntity());
    }

    return adFailure(ApiFailure.fromBody(response));
  } catch (e) {
    return adFailure(e);
  }
}

  Future<Resource<AdEntity?>> getAdById(int id) async {
    try {
      final response = await _apiServices.get<Map<String, dynamic>>(
        '/advertisements',
        queryParameters: {
          'filter[id]': id,
        },
      );
      if (response == null || response['data'] == null) {
        return adFailure(ApiFailure.fromBody(response));
      }
      final ad = AdResponse.fromMap(response);
      if (ad.data?.isNotEmpty ?? false) {
        return Resource.success(ad.data!.first.toEntity());
      }
      return adFailure(ApiFailure.fromBody(response));
    } catch (e) {
      return adFailure(e);
    }
  }

  /// Fetch advertisement by advertiserId and adLicenseNumber (used by new pre-wizard step)
  Future<Resource<AdEntity?>> getAdByAdvertiserAndLicense(
      String advertiserId, String adLicenseNumber,) async {
    try {
      final response = await _apiServices.post<Map<String, dynamic>>(
        '/advertisements',
        data: {
          'advertiserId': advertiserId,
          'adLicenseNumber': adLicenseNumber,
        },
      );

      if (response == null || response['data'] == null) {
        return adFailure(ApiFailure.fromBody(response));
      }
      final ad = AdResponse.fromMap(response);
      if (ad.data != null && ad.data!.isNotEmpty) {
        return Resource.success(ad.data!.first.toEntity());
      }
      return adFailure(ApiFailure.fromBody(response));
    } catch (e) {
      return adFailure(e);
    }
  }

  /// Verify license endpoint - returns detailed verification data
  Future<Resource<VerifyLicenseEntity?>> verifyLicense(
      String advertiserId, String adLicenseNumber,) async {
    try {
      final response = await _apiServices.post<Map<String, dynamic>>(
        '/advertisements/verify-license',
        data: {
          'adLicenseNumber': adLicenseNumber,
          'advertiserId': advertiserId,
        },
      );

      if (response == null) return adFailure(null);

      // The Wasset envelope wraps the payload in `data`; the NHC payload
      // itself may nest the advertisement under `result.advertisement`.
      // VerifyLicenseModel unwraps both, so either shape parses safely.
      final rawData = response['data'];
      final candidate = rawData is Map<String, dynamic>
          ? rawData
          : rawData is Map
              ? Map<String, dynamic>.from(rawData)
              : response;
      final model = VerifyLicenseModel.fromMap(candidate);
      // A payload without license identifiers is not a usable verification.
      // This keeps null/empty data a failure instead of an empty preview.
      if ((model.adLicenseNumber?.trim().isNotEmpty ?? false) ||
          (model.advertiserId?.trim().isNotEmpty ?? false)) {
        return Resource.success(model);
      }
      return adFailure(ApiFailure.fromBody(response));
    } catch (e) {
      return adFailure(e);
    }
  }

  Future<Resource<PostEntity?>> createPost(AddNewPostRequest request) async {
    try {
      final response = await _apiServices.post<Map<String, dynamic>>(
        '/posts',
        data: request.toMap(),
      );
      final post = PostsResponse.fromMap(response!);
      if (post.data != null) {
        return Resource.success(post.data!.first.toEntity());
      }
      return Resource.error(post.message ?? 'error', null, post.errors);
    } catch (e) {
      return Resource.error(e.toString());
    }
  }

  Future<Resource<PostEntity?>> getPostById(GetPostsRequest request) async {
    try {
      final response = await _apiServices.get<Map<String, dynamic>>(
        '/posts',
        queryParameters: request.toMap(),
      );
      final post = PostsResponse.fromMap(response!);
      if (post.data != null) {
        return Resource.success(post.data!.first.toEntity());
      }
      return Resource.error(post.message ?? 'error', null, post.errors);
    } catch (e) {
      return Resource.error(e.toString());
    }
  }

  Future<Resource<List<PostEntity>?>> getPosts(GetPostsRequest request) async {
    try {
      final response = await _apiServices.get<Map<String, dynamic>>(
        '/posts?filter[user_id]=${request.id}',
        queryParameters: request.toMap(),
      );
      final post = PostsResponse.fromMap(response!);
      if (post.data != null) {
        return Resource.success(post.data!.map((e) => e.toEntity()).toList());
      }
      return Resource.error(post.message ?? 'error', null, post.errors);
    } catch (e) {
      return Resource.error(e.toString());
    }
  }

  Future<Resource<PostEntity?>> updatePost(AddNewPostRequest request) async {
    try {
      final response = await _apiServices.put<Map<String, dynamic>>(
        '/posts/${request.id}',
        data: request.toMap(),
      );
      final post = PostsResponse.fromMap(response!);
      if (post.data != null) {
        return Resource.success(post.data!.first.toEntity());
      }
      return Resource.error(post.message ?? 'error', null, post.errors);
    } catch (e) {
      return Resource.error(e.toString());
    }
  }

  Future<Resource<PostEntity?>> deletePost(int id) async {
    try {
      await _apiServices.delete<Map<String, dynamic>>(
        '/posts/$id',
      );
      return Resource.success(null);
    } catch (e) {
      return Resource.error(e.toString());
    }
  }

  Future<Resource<String>> removeFavAd(int adId) async {
    try {
      final response = await _apiServices.delete<Map<String, dynamic>>(
        '/users/advertisements/$adId/favorite',
        headers: {
          'Authorization': 'Bearer ${wassetSharedPreferences.getToken()}}',
        },
      );

      if (response!['message'] != 'تم إزالة الإعلان من المفضلة بنجاح') {
        final message = response['message'] as String;
        return Resource.error(
          message,
        );
      }
      return Resource.success(response['message'] as String);
    } on Exception catch (e) {
      log(e.toString());
      return Resource.error(e.toString());
    }
  }

  Future<Resource<String>> addFavAd(int adId) async {
    try {
      final response = await _apiServices.post<Map<String, dynamic>>(
        '/users/advertisements/$adId/favorite',
        headers: {
          'Authorization': 'Bearer ${wassetSharedPreferences.getToken()}}',
        },
      );

      if (response!['message'] == 'تم إضافة الإعلان إلى المفضلة بنجاح') {
        return Resource.success(response['message'] as String);
      }
      final message = response['message'] as String;
      return Resource.error(
        message,
      );
    } on Exception catch (e) {
      log(e.toString());
      return Resource.error(e.toString());
    }
  }
}
