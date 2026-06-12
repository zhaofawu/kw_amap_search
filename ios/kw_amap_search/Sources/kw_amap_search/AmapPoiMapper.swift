#if canImport(AMapSearchKit)
import AMapSearchKit
import UIKit

enum AmapPoiMapper {
  static func toChannelList(_ pois: [AMapPOI]) -> [[String: Any]] {
    pois.map(toChannelMap)
  }

  /// Returns the same payload shape as Android's mapper.
  ///
  /// AMap's iOS SDK uses names like `uid`, `name`, `address`, and `typecode`;
  /// Android uses `poiId`, `title`, `snippet`, and `typeCode`. The Flutter
  /// channel keeps the Android-origin schema so Dart receives one stable shape.
  private static func toChannelMap(_ poi: AMapPOI) -> [String: Any] {
    [
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
      "distance": Int(poi.distance),
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
      "subPois": (poi.subPOIs ?? []).map { child in
        [
          "title": string(child.name),
          "snippet": string(child.address),
          "subTypeDes": string(child.subtype),
          "distance": child.distance,
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

  private static func pointMap(_ point: AMapGeoPoint?) -> [String: Double] {
    [
      "latitude": Double(point?.latitude ?? 0),
      "longitude": Double(point?.longitude ?? 0)
    ]
  }

  private static func string(_ value: String?) -> String {
    value ?? ""
  }
}
#endif
