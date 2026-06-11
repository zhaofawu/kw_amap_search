import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'kw_amap_search_method_channel.dart';
import 'search_result_item.dart';

abstract class KwAmapSearchPlatform extends PlatformInterface {
  /// Constructs a KwAmapSearchPlatform.
  KwAmapSearchPlatform() : super(token: _token);

  static final Object _token = Object();

  static KwAmapSearchPlatform _instance = MethodChannelKwAmapSearch();

  /// The default instance of [KwAmapSearchPlatform] to use.
  ///
  /// Defaults to [MethodChannelKwAmapSearch].
  static KwAmapSearchPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KwAmapSearchPlatform] when
  /// they register themselves.
  static set instance(KwAmapSearchPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> setApiKey(String androidKey, String iosKey) {
    throw UnimplementedError('setApiKey() has not been implemented.');
  }

  Future<void> updatePrivacyShow(bool hasContains, bool hasShow) {
    throw UnimplementedError('updatePrivacyShow() has not been implemented.');
  }

  Future<void> updatePrivacyAgree(bool hasAgree) {
    throw UnimplementedError('updatePrivacyAgree() has not been implemented.');
  }

  Future<List<SearchResultItem>> searchKeyword({
    required String keyword,
    String city = '',
    String types = '',
    int pageSize = 20,
    int pageNum = 1,
  }) {
    throw UnimplementedError('searchKeyword() has not been implemented.');
  }

  Future<List<SearchResultItem>> searchAround({
    required double latitude,
    required double longitude,
    String keyword = '',
    String city = '',
    String types = '',
    int pageSize = 20,
    int pageNum = 1,
  }) {
    throw UnimplementedError('searchAround() has not been implemented.');
  }
}
