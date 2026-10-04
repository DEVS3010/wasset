import 'package:dio/dio.dart';

/// Retains validation details and keeps transport diagnostics out of the UI.
class ApiFailure implements Exception {
  const ApiFailure({required this.message, this.errors, this.statusCode});

  factory ApiFailure.fromDio(DioException exception) {
    final body = exception.response?.data;
    return ApiFailure.fromBody(
      body,
      statusCode: exception.response?.statusCode,
    );
  }

  factory ApiFailure.fromBody(Object? body, {int? statusCode}) {
    final map = body is Map ? body : const <String, Object?>{};
    final errors = map['errors'];
    return ApiFailure(
      message: usefulMessage(map['message']) ??
          usefulMessage(map['error']) ??
          usefulMessage(errors) ??
          fallback,
      errors: errors is Map<String, dynamic> ? errors : null,
      statusCode: statusCode,
    );
  }

  static const fallback = 'تعذر إتمام الطلب. يرجى المحاولة مرة أخرى.';

  static String? usefulMessage(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is Iterable) {
      for (final item in value) {
        final message = usefulMessage(item);
        if (message != null) return message;
      }
    }
    if (value is Map) return usefulMessage(value.values);
    return null;
  }

  final String message;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  @override
  String toString() => message;
}
