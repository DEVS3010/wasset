import 'dart:developer';

import 'package:flutter/foundation.dart';

/// Policy for malformed list items: skip the single unusable item and keep
/// the rest of the page. A transport-level failure still fails the request in
/// the datasource; this only isolates per-item model failures. Diagnostics
/// are debug-only and sanitized (index and error type only — never the
/// payload, which may contain personal data).
mixin BasePaginationResponse<T> {
  int? status;
  String? message;
  Map<String, dynamic>? errors;
  List<T>? data;
  int? currentPage;
  int? lastPage;
  int? total;
  String? nextPageUrl;

  fromJson(
    Map<String, dynamic> json, {
    T Function(Map<String, dynamic> item)? builder,
  }) {
    status = json['status'] as int?;
    message = json['message'] as String?;
    errors = json['errors'] as Map<String, dynamic>?;
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final links = json['links'] as Map<String, dynamic>? ?? {};
    currentPage = meta['current_page'] as int?;
    lastPage = meta['last_page'] as int?;
    total = meta['total'] as int?;
    nextPageUrl = links['next'] as String?;
    if (json['data'] != null) {
      data = [];
      if (json['data'] is List) {
        final items = json['data'] as List;
        for (var index = 0; index < items.length; index++) {
          final mapped = _mapOrNull(items[index]);
          if (mapped == null) {
            _logSkippedItem(index, 'non-map entry');
            continue;
          }
          try {
            data?.add(builder!(mapped));
          } catch (error) {
            // The model builder rejected this entry (missing identity or
            // malformed nested fields): skip it, keep the page.
            _logSkippedItem(index, error.runtimeType.toString());
          }
        }
      } else {
        final mapped = _mapOrNull(json['data']);
        if (mapped == null) {
          _logSkippedItem(0, 'non-map entry');
        } else {
          try {
            data?.add(builder!(mapped));
          } catch (error) {
            _logSkippedItem(0, error.runtimeType.toString());
          }
        }
      }
    }
  }
}

Map<String, dynamic>? _mapOrNull(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

void _logSkippedItem(int index, String reason) {
  if (kDebugMode) {
    log(
      'Skipping malformed list item at index $index ($reason).',
      name: 'Pagination',
    );
  }
}
