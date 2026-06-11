import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'kw_amap_search_method_channel.dart';

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
}
