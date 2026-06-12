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
    AmapKeywordSearchQuery query,
  ) async {
    final dataList = await invokeNative<List<dynamic>>(
      'searchKeyword',
      query.toMethodArguments(),
    );
    return (dataList ?? <dynamic>[]).map(SearchResultItem.fromJson).toList();
  }

  @override
  Future<List<SearchResultItem>> searchNearby(
    AmapAroundSearchQuery query,
  ) async {
    final dataList = await invokeNative<List<dynamic>>(
      'searchAround',
      query.toMethodArguments(),
    );
    return (dataList ?? <dynamic>[]).map(SearchResultItem.fromJson).toList();
  }
}
