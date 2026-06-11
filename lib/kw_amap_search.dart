import 'kw_amap_search_platform_interface.dart';
import 'search_result_item.dart';

class KwAmapSearch {
  KwAmapSearch._();

  static Future<String?> getPlatformVersion() {
    return KwAmapSearchPlatform.instance.getPlatformVersion();
  }

  static Future<void> setApiKey(String androidKey, String iosKey) {
    return KwAmapSearchPlatform.instance.setApiKey(androidKey, iosKey);
  }

  static Future<void> updatePrivacyShow(bool hasContains, bool hasShow) {
    return KwAmapSearchPlatform.instance.updatePrivacyShow(
      hasContains,
      hasShow,
    );
  }

  static Future<void> updatePrivacyAgree(bool hasAgree) {
    return KwAmapSearchPlatform.instance.updatePrivacyAgree(hasAgree);
  }

  static Future<List<SearchResultItem>> searchKeyword({
    required String keyword,
    String city = '',
    String types = '',
    int pageSize = 20,
    int pageNum = 1,
  }) {
    return KwAmapSearchPlatform.instance.searchKeyword(
      keyword: keyword,
      city: city,
      types: types,
      pageSize: pageSize,
      pageNum: pageNum,
    );
  }

  static Future<List<SearchResultItem>> searchAround({
    required double latitude,
    required double longitude,
    String keyword = '',
    String city = '',
    String types = '',
    int pageSize = 20,
    int pageNum = 1,
  }) {
    return KwAmapSearchPlatform.instance.searchAround(
      latitude: latitude,
      longitude: longitude,
      keyword: keyword,
      city: city,
      types: types,
      pageSize: pageSize,
      pageNum: pageNum,
    );
  }
}
