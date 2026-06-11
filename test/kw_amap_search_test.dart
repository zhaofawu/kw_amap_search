import 'package:flutter_test/flutter_test.dart';
import 'package:kw_amap_search/kw_amap_search.dart';
import 'package:kw_amap_search/kw_amap_search_method_channel.dart';
import 'package:kw_amap_search/kw_amap_search_platform_interface.dart';
import 'package:kw_amap_search/search_result_item.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKwAmapSearchPlatform
    with MockPlatformInterfaceMixin
    implements KwAmapSearchPlatform {
  String? androidKey;
  String? iosKey;
  bool? hasContains;
  bool? hasShow;
  bool? hasAgree;
  Map<String, Object?>? lastKeywordSearch;
  Map<String, Object?>? lastAroundSearch;

  final results = <SearchResultItem>[
    SearchResultItem.fromJson(_samplePoiJson()),
  ];

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> setApiKey(String androidKey, String iosKey) async {
    this.androidKey = androidKey;
    this.iosKey = iosKey;
  }

  @override
  Future<void> updatePrivacyShow(bool hasContains, bool hasShow) async {
    this.hasContains = hasContains;
    this.hasShow = hasShow;
  }

  @override
  Future<void> updatePrivacyAgree(bool hasAgree) async {
    this.hasAgree = hasAgree;
  }

  @override
  Future<List<SearchResultItem>> searchKeyword({
    required String keyword,
    String city = '',
    String types = '',
    int pageSize = 20,
    int pageNum = 1,
  }) async {
    lastKeywordSearch = <String, Object?>{
      'keyword': keyword,
      'city': city,
      'types': types,
      'pageSize': pageSize,
      'pageNum': pageNum,
    };
    return results;
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
    lastAroundSearch = <String, Object?>{
      'latitude': latitude,
      'longitude': longitude,
      'keyword': keyword,
      'city': city,
      'types': types,
      'pageSize': pageSize,
      'pageNum': pageNum,
    };
    return results;
  }
}

void main() {
  final initialPlatform = KwAmapSearchPlatform.instance;

  tearDown(() {
    KwAmapSearchPlatform.instance = initialPlatform;
  });

  test('$MethodChannelKwAmapSearch is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelKwAmapSearch>());
  });

  test('static facade forwards setup and search calls to platform', () async {
    final fakePlatform = MockKwAmapSearchPlatform();
    KwAmapSearchPlatform.instance = fakePlatform;

    expect(await KwAmapSearch.getPlatformVersion(), '42');

    await KwAmapSearch.setApiKey('android-key', 'ios-key');
    await KwAmapSearch.updatePrivacyShow(true, false);
    await KwAmapSearch.updatePrivacyAgree(true);
    final keywordResults = await KwAmapSearch.searchKeyword(
      keyword: 'coffee',
      city: 'Shanghai',
      types: '050000',
      pageSize: 10,
      pageNum: 2,
    );
    final aroundResults = await KwAmapSearch.searchAround(
      latitude: 31.2304,
      longitude: 121.4737,
      keyword: 'tea',
      city: 'Shanghai',
      types: '050000',
      pageSize: 12,
      pageNum: 3,
    );

    expect(fakePlatform.androidKey, 'android-key');
    expect(fakePlatform.iosKey, 'ios-key');
    expect(fakePlatform.hasContains, isTrue);
    expect(fakePlatform.hasShow, isFalse);
    expect(fakePlatform.hasAgree, isTrue);
    expect(fakePlatform.lastKeywordSearch, <String, Object?>{
      'keyword': 'coffee',
      'city': 'Shanghai',
      'types': '050000',
      'pageSize': 10,
      'pageNum': 2,
    });
    expect(fakePlatform.lastAroundSearch, <String, Object?>{
      'latitude': 31.2304,
      'longitude': 121.4737,
      'keyword': 'tea',
      'city': 'Shanghai',
      'types': '050000',
      'pageSize': 12,
      'pageNum': 3,
    });
    expect(keywordResults.single.title, 'Sample POI');
    expect(aroundResults.single.poiId, 'B001');
  });

  test('SearchResultItem parses and serializes native POI maps', () {
    final item = SearchResultItem.fromJson(_samplePoiJson());

    expect(item.adCode, '310101');
    expect(item.indoorData.floorName, 'F1');
    expect(item.enter.latitude, 31.2);
    expect(item.exit.longitude, 121.5);
    expect(item.latLonPoint.latitude, 31.2304);
    expect(item.photos.single.url, 'https://example.com/photo.jpg');
    expect(item.poiExtension.openTime, '09:00-18:00');
    expect(item.subPois.single.subLatLonPoint.longitude, 121.4738);
    expect(item.toJson()['title'], 'Sample POI');
  });
}

Map<String, Object?> _samplePoiJson() {
  return <String, Object?>{
    'adCode': '310101',
    'adName': 'Huangpu',
    'cityName': 'Shanghai',
    'cityCode': '021',
    'indoorData': <String, Object?>{
      'floor': 1,
      'floorName': 'F1',
      'poiId': 'indoor-1',
    },
    'businessArea': 'People Square',
    'direction': 'east',
    'distance': 120,
    'email': 'poi@example.com',
    'enter': <String, Object?>{'latitude': 31.2, 'longitude': 121.4},
    'exit': <String, Object?>{'latitude': 31.3, 'longitude': 121.5},
    'isIndoorMap': true,
    'latLonPoint': <String, Object?>{
      'latitude': 31.2304,
      'longitude': 121.4737,
    },
    'parkingType': 'ground',
    'photos': <Object?>[
      <String, Object?>{
        'title': 'front',
        'url': 'https://example.com/photo.jpg',
      },
    ],
    'poiExtension': <String, Object?>{'openTime': '09:00-18:00'},
    'poiId': 'B001',
    'postcode': '200000',
    'provinceCode': '310000',
    'provinceName': 'Shanghai',
    'shopID': 'shop-1',
    'snippet': 'Sample address',
    'subPois': <Object?>[
      <String, Object?>{
        'title': 'Sub POI',
        'snippet': 'Sub address',
        'subTypeDes': 'entrance',
        'distance': 15,
        'poiId': 'S001',
        'subName': 'North Gate',
        'subLatLonPoint': <String, Object?>{
          'latitude': 31.2305,
          'longitude': 121.4738,
        },
      },
    ],
    'tel': '021-00000000',
    'title': 'Sample POI',
    'typeCode': '050000',
    'typeDes': 'Dining',
    'website': 'https://example.com',
  };
}
