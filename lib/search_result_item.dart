class SearchResultItem {
  SearchResultItem({
    required this.adCode,
    required this.adName,
    required this.cityName,
    required this.cityCode,
    required this.indoorData,
    required this.businessArea,
    required this.direction,
    required this.distance,
    required this.email,
    required this.enter,
    required this.exit,
    required this.isIndoorMap,
    required this.latLonPoint,
    required this.parkingType,
    required this.photos,
    required this.poiExtension,
    required this.poiId,
    required this.postcode,
    required this.provinceCode,
    required this.provinceName,
    required this.shopID,
    required this.snippet,
    required this.subPois,
    required this.tel,
    required this.title,
    required this.typeCode,
    required this.typeDes,
    required this.website,
  });

  factory SearchResultItem.fromJson(dynamic json) {
    final map = _asMap(json);
    return SearchResultItem(
      adCode: _string(map['adCode']),
      adName: _string(map['adName']),
      cityName: _string(map['cityName']),
      cityCode: _string(map['cityCode']),
      indoorData: IndoorData.fromJson(map['indoorData']),
      businessArea: _string(map['businessArea']),
      direction: _string(map['direction']),
      distance: _int(map['distance']),
      email: _string(map['email']),
      enter: Enter.fromJson(map['enter']),
      exit: Exit.fromJson(map['exit']),
      isIndoorMap: _bool(map['isIndoorMap']),
      latLonPoint: LatLonPoint.fromJson(map['latLonPoint']),
      parkingType: _string(map['parkingType']),
      photos: _list(map['photos']).map(Photos.fromJson).toList(),
      poiExtension: PoiExtension.fromJson(map['poiExtension']),
      poiId: _string(map['poiId']),
      postcode: _string(map['postcode']),
      provinceCode: _string(map['provinceCode']),
      provinceName: _string(map['provinceName']),
      shopID: _string(map['shopID']),
      snippet: _string(map['snippet']),
      subPois: _list(map['subPois']).map(SubPois.fromJson).toList(),
      tel: _string(map['tel']),
      title: _string(map['title']),
      typeCode: _string(map['typeCode']),
      typeDes: _string(map['typeDes']),
      website: _string(map['website']),
    );
  }

  final String adCode;
  final String adName;
  final String cityName;
  final String cityCode;
  final IndoorData indoorData;
  final String businessArea;
  final String direction;
  final int distance;
  final String email;
  final Enter enter;
  final Exit exit;
  final bool isIndoorMap;
  final LatLonPoint latLonPoint;
  final String parkingType;
  final List<Photos> photos;
  final PoiExtension poiExtension;
  final String poiId;
  final String postcode;
  final String provinceCode;
  final String provinceName;
  final String shopID;
  final String snippet;
  final List<SubPois> subPois;
  final String tel;
  final String title;
  final String typeCode;
  final String typeDes;
  final String website;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'adCode': adCode,
      'adName': adName,
      'cityName': cityName,
      'cityCode': cityCode,
      'indoorData': indoorData.toJson(),
      'businessArea': businessArea,
      'direction': direction,
      'distance': distance,
      'email': email,
      'enter': enter.toJson(),
      'exit': exit.toJson(),
      'isIndoorMap': isIndoorMap,
      'latLonPoint': latLonPoint.toJson(),
      'parkingType': parkingType,
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'poiExtension': poiExtension.toJson(),
      'poiId': poiId,
      'postcode': postcode,
      'provinceCode': provinceCode,
      'provinceName': provinceName,
      'shopID': shopID,
      'snippet': snippet,
      'subPois': subPois.map((subPoi) => subPoi.toJson()).toList(),
      'tel': tel,
      'title': title,
      'typeCode': typeCode,
      'typeDes': typeDes,
      'website': website,
    };
  }
}

class SubPois {
  SubPois({
    required this.title,
    required this.snippet,
    required this.subTypeDes,
    required this.distance,
    required this.poiId,
    required this.subName,
    required this.subLatLonPoint,
  });

  factory SubPois.fromJson(dynamic json) {
    final map = _asMap(json);
    return SubPois(
      title: _string(map['title']),
      snippet: _string(map['snippet']),
      subTypeDes: _string(map['subTypeDes']),
      distance: _int(map['distance']),
      poiId: _string(map['poiId']),
      subName: _string(map['subName']),
      subLatLonPoint: SubLatLonPoint.fromJson(map['subLatLonPoint']),
    );
  }

  final String title;
  final String snippet;
  final String subTypeDes;
  final int distance;
  final String poiId;
  final String subName;
  final SubLatLonPoint subLatLonPoint;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'snippet': snippet,
      'subTypeDes': subTypeDes,
      'distance': distance,
      'poiId': poiId,
      'subName': subName,
      'subLatLonPoint': subLatLonPoint.toJson(),
    };
  }
}

class SubLatLonPoint {
  SubLatLonPoint({required this.latitude, required this.longitude});

  factory SubLatLonPoint.fromJson(dynamic json) {
    final map = _asMap(json);
    return SubLatLonPoint(
      latitude: _double(map['latitude']),
      longitude: _double(map['longitude']),
    );
  }

  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'latitude': latitude, 'longitude': longitude};
  }
}

class PoiExtension {
  PoiExtension({required this.openTime});

  factory PoiExtension.fromJson(dynamic json) {
    final map = _asMap(json);
    return PoiExtension(openTime: _string(map['openTime']));
  }

  final String openTime;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'openTime': openTime};
  }
}

class Photos {
  Photos({required this.title, required this.url});

  factory Photos.fromJson(dynamic json) {
    final map = _asMap(json);
    return Photos(title: _string(map['title']), url: _string(map['url']));
  }

  final String title;
  final String url;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'title': title, 'url': url};
  }
}

class LatLonPoint {
  LatLonPoint({required this.latitude, required this.longitude});

  factory LatLonPoint.fromJson(dynamic json) {
    final map = _asMap(json);
    return LatLonPoint(
      latitude: _double(map['latitude']),
      longitude: _double(map['longitude']),
    );
  }

  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'latitude': latitude, 'longitude': longitude};
  }
}

class Exit {
  Exit({required this.latitude, required this.longitude});

  factory Exit.fromJson(dynamic json) {
    final map = _asMap(json);
    return Exit(
      latitude: _double(map['latitude']),
      longitude: _double(map['longitude']),
    );
  }

  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'latitude': latitude, 'longitude': longitude};
  }
}

class Enter {
  Enter({required this.latitude, required this.longitude});

  factory Enter.fromJson(dynamic json) {
    final map = _asMap(json);
    return Enter(
      latitude: _double(map['latitude']),
      longitude: _double(map['longitude']),
    );
  }

  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'latitude': latitude, 'longitude': longitude};
  }
}

class IndoorData {
  IndoorData({
    required this.floor,
    required this.floorName,
    required this.poiId,
  });

  factory IndoorData.fromJson(dynamic json) {
    final map = _asMap(json);
    return IndoorData(
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
