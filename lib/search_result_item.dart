import 'dart:math' as math;

import 'package:flutter/services.dart';

const String amapCoordinateTypeGcj02 = 'gcj02';

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

class AmapLatLng {
  const AmapLatLng({required this.latitude, required this.longitude});

  factory AmapLatLng.fromJson(dynamic json) {
    final point = AmapLatLng.tryParse(json);
    if (point == null) {
      throw ArgumentError.value(json, 'json', 'Invalid AMap coordinate.');
    }
    return point;
  }

  static AmapLatLng? tryParse(dynamic json) {
    final map = _asMapOrNull(json);
    if (map == null) return null;
    final latitude = _doubleOrNull(map['latitude']);
    final longitude = _doubleOrNull(map['longitude']);
    if (!_validLatitude(latitude) || !_validLongitude(longitude)) return null;
    return AmapLatLng(latitude: latitude!, longitude: longitude!);
  }

  final double latitude;
  final double longitude;

  void validate({String name = 'coordinate'}) {
    if (!_validLatitude(latitude) || !_validLongitude(longitude)) {
      throw AmapSearchException(
        code: 'invalid_argument',
        message: '$name must be finite GCJ-02 latitude/longitude.',
        details: <String, Object?>{
          'latitude': latitude,
          'longitude': longitude,
        },
      );
    }
  }

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

enum AmapAroundSortRule { distance, comprehensive }

extension on AmapAroundSortRule {
  String get methodValue {
    switch (this) {
      case AmapAroundSortRule.distance:
        return 'distance';
      case AmapAroundSortRule.comprehensive:
        return 'comprehensive';
    }
  }
}

class AmapSearchRequestOptions {
  const AmapSearchRequestOptions({this.requestId, this.timeout});

  final String? requestId;
  final Duration? timeout;

  Map<String, Object?> toMethodArguments(String operation) {
    final effectiveTimeout = timeout ?? const Duration(seconds: 10);
    if (effectiveTimeout <= Duration.zero) {
      throw const AmapSearchException(
        code: 'invalid_argument',
        message: 'timeout must be positive.',
      );
    }
    final id = requestId?.trim().isNotEmpty == true
        ? requestId!.trim()
        : _nextRequestId(operation);
    return <String, Object?>{
      'requestId': id,
      'timeoutMs': effectiveTimeout.inMilliseconds,
      'coordinateType': amapCoordinateTypeGcj02,
    };
  }

  static int _counter = 0;

  static String _nextRequestId(String operation) {
    _counter += 1;
    return 'kw-amap-$operation-${DateTime.now().microsecondsSinceEpoch}-$_counter';
  }
}

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

  Map<String, Object?> toMethodArguments({AmapSearchRequestOptions? options}) {
    final text = keyword.trim();
    if (text.isEmpty) {
      throw const AmapSearchException(
        code: 'invalid_argument',
        message: 'keyword must not be empty.',
      );
    }
    _validatePaging(pageSize: pageSize, pageNum: pageNum);
    return <String, Object?>{
      'keyword': text,
      'city': city,
      'types': types,
      'pageSize': pageSize,
      'pageNum': pageNum,
      ...(options ?? const AmapSearchRequestOptions()).toMethodArguments(
        'keyword',
      ),
    };
  }
}

class AmapAroundSearchQuery {
  const AmapAroundSearchQuery({
    required this.center,
    this.keyword = '',
    this.city = '',
    this.types = '',
    this.pageSize = 20,
    this.pageNum = 1,
    this.radius = 1000,
    this.sortRule = AmapAroundSortRule.distance,
  });

  final AmapLatLng center;
  final String keyword;
  final String city;
  final String types;
  final int pageSize;
  final int pageNum;
  final int radius;
  final AmapAroundSortRule sortRule;

  Map<String, Object?> toMethodArguments({AmapSearchRequestOptions? options}) {
    center.validate(name: 'center');
    _validateRadius(radius, max: 50000, name: 'radius');
    _validatePaging(pageSize: pageSize, pageNum: pageNum);
    return <String, Object?>{
      'latitude': center.latitude,
      'longitude': center.longitude,
      'radius': radius,
      'keyword': keyword.trim(),
      'city': city,
      'types': types,
      'pageSize': pageSize,
      'pageNum': pageNum,
      'sortRule': sortRule.methodValue,
      ...(options ?? const AmapSearchRequestOptions()).toMethodArguments(
        'nearby',
      ),
    };
  }
}

class AmapReverseGeocodeQuery {
  const AmapReverseGeocodeQuery({
    required this.point,
    this.radius = 300,
    this.includeExtensions = true,
  });

  final AmapLatLng point;
  final int radius;
  final bool includeExtensions;

  Map<String, Object?> toMethodArguments({AmapSearchRequestOptions? options}) {
    point.validate(name: 'point');
    _validateRadius(radius, max: 3000, name: 'radius');
    return <String, Object?>{
      'latitude': point.latitude,
      'longitude': point.longitude,
      'radius': radius,
      'includeExtensions': includeExtensions,
      ...(options ?? const AmapSearchRequestOptions()).toMethodArguments(
        'reverse',
      ),
    };
  }
}

class SearchResultItem {
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
    this.distanceMeters,
    this.sdkDistanceMeters,
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
       location = location ?? latLonPoint,
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
       _legacyDistance = distance,
       email = email ?? '',
       entryLocation = entryLocation ?? enter,
       exitLocation = exitLocation ?? exit,
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

  factory SearchResultItem.fromJson(dynamic json, {AmapLatLng? queryCenter}) {
    final map = _asMap(json);
    final location = AmapLatLng.tryParse(map['latLonPoint']);
    final sdkDistanceMeters = _nonNegativeDoubleOrNull(
      map['sdkDistanceMeters'] ?? map['distance'],
    );
    return SearchResultItem(
      id: _string(map['poiId']),
      name: _string(map['title']),
      address: _string(map['snippet']),
      location: location,
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
      sdkDistanceMeters: sdkDistanceMeters,
      distanceMeters: queryCenter == null
          ? _nonNegativeDoubleOrNull(map['distanceMeters'])
          : _distanceMeters(queryCenter, location),
      email: _string(map['email']),
      entryLocation: AmapLatLng.tryParse(map['enter']),
      exitLocation: AmapLatLng.tryParse(map['exit']),
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
  final AmapLatLng? location;
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
  final double? distanceMeters;
  final double? sdkDistanceMeters;
  final int? _legacyDistance;
  final String email;
  final AmapLatLng? entryLocation;
  final AmapLatLng? exitLocation;
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

  String get poiId => id;
  String get title => name;
  String get snippet => address;
  AmapLatLng? get latLonPoint => location;
  AmapLatLng? get enter => entryLocation;
  AmapLatLng? get exit => exitLocation;
  String get typeDes => typeDescription;
  int? get distance => sdkDistanceMeters?.round() ?? _legacyDistance;
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
      'distanceMeters': distanceMeters,
      'sdkDistanceMeters': sdkDistanceMeters ?? _legacyDistance?.toDouble(),
      'email': email,
      'enter': entryLocation?.toJson(),
      'exit': exitLocation?.toJson(),
      'isIndoorMap': isIndoorMap,
      'latLonPoint': location?.toJson(),
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

class AmapRegeocodeResult {
  const AmapRegeocodeResult({
    required this.requestedLocation,
    this.coordinateType = amapCoordinateTypeGcj02,
    this.formattedAddress = '',
    this.addressComponent,
    this.pois = const <SearchResultItem>[],
    this.aois = const <AmapAoiItem>[],
    this.roads = const <AmapRoadItem>[],
    this.roadIntersections = const <AmapRoadIntersectionItem>[],
  });

  factory AmapRegeocodeResult.fromJson(dynamic json) {
    final map = _asMap(json);
    final requestedLocation = AmapLatLng.fromJson(map['requestedLocation']);
    return AmapRegeocodeResult(
      requestedLocation: requestedLocation,
      coordinateType: _string(map['coordinateType'], amapCoordinateTypeGcj02),
      formattedAddress: _string(map['formattedAddress']),
      addressComponent: _asMapOrNull(map['addressComponent']) == null
          ? null
          : AmapAddressComponent.fromJson(map['addressComponent']),
      pois: _list(map['pois'])
          .map(
            (item) =>
                SearchResultItem.fromJson(item, queryCenter: requestedLocation),
          )
          .toList(),
      aois: _list(map['aois']).map(AmapAoiItem.fromJson).toList(),
      roads: _list(map['roads']).map(AmapRoadItem.fromJson).toList(),
      roadIntersections: _list(
        map['roadIntersections'],
      ).map(AmapRoadIntersectionItem.fromJson).toList(),
    );
  }

  final AmapLatLng requestedLocation;
  final String coordinateType;
  final String formattedAddress;
  final AmapAddressComponent? addressComponent;
  final List<SearchResultItem> pois;
  final List<AmapAoiItem> aois;
  final List<AmapRoadItem> roads;
  final List<AmapRoadIntersectionItem> roadIntersections;
}

class AmapAddressComponent {
  const AmapAddressComponent({
    this.country = '',
    this.province = '',
    this.city = '',
    this.cityCode = '',
    this.district = '',
    this.adCode = '',
    this.township = '',
    this.townCode = '',
    this.neighborhood = '',
    this.building = '',
    this.streetNumber,
  });

  factory AmapAddressComponent.fromJson(dynamic json) {
    final map = _asMap(json);
    return AmapAddressComponent(
      country: _string(map['country']),
      province: _string(map['province']),
      city: _string(map['city']),
      cityCode: _string(map['cityCode']),
      district: _string(map['district']),
      adCode: _string(map['adCode']),
      township: _string(map['township']),
      townCode: _string(map['townCode']),
      neighborhood: _string(map['neighborhood']),
      building: _string(map['building']),
      streetNumber: _asMapOrNull(map['streetNumber']) == null
          ? null
          : AmapStreetNumber.fromJson(map['streetNumber']),
    );
  }

  final String country;
  final String province;
  final String city;
  final String cityCode;
  final String district;
  final String adCode;
  final String township;
  final String townCode;
  final String neighborhood;
  final String building;
  final AmapStreetNumber? streetNumber;
}

class AmapStreetNumber {
  const AmapStreetNumber({
    this.street = '',
    this.number = '',
    this.location,
    this.sdkDistanceMeters,
    this.direction = '',
  });

  factory AmapStreetNumber.fromJson(dynamic json) {
    final map = _asMap(json);
    return AmapStreetNumber(
      street: _string(map['street']),
      number: _string(map['number']),
      location: AmapLatLng.tryParse(map['location']),
      sdkDistanceMeters: _doubleOrNull(map['sdkDistanceMeters']),
      direction: _string(map['direction']),
    );
  }

  final String street;
  final String number;
  final AmapLatLng? location;
  final double? sdkDistanceMeters;
  final String direction;
}

class AmapAoiItem {
  const AmapAoiItem({
    this.id = '',
    this.name = '',
    this.adCode = '',
    this.center,
    this.areaSquareMeters,
    this.containsPoint,
    this.distanceToBoundaryMeters,
  });

  factory AmapAoiItem.fromJson(dynamic json) {
    final map = _asMap(json);
    return AmapAoiItem(
      id: _string(map['id']),
      name: _string(map['name']),
      adCode: _string(map['adCode']),
      center: AmapLatLng.tryParse(map['center']),
      areaSquareMeters: _doubleOrNull(map['areaSquareMeters']),
      containsPoint: _nullableBool(map['containsPoint']),
      distanceToBoundaryMeters: _doubleOrNull(map['distanceToBoundaryMeters']),
    );
  }

  final String id;
  final String name;
  final String adCode;
  final AmapLatLng? center;
  final double? areaSquareMeters;
  final bool? containsPoint;
  final double? distanceToBoundaryMeters;
}

class AmapRoadItem {
  const AmapRoadItem({
    this.id = '',
    this.name = '',
    this.location,
    this.sdkDistanceMeters,
    this.direction = '',
  });

  factory AmapRoadItem.fromJson(dynamic json) {
    final map = _asMap(json);
    return AmapRoadItem(
      id: _string(map['id']),
      name: _string(map['name']),
      location: AmapLatLng.tryParse(map['location']),
      sdkDistanceMeters: _doubleOrNull(map['sdkDistanceMeters']),
      direction: _string(map['direction']),
    );
  }

  final String id;
  final String name;
  final AmapLatLng? location;
  final double? sdkDistanceMeters;
  final String direction;
}

class AmapRoadIntersectionItem {
  const AmapRoadIntersectionItem({
    this.firstRoadId = '',
    this.firstRoadName = '',
    this.secondRoadId = '',
    this.secondRoadName = '',
    this.location,
    this.sdkDistanceMeters,
    this.direction = '',
  });

  factory AmapRoadIntersectionItem.fromJson(dynamic json) {
    final map = _asMap(json);
    return AmapRoadIntersectionItem(
      firstRoadId: _string(map['firstRoadId']),
      firstRoadName: _string(map['firstRoadName']),
      secondRoadId: _string(map['secondRoadId']),
      secondRoadName: _string(map['secondRoadName']),
      location: AmapLatLng.tryParse(map['location']),
      sdkDistanceMeters: _doubleOrNull(map['sdkDistanceMeters']),
      direction: _string(map['direction']),
    );
  }

  final String firstRoadId;
  final String firstRoadName;
  final String secondRoadId;
  final String secondRoadName;
  final AmapLatLng? location;
  final double? sdkDistanceMeters;
  final String direction;
}

class PoiChild {
  const PoiChild({
    String? id,
    String? name,
    String? address,
    String? typeDescription,
    int? distance,
    this.sdkDistanceMeters,
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
       _legacyDistance = distance,
       shortName = shortName ?? subName ?? '',
       location = location ?? subLatLonPoint;

  factory PoiChild.fromJson(dynamic json) {
    final map = _asMap(json);
    return PoiChild(
      id: _string(map['poiId']),
      name: _string(map['title']),
      address: _string(map['snippet']),
      typeDescription: _string(map['subTypeDes']),
      sdkDistanceMeters: _nonNegativeDoubleOrNull(
        map['sdkDistanceMeters'] ?? map['distance'],
      ),
      shortName: _string(map['subName']),
      location: AmapLatLng.tryParse(map['subLatLonPoint']),
    );
  }

  final String id;
  final String name;
  final String address;
  final String typeDescription;
  final double? sdkDistanceMeters;
  final int? _legacyDistance;
  final String shortName;
  final AmapLatLng? location;

  String get poiId => id;
  String get title => name;
  String get snippet => address;
  String get subTypeDes => typeDescription;
  int? get distance => sdkDistanceMeters?.round() ?? _legacyDistance;
  String get subName => shortName;
  AmapLatLng? get subLatLonPoint => location;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': name,
      'snippet': address,
      'subTypeDes': typeDescription,
      'distance': distance,
      'sdkDistanceMeters': sdkDistanceMeters ?? _legacyDistance?.toDouble(),
      'poiId': id,
      'subName': shortName,
      'subLatLonPoint': location?.toJson(),
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

  Map<String, dynamic> toJson() => <String, dynamic>{'openTime': openTime};
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

typedef LatLonPoint = AmapLatLng;
typedef Enter = AmapLatLng;
typedef Exit = AmapLatLng;
typedef SubLatLonPoint = AmapLatLng;
typedef SubPois = PoiChild;
typedef PoiExtension = PoiOpeningHours;
typedef Photos = PoiPhoto;
typedef IndoorData = PoiIndoorInfo;

void _validatePaging({required int pageSize, required int pageNum}) {
  if (pageSize < 1 || pageSize > 25 || pageNum < 1) {
    throw AmapSearchException(
      code: 'invalid_argument',
      message: 'pageSize must be 1..25 and pageNum must be >= 1.',
      details: <String, Object?>{'pageSize': pageSize, 'pageNum': pageNum},
    );
  }
}

void _validateRadius(int radius, {required int max, required String name}) {
  if (radius < 1 || radius > max) {
    throw AmapSearchException(
      code: 'invalid_argument',
      message: '$name must be 1..$max meters.',
      details: <String, Object?>{name: radius},
    );
  }
}

double? _distanceMeters(AmapLatLng? from, AmapLatLng? to) {
  if (from == null || to == null) return null;
  const earthRadiusMeters = 6371008.8;
  final lat1 = _radians(from.latitude);
  final lat2 = _radians(to.latitude);
  final dLat = lat2 - lat1;
  final dLng = _radians(to.longitude - from.longitude);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _radians(double degrees) => degrees * math.pi / 180;

Map<String, dynamic> _asMap(dynamic value) {
  return _asMapOrNull(value) ?? <String, dynamic>{};
}

Map<String, dynamic>? _asMapOrNull(dynamic value) {
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

List<dynamic> _list(dynamic value) => value is List ? value : <dynamic>[];

String _string(dynamic value, [String defaultValue = '']) {
  return value?.toString() ?? defaultValue;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _doubleOrNull(dynamic value) {
  if (value is num) {
    final number = value.toDouble();
    return number.isFinite ? number : null;
  }
  final parsed = double.tryParse(value?.toString() ?? '');
  return parsed != null && parsed.isFinite ? parsed : null;
}

double? _nonNegativeDoubleOrNull(dynamic value) {
  final number = _doubleOrNull(value);
  return number != null && number >= 0 ? number : null;
}

bool _bool(dynamic value) => _nullableBool(value) ?? false;

bool? _nullableBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return null;
}

bool _validLatitude(double? value) {
  return value != null && value.isFinite && value >= -90 && value <= 90;
}

bool _validLongitude(double? value) {
  return value != null && value.isFinite && value >= -180 && value <= 180;
}
