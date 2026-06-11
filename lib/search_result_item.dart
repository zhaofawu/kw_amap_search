import 'package:flutter/services.dart';

/// Typed exception for errors reported by the native AMap SDKs.
///
/// The first Android-only version surfaced every native failure as an empty
/// result list. That made "no POIs found" indistinguishable from "invalid key"
/// or "network timeout", so the plugin now converts platform errors into this
/// explicit Dart exception while keeping the original error payload in [details].
class AmapSearchException implements Exception {
  const AmapSearchException({required this.code, this.message, this.details});

  factory AmapSearchException.fromPlatformException(PlatformException error) {
    return AmapSearchException(
      code: error.code,
      message: error.message,
      details: error.details,
    );
  }

  final String code;
  final String? message;
  final Object? details;

  @override
  String toString() {
    final text = message == null || message!.isEmpty ? code : '$code: $message';
    return 'AmapSearchException($text)';
  }
}

/// Simple latitude/longitude value used by both query inputs and POI outputs.
class AmapLatLng {
  const AmapLatLng({required this.latitude, required this.longitude});

  factory AmapLatLng.fromJson(dynamic json) {
    final map = _asMap(json);
    return AmapLatLng(
      latitude: _double(map['latitude']),
      longitude: _double(map['longitude']),
    );
  }

  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'latitude': latitude, 'longitude': longitude};
  }

  @override
  bool operator ==(Object other) {
    return other is AmapLatLng &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// Keyword POI search parameters.
///
/// The facade still exposes the legacy named-parameter call, but internally both
/// Android and iOS receive this normalized shape.
class AmapKeywordSearchQuery {
  const AmapKeywordSearchQuery({
    required this.keyword,
    this.city = '',
    this.types = '',
    this.pageSize = 20,
    this.pageNum = 1,
  });

  final String keyword;
  final String city;
  final String types;
  final int pageSize;
  final int pageNum;

  Map<String, Object?> toMethodArguments() {
    return <String, Object?>{
      'keyword': keyword,
      'city': city,
      'types': types,
      'pageSize': pageSize,
      'pageNum': pageNum,
    };
  }
}

/// Around-search parameters with an explicit radius.
///
/// The default radius remains 1000 meters to preserve the old Android behavior,
/// while callers can now opt into a different search radius on both platforms.
class AmapAroundSearchQuery {
  const AmapAroundSearchQuery({
    required this.center,
    this.keyword = '',
    this.city = '',
    this.types = '',
    this.pageSize = 20,
    this.pageNum = 1,
    this.radius = 1000,
  });

  final AmapLatLng center;
  final String keyword;
  final String city;
  final String types;
  final int pageSize;
  final int pageNum;
  final int radius;

  Map<String, Object?> toMethodArguments() {
    return <String, Object?>{
      'latitude': center.latitude,
      'longitude': center.longitude,
      'radius': radius,
      'keyword': keyword,
      'city': city,
      'types': types,
      'pageSize': pageSize,
      'pageNum': pageNum,
    };
  }
}

/// A normalized POI result returned by both Android and iOS.
///
/// The native layer still sends the legacy map keys (`poiId`, `title`,
/// `snippet`, etc.) because that schema is already proven across the first port.
/// This Dart model presents those fields with clearer names while exposing
/// legacy getters so existing apps do not need an immediate migration.
class SearchResultItem {
  /// Creates a normalized POI item.
  ///
  /// Both the new names (`id`, `name`, `location`, `children`) and the legacy
  /// generated-model names (`poiId`, `title`, `latLonPoint`, `subPois`) are
  /// accepted here. The fields below stay normalized so the rest of the plugin
  /// does not have to carry two naming schemes around.
  const SearchResultItem({
    String? id,
    String? name,
    String? address,
    AmapLatLng? location,
    String? typeCode,
    String? typeDescription,
    String? adCode,
    String? adName,
    String? cityName,
    String? cityCode,
    String? provinceCode,
    String? provinceName,
    String? businessArea,
    String? direction,
    int? distance,
    String? email,
    AmapLatLng? entryLocation,
    AmapLatLng? exitLocation,
    bool? isIndoorMap,
    String? parkingType,
    List<PoiPhoto>? photos,
    PoiOpeningHours? openingHours,
    String? postcode,
    String? shopId,
    List<PoiChild>? children,
    String? tel,
    String? website,
    PoiIndoorInfo? indoor,
    String? poiId,
    String? title,
    String? snippet,
    AmapLatLng? latLonPoint,
    AmapLatLng? enter,
    AmapLatLng? exit,
    String? typeDes,
    String? shopID,
    PoiIndoorInfo? indoorData,
    PoiOpeningHours? poiExtension,
    List<PoiChild>? subPois,
  }) : id = id ?? poiId ?? '',
       name = name ?? title ?? '',
       address = address ?? snippet ?? '',
       location =
           location ??
           latLonPoint ??
           const AmapLatLng(latitude: 0, longitude: 0),
       typeCode = typeCode ?? '',
       typeDescription = typeDescription ?? typeDes ?? '',
       adCode = adCode ?? '',
       adName = adName ?? '',
       cityName = cityName ?? '',
       cityCode = cityCode ?? '',
       provinceCode = provinceCode ?? '',
       provinceName = provinceName ?? '',
       businessArea = businessArea ?? '',
       direction = direction ?? '',
       distance = distance ?? 0,
       email = email ?? '',
       entryLocation =
           entryLocation ??
           enter ??
           const AmapLatLng(latitude: 0, longitude: 0),
       exitLocation =
           exitLocation ?? exit ?? const AmapLatLng(latitude: 0, longitude: 0),
       isIndoorMap = isIndoorMap ?? false,
       parkingType = parkingType ?? '',
       photos = photos ?? const <PoiPhoto>[],
       openingHours =
           openingHours ?? poiExtension ?? const PoiOpeningHours(openTime: ''),
       postcode = postcode ?? '',
       shopId = shopId ?? shopID ?? '',
       children = children ?? subPois ?? const <PoiChild>[],
       tel = tel ?? '',
       website = website ?? '',
       indoor =
           indoor ??
           indoorData ??
           const PoiIndoorInfo(floor: 0, floorName: '', poiId: '');

  factory SearchResultItem.fromJson(dynamic json) {
    final map = _asMap(json);
    return SearchResultItem(
      id: _string(map['poiId']),
      name: _string(map['title']),
      address: _string(map['snippet']),
      location: AmapLatLng.fromJson(map['latLonPoint']),
      typeCode: _string(map['typeCode']),
      typeDescription: _string(map['typeDes']),
      adCode: _string(map['adCode']),
      adName: _string(map['adName']),
      cityName: _string(map['cityName']),
      cityCode: _string(map['cityCode']),
      provinceCode: _string(map['provinceCode']),
      provinceName: _string(map['provinceName']),
      businessArea: _string(map['businessArea']),
      direction: _string(map['direction']),
      distance: _int(map['distance']),
      email: _string(map['email']),
      entryLocation: AmapLatLng.fromJson(map['enter']),
      exitLocation: AmapLatLng.fromJson(map['exit']),
      isIndoorMap: _bool(map['isIndoorMap']),
      parkingType: _string(map['parkingType']),
      photos: _list(map['photos']).map(PoiPhoto.fromJson).toList(),
      openingHours: PoiOpeningHours.fromJson(map['poiExtension']),
      postcode: _string(map['postcode']),
      shopId: _string(map['shopID']),
      children: _list(map['subPois']).map(PoiChild.fromJson).toList(),
      tel: _string(map['tel']),
      website: _string(map['website']),
      indoor: PoiIndoorInfo.fromJson(map['indoorData']),
    );
  }

  final String id;
  final String name;
  final String address;
  final AmapLatLng location;
  final String typeCode;
  final String typeDescription;
  final String adCode;
  final String adName;
  final String cityName;
  final String cityCode;
  final String provinceCode;
  final String provinceName;
  final String businessArea;
  final String direction;
  final int distance;
  final String email;
  final AmapLatLng entryLocation;
  final AmapLatLng exitLocation;
  final bool isIndoorMap;
  final String parkingType;
  final List<PoiPhoto> photos;
  final PoiOpeningHours openingHours;
  final String postcode;
  final String shopId;
  final List<PoiChild> children;
  final String tel;
  final String website;
  final PoiIndoorInfo indoor;

  // Compatibility aliases for the first Android-only API surface.
  String get poiId => id;
  String get title => name;
  String get snippet => address;
  AmapLatLng get latLonPoint => location;
  AmapLatLng get enter => entryLocation;
  AmapLatLng get exit => exitLocation;
  String get typeDes => typeDescription;
  String get shopID => shopId;
  PoiIndoorInfo get indoorData => indoor;
  PoiOpeningHours get poiExtension => openingHours;
  List<PoiChild> get subPois => children;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'adCode': adCode,
      'adName': adName,
      'cityName': cityName,
      'cityCode': cityCode,
      'indoorData': indoor.toJson(),
      'businessArea': businessArea,
      'direction': direction,
      'distance': distance,
      'email': email,
      'enter': entryLocation.toJson(),
      'exit': exitLocation.toJson(),
      'isIndoorMap': isIndoorMap,
      'latLonPoint': location.toJson(),
      'parkingType': parkingType,
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'poiExtension': openingHours.toJson(),
      'poiId': id,
      'postcode': postcode,
      'provinceCode': provinceCode,
      'provinceName': provinceName,
      'shopID': shopId,
      'snippet': address,
      'subPois': children.map((child) => child.toJson()).toList(),
      'tel': tel,
      'title': name,
      'typeCode': typeCode,
      'typeDes': typeDescription,
      'website': website,
    };
  }
}

class PoiChild {
  /// Creates a child POI while accepting both the cleaned-up field names and the
  /// legacy `SubPois` constructor argument names.
  const PoiChild({
    String? id,
    String? name,
    String? address,
    String? typeDescription,
    int? distance,
    String? shortName,
    AmapLatLng? location,
    String? poiId,
    String? title,
    String? snippet,
    String? subTypeDes,
    String? subName,
    AmapLatLng? subLatLonPoint,
  }) : id = id ?? poiId ?? '',
       name = name ?? title ?? '',
       address = address ?? snippet ?? '',
       typeDescription = typeDescription ?? subTypeDes ?? '',
       distance = distance ?? 0,
       shortName = shortName ?? subName ?? '',
       location =
           location ??
           subLatLonPoint ??
           const AmapLatLng(latitude: 0, longitude: 0);

  factory PoiChild.fromJson(dynamic json) {
    final map = _asMap(json);
    return PoiChild(
      id: _string(map['poiId']),
      name: _string(map['title']),
      address: _string(map['snippet']),
      typeDescription: _string(map['subTypeDes']),
      distance: _int(map['distance']),
      shortName: _string(map['subName']),
      location: AmapLatLng.fromJson(map['subLatLonPoint']),
    );
  }

  final String id;
  final String name;
  final String address;
  final String typeDescription;
  final int distance;
  final String shortName;
  final AmapLatLng location;

  // Legacy aliases.
  String get poiId => id;
  String get title => name;
  String get snippet => address;
  String get subTypeDes => typeDescription;
  String get subName => shortName;
  AmapLatLng get subLatLonPoint => location;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': name,
      'snippet': address,
      'subTypeDes': typeDescription,
      'distance': distance,
      'poiId': id,
      'subName': shortName,
      'subLatLonPoint': location.toJson(),
    };
  }
}

class PoiOpeningHours {
  const PoiOpeningHours({required this.openTime});

  factory PoiOpeningHours.fromJson(dynamic json) {
    final map = _asMap(json);
    return PoiOpeningHours(openTime: _string(map['openTime']));
  }

  final String openTime;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'openTime': openTime};
  }
}

class PoiPhoto {
  const PoiPhoto({required this.title, required this.url});

  factory PoiPhoto.fromJson(dynamic json) {
    final map = _asMap(json);
    return PoiPhoto(title: _string(map['title']), url: _string(map['url']));
  }

  final String title;
  final String url;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'title': title, 'url': url};
  }
}

class PoiIndoorInfo {
  const PoiIndoorInfo({
    required this.floor,
    required this.floorName,
    required this.poiId,
  });

  factory PoiIndoorInfo.fromJson(dynamic json) {
    final map = _asMap(json);
    return PoiIndoorInfo(
      floor: _int(map['floor']),
      floorName: _string(map['floorName']),
      poiId: _string(map['poiId']),
    );
  }

  final int floor;
  final String floorName;
  final String poiId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'floor': floor,
      'floorName': floorName,
      'poiId': poiId,
    };
  }
}

// Type aliases preserve source compatibility for code that imported the first
// generated models directly. New code should prefer AmapLatLng/PoiPhoto/etc.
typedef LatLonPoint = AmapLatLng;
typedef Enter = AmapLatLng;
typedef Exit = AmapLatLng;
typedef SubLatLonPoint = AmapLatLng;
typedef SubPois = PoiChild;
typedef PoiExtension = PoiOpeningHours;
typedef Photos = PoiPhoto;
typedef IndoorData = PoiIndoorInfo;

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}

List<dynamic> _list(dynamic value) {
  if (value is List) {
    return value;
  }
  return <dynamic>[];
}

String _string(dynamic value) => value?.toString() ?? '';

int _int(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _bool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  return value?.toString().toLowerCase() == 'true';
}
