#if canImport(AMapSearchKit)
import AMapSearchKit
import UIKit

enum AmapPoiMapper {
  static func toChannelList(_ pois: [AMapPOI], includeDistance: Bool = true) -> [[String: Any?]] {
    pois.map { toChannelMap($0, includeDistance: includeDistance) }
  }

  /// Returns the same payload shape as Android's mapper.
  ///
  /// AMap's iOS SDK uses names like `uid`, `name`, `address`, and `typecode`;
  /// Android uses `poiId`, `title`, `snippet`, and `typeCode`. The Flutter
  /// channel keeps the Android-origin schema so Dart receives one stable shape.
  private static func toChannelMap(_ poi: AMapPOI, includeDistance: Bool) -> [String: Any?] {
    let distance = includeDistance && poi.distance >= 0 ? Double(poi.distance) : nil
    return [
      "adCode": string(poi.adcode),
      "adName": string(poi.district),
      "cityName": string(poi.city),
      "cityCode": string(poi.citycode),
      "indoorData": [
        "floor": poi.indoorData?.floor ?? 0,
        "floorName": string(poi.indoorData?.floorName),
        "poiId": string(poi.indoorData?.pid)
      ],
      "businessArea": string(poi.businessData?.businessArea ?? poi.businessArea),
      "direction": string(poi.direction),
      "distance": distance,
      "sdkDistanceMeters": distance,
      "email": string(poi.email),
      "enter": pointMap(poi.enterLocation),
      "exit": pointMap(poi.exitLocation),
      "isIndoorMap": poi.hasIndoorMap,
      "latLonPoint": pointMap(poi.location),
      "parkingType": string(poi.businessData?.parkingType ?? poi.parkingType),
      "photos": (poi.images ?? []).map { image in
        [
          "title": string(image.title),
          "url": string(image.url)
        ]
      },
      "poiExtension": [
        "openTime": string(
          poi.extensionInfo?.openTime
            ?? poi.businessData?.opentimeToday
            ?? poi.businessData?.opentimeWeek
        )
      ],
      "poiId": string(poi.uid),
      "postcode": string(poi.postcode),
      "provinceCode": string(poi.pcode),
      "provinceName": string(poi.province),
      "shopID": string(poi.shopID),
      "snippet": string(poi.address),
      "subPois": (poi.subPOIs ?? []).map { child -> [String: Any?] in
        [
          "title": string(child.name),
          "snippet": string(child.address),
          "subTypeDes": string(child.subtype),
          "distance": child.distance >= 0 ? Double(child.distance) : nil,
          "sdkDistanceMeters": child.distance >= 0 ? Double(child.distance) : nil,
          "poiId": string(child.uid),
          "subName": string(child.sname),
          "subLatLonPoint": pointMap(child.location)
        ]
      },
      "tel": string(poi.businessData?.tel ?? poi.tel),
      "title": string(poi.name),
      "typeCode": string(poi.typecode),
      "typeDes": string(poi.type),
      "website": string(poi.website)
    ]
  }

  static func pointMap(_ point: AMapGeoPoint?) -> [String: Double]? {
    guard let point = point else {
      return nil
    }
    return [
      "latitude": Double(point.latitude),
      "longitude": Double(point.longitude)
    ]
  }

  private static func string(_ value: String?) -> String {
    value ?? ""
  }
}
#endif
