
import 'kw_amap_search_platform_interface.dart';

class KwAmapSearch {
  Future<String?> getPlatformVersion() {
    return KwAmapSearchPlatform.instance.getPlatformVersion();
  }
}
