import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:waseet/constants/constants.dart';
import 'package:waseet/res/api_failure.dart';
import 'package:waseet/res/shared_preferences.dart';

class ApiService {
  ApiService() {
    _dio.options.connectTimeout = const Duration(milliseconds: 60000);
    _dio.options.sendTimeout = const Duration(milliseconds: 60000);
    _dio.options.receiveTimeout = const Duration(milliseconds: 60000);

    if (!kReleaseMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: false,
          maxWidth: 40,
        ),
      );
    }
    // _dio.interceptors.add(InterceptorsWrapper(
    //     onError: (DioError dioError, _) => errorInterceptor(dioError)));

    _dio.options.baseUrl = Constants.baseApiUrl;
    _dio.options.headers.addAll({'Accept': 'application/json'});
    _dio.options.receiveDataWhenStatusError = true;
  }
  final Dio _dio = Dio();

  Future<T?> delete<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
  }) async {
    headers = await addToken(headers);
    final res = await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        headers: headers,
        extra: extra,
      ),
    );
    return res.data;
  }

  Future<T?> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    void Function(int, int)? onReceiveProgress,
  }) async {
    headers = await addToken(headers);

    late Response<T> res;
    try {
      await _dio
          .get<T>(
        path,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          extra: extra,
        ),
      )
          .then((value) {
        if (value.statusCode == 200) {
          res = value;
        }
        if (value.statusCode == 401) {
          wassetSharedPreferences.removeToken();
        }
        if (value.statusCode == 408) {
          get<T>(
            path,
            queryParameters: queryParameters,
            extra: extra,
            headers: headers,
            onReceiveProgress: onReceiveProgress,
          );
        }
      });
      return res.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        wassetSharedPreferences.removeToken();
      }
      return e.response?.data as T?;
    }
  }

  Future<T?> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    headers = await addToken(headers);

    try {
      final res = await _dio.post<T>(
        path,
        data: data,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        options: Options(headers: headers, extra: extra),
      );
      return res.data;
    } on DioException catch (e) {
      errorInterceptor(e);
      rethrow;
    }
  }

  Future<T?> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      headers = await addToken(headers);
      // headers.addAll({
      //   "content-type": "multipart/form-data"
      // });

      late Response<T> res;
      await _dio
          .put<T>(
        path,
        data: data,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          extra: extra,
        ),
      )
          .then((value) {
        if (value.statusCode == 200) {
          res = value;
        }
        if (value.statusCode == 201) {
          res = value;
        }
        if (value.statusCode == 408) {
          post<T>(
            path,
            data: data,
            onReceiveProgress: onReceiveProgress,
            headers: headers,
            extra: extra,
            queryParameters: queryParameters,
          );
        }
      });
      return res.data;
    } on DioException catch (e) {
      errorInterceptor(e);
    }
    return null;
  }

  // patch
  Future<T?> patch<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    headers = await addToken(headers);

    late Response<T> res;
    try {
      await _dio
          .patch<T>(
        path,
        data: data,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          extra: extra,
        ),
      )
          .then((value) {
        if (value.statusCode == 200) {
          res = value;
        }
        if (value.statusCode == 408) {
          post<T>(
            path,
            data: data,
            onReceiveProgress: onReceiveProgress,
            headers: headers,
            extra: extra,
            queryParameters: queryParameters,
          );
        }
      });
      return res.data;
    } on DioException catch (e) {
      errorInterceptor(e);
    }
    return null;
  }

  void errorInterceptor(DioException dioError) {
    if (dioError.response?.statusCode == 401) {
      wassetSharedPreferences.removeToken();
    }
    throw ApiFailure.fromDio(dioError);
  }

  Future<Map<String, dynamic>> addToken([Map<String, dynamic>? headers]) async {
    headers ??= {};
    String? token;
    token = wassetSharedPreferences.getToken();
    headers['Authorization'] = 'Bearer $token';
    return headers;
  }
}
