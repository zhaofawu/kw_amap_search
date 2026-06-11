import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'kw_amap_search_platform_interface.dart';
import 'search_result_item.dart';

/// An implementation of [KwAmapSearchPlatform] that uses method channels.
class MethodChannelKwAmapSearch extends KwAmapSearchPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('kw_amap_search');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> setApiKey(String androidKey, String iosKey) async {
    await methodChannel.invokeMethod<void>('setApiKey', <String, Object?>{
      'androidKey': androidKey,
      'iosKey': iosKey,
    });
  }

  @override
  Future<void> updatePrivacyShow(bool hasContains, bool hasShow) async {
    await methodChannel.invokeMethod<void>(
      'updatePrivacyShow',
      <String, Object?>{'hasContains': hasContains, 'hasShow': hasShow},
    );
  }

  @override
  Future<void> updatePrivacyAgree(bool hasAgree) async {
    await methodChannel.invokeMethod<void>(
      'updatePrivacyAgree',
      <String, Object?>{'hasAgree': hasAgree},
    );
  }

  @override
  Future<List<SearchResultItem>> searchKeyword({
    required String keyword,
    String city = '',
    String types = '',
    int pageSize = 20,
    int pageNum = 1,
  }) async {
    final dataList = await methodChannel
        .invokeMethod<List<dynamic>>('searchKeyword', <String, Object?>{
          'keyword': keyword,
          'city': city,
          'types': types,
          'pageSize': pageSize,
          'pageNum': pageNum,
        });
    return (dataList ?? <dynamic>[]).map(SearchResultItem.fromJson).toList();
  }

  @override
  Future<List<SearchResultItem>> searchAround({
    required double latitude,
    required double longitude,
    String keyword = '',
    String city = '',
    String types = '',
    int pageSize = 20,
    int pageNum = 1,
  }) async {
    final dataList = await methodChannel
        .invokeMethod<List<dynamic>>('searchAround', <String, Object?>{
          'latitude': latitude,
          'longitude': longitude,
          'keyword': keyword,
          'city': city,
          'types': types,
          'pageSize': pageSize,
          'pageNum': pageNum,
        });
    return (dataList ?? <dynamic>[]).map(SearchResultItem.fromJson).toList();
  }
}
