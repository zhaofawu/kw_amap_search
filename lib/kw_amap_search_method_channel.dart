import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'kw_amap_search_platform_interface.dart';
import 'search_result_item.dart';

/// An implementation of [KwAmapSearchPlatform] that uses method channels.
class MethodChannelKwAmapSearch extends KwAmapSearchPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('kw_amap_search');

  /// Invokes the native SDK and converts platform errors to the plugin's typed
  /// exception so callers can distinguish SDK failures from empty result sets.
  @visibleForTesting
  Future<T?> invokeNative<T>(String method, [Object? arguments]) async {
    try {
      return await methodChannel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw AmapSearchException.fromPlatformException(error);
    }
  }

  Future<T?> _invokeRequest<T>(
    String method,
    Map<String, Object?> arguments,
  ) async {
    final requestId = arguments['requestId'] as String?;
    final timeoutMs = arguments['timeoutMs'] as int?;
    final call = invokeNative<T>(method, arguments);
    if (requestId == null || timeoutMs == null) {
      return call;
    }
    try {
      return await call.timeout(Duration(milliseconds: timeoutMs));
    } on TimeoutException {
      // Cleanup must not block the timeout or replace its error.
      cancelRequest(requestId).ignore();
      throw AmapSearchException(
        code: 'timeout',
        message: 'AMap search request timed out.',
        details: <String, Object?>{'requestId': requestId, 'operation': method},
      );
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await invokeNative<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> setApiKey(String androidKey, String iosKey) async {
    await invokeNative<void>('setApiKey', <String, Object?>{
      'androidKey': androidKey,
      'iosKey': iosKey,
    });
  }

  @override
  Future<void> updatePrivacyShow(bool hasContains, bool hasShow) async {
    await invokeNative<void>('updatePrivacyShow', <String, Object?>{
      'hasContains': hasContains,
      'hasShow': hasShow,
    });
  }

  @override
  Future<void> updatePrivacyAgree(bool hasAgree) async {
    await invokeNative<void>('updatePrivacyAgree', <String, Object?>{
      'hasAgree': hasAgree,
    });
  }

  @override
  Future<List<SearchResultItem>> searchByKeyword(
    AmapKeywordSearchQuery query, {
    AmapSearchRequestOptions? options,
  }) async {
    final dataList = await _invokeRequest<List<dynamic>>(
      'searchKeyword',
      query.toMethodArguments(options: options),
    );
    return (dataList ?? <dynamic>[]).map(SearchResultItem.fromJson).toList();
  }

  @override
  Future<List<SearchResultItem>> searchNearby(
    AmapAroundSearchQuery query, {
    AmapSearchRequestOptions? options,
  }) async {
    final dataList = await _invokeRequest<List<dynamic>>(
      'searchAround',
      query.toMethodArguments(options: options),
    );
    return (dataList ?? <dynamic>[])
        .map(
          (item) => SearchResultItem.fromJson(item, queryCenter: query.center),
        )
        .toList();
  }

  @override
  Future<AmapRegeocodeResult> reverseGeocode(
    AmapReverseGeocodeQuery query, {
    AmapSearchRequestOptions? options,
  }) async {
    final data = await _invokeRequest<Map<dynamic, dynamic>>(
      'reverseGeocode',
      query.toMethodArguments(options: options),
    );
    return AmapRegeocodeResult.fromJson(data);
  }

  @override
  Future<bool> cancelRequest(String requestId) async {
    final trimmed = requestId.trim();
    if (trimmed.isEmpty) {
      throw const AmapSearchException(
        code: 'invalid_argument',
        message: 'requestId must not be empty.',
      );
    }
    return await invokeNative<bool>('cancelRequest', <String, Object?>{
          'requestId': trimmed,
        }) ??
        false;
  }
}
