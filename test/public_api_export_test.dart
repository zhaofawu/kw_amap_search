import 'package:flutter_test/flutter_test.dart';
import 'package:kw_amap_search/kw_amap_search.dart';

void main() {
  test('main library exports public query and result types', () {
    const center = AmapLatLng(latitude: 31.2304, longitude: 121.4737);
    const keywordQuery = AmapKeywordSearchQuery(keyword: 'coffee');
    const aroundQuery = AmapAroundSearchQuery(center: center, radius: 1500);
    const exception = AmapSearchException(code: 'AMAP_SEARCH_ERROR');

    final item = SearchResultItem.fromJson(<String, Object?>{
      'poiId': 'B001',
      'title': 'Public API POI',
      'snippet': 'Address',
      'latLonPoint': center.toJson(),
    });

    expect(keywordQuery.keyword, 'coffee');
    expect(aroundQuery.radius, 1500);
    expect(exception.code, 'AMAP_SEARCH_ERROR');
    expect(item.name, 'Public API POI');
  });
}
