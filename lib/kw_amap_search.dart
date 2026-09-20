import 'kw_amap_search_platform_interface.dart';
import 'search_result_item.dart';

export 'search_result_item.dart';

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

  static Future<List<SearchResultItem>> searchByKeyword(
    AmapKeywordSearchQuery query, {
    AmapSearchRequestOptions? options,
  }) {
    return KwAmapSearchPlatform.instance.searchByKeyword(
      query,
      options: options,
    );
  }

  static Future<List<SearchResultItem>> searchNearby(
    AmapAroundSearchQuery query, {
    AmapSearchRequestOptions? options,
  }) {
    return KwAmapSearchPlatform.instance.searchNearby(query, options: options);
  }

  static Future<AmapRegeocodeResult> reverseGeocode(
    AmapReverseGeocodeQuery query, {
    AmapSearchRequestOptions? options,
  }) {
    return KwAmapSearchPlatform.instance.reverseGeocode(
      query,
      options: options,
    );
  }

  static Future<bool> cancelRequest(String requestId) {
    return KwAmapSearchPlatform.instance.cancelRequest(requestId);
  }

  /// Legacy keyword-search API kept for source compatibility.
  ///
  /// New code may prefer [searchByKeyword] because query objects are easier to
  /// extend without growing another long named-parameter list.
  static Future<List<SearchResultItem>> searchKeyword({
    required String keyword,
    String city = '',
    String types = '',
    int pageSize = 20,
    int pageNum = 1,
    AmapSearchRequestOptions? options,
  }) {
    return KwAmapSearchPlatform.instance.searchKeyword(
      keyword: keyword,
      city: city,
      types: types,
      pageSize: pageSize,
      pageNum: pageNum,
      options: options,
    );
  }

  /// Legacy around-search API with a new optional [radius] parameter.
  ///
  /// The default remains 1000 meters, matching the first Android-only port.
  static Future<List<SearchResultItem>> searchAround({
    required double latitude,
    required double longitude,
    int radius = 1000,
    String keyword = '',
    String city = '',
    String types = '',
    int pageSize = 20,
    int pageNum = 1,
    AmapAroundSortRule sortRule = AmapAroundSortRule.distance,
    AmapSearchRequestOptions? options,
  }) {
    return KwAmapSearchPlatform.instance.searchAround(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      keyword: keyword,
      city: city,
      types: types,
      pageSize: pageSize,
      pageNum: pageNum,
      sortRule: sortRule,
      options: options,
    );
  }
}
