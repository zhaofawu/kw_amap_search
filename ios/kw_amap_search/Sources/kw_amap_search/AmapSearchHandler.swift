#if canImport(AMapSearchKit) && canImport(AMapFoundationKit)
import AMapFoundationKit
import AMapSearchKit
import Flutter
import UIKit

final class AmapSearchHandler: NSObject, KwAmapSearchHandling, AMapSearchDelegate {
  private var search: AMapSearchAPI?
  private var pendingByObject: [ObjectIdentifier: PendingRequest] = [:]
  private var pendingById: [String: PendingRequest] = [:]
  private var privacyContains = false
  private var privacyShown = false
  private var privacyAgreed = false

  func setApiKey(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(invalidArguments("setApiKey requires a map argument."))
      return
    }
    if let key = arguments["iosKey"] as? String, !key.isEmpty {
      AMapServices.shared().apiKey = key
    }
    result(nil)
  }

  func updatePrivacyShow(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(invalidArguments("updatePrivacyShow requires a map argument."))
      return
    }
    privacyContains = arguments["hasContains"] as? Bool ?? false
    privacyShown = arguments["hasShow"] as? Bool ?? false
    result(nil)
  }

  func updatePrivacyAgree(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(invalidArguments("updatePrivacyAgree requires a map argument."))
      return
    }

    privacyAgreed = arguments["hasAgree"] as? Bool ?? false
    AMapServices.shared().securityAgree = privacyAgreed
    AMapServices.shared().analysisAgree = privacyAgreed
    result(nil)
  }

  func searchKeyword(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(invalidArguments("searchKeyword requires a map argument."))
      return
    }
    guard let search = ensureSearch(result: result) else { return }
    let keyword = string(arguments, "keyword").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !keyword.isEmpty else {
      result(invalidArguments("keyword must not be empty."))
      return
    }
    guard validPaging(arguments, result: result) else { return }

    let request = AMapPOIKeywordsSearchRequest()
    request.keywords = keyword
    request.city = string(arguments, "city")
    request.types = string(arguments, "types")
    request.offset = int(arguments, "pageSize", defaultValue: 20)
    request.page = int(arguments, "pageNum", defaultValue: 1)
    request.showFieldsType = AMapPOISearchShowFieldsType(rawValue: UInt.max)

    guard register(request, arguments: arguments, operation: "searchKeyword", result: result) != nil else {
      return
    }
    search.aMapPOIKeywordsSearch(request)
  }

  func searchAround(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(invalidArguments("searchAround requires a map argument."))
      return
    }
    guard let search = ensureSearch(result: result) else { return }
    guard let latitude = validLatitude(arguments["latitude"]),
      let longitude = validLongitude(arguments["longitude"])
    else {
      result(invalidArguments("center must be finite latitude/longitude."))
      return
    }
    let radius = int(arguments, "radius", defaultValue: 1000)
    guard radius >= 1 && radius <= 50000 else {
      result(invalidArguments("radius must be 1..50000 meters."))
      return
    }
    guard validPaging(arguments, result: result) else { return }

    let request = AMapPOIAroundSearchRequest()
    request.keywords = string(arguments, "keyword").trimmingCharacters(in: .whitespacesAndNewlines)
    request.city = string(arguments, "city")
    request.types = string(arguments, "types")
    request.offset = int(arguments, "pageSize", defaultValue: 20)
    request.page = int(arguments, "pageNum", defaultValue: 1)
    request.radius = radius
    request.location = AMapGeoPoint.location(
      withLatitude: CGFloat(latitude),
      longitude: CGFloat(longitude)
    )
    request.sortrule = string(arguments, "sortRule") == "comprehensive" ? 1 : 0
    request.showFieldsType = AMapPOISearchShowFieldsType(rawValue: UInt.max)

    guard register(request, arguments: arguments, operation: "searchAround", result: result) != nil else {
      return
    }
    search.aMapPOIAroundSearch(request)
  }

  func reverseGeocode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(invalidArguments("reverseGeocode requires a map argument."))
      return
    }
    guard let search = ensureSearch(result: result) else { return }
    guard let latitude = validLatitude(arguments["latitude"]),
      let longitude = validLongitude(arguments["longitude"])
    else {
      result(invalidArguments("point must be finite latitude/longitude."))
      return
    }
    let radius = int(arguments, "radius", defaultValue: 300)
    guard radius >= 1 && radius <= 3000 else {
      result(invalidArguments("radius must be 1..3000 meters."))
      return
    }

    let request = AMapReGeocodeSearchRequest()
    request.location = AMapGeoPoint.location(
      withLatitude: CGFloat(latitude),
      longitude: CGFloat(longitude)
    )
    request.radius = radius
    request.requireExtension = bool(arguments, "includeExtensions", defaultValue: true)

    guard
      register(request, arguments: arguments, operation: "reverseGeocode", result: result) != nil
    else {
      return
    }
    search.aMapReGoecodeSearch(request)
  }

  func cancelRequest(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(invalidArguments("cancelRequest requires a map argument."))
      return
    }
    let requestId = string(arguments, "requestId").trimmingCharacters(in: .whitespacesAndNewlines)
    guard let pending = pendingById[requestId] else {
      result(false)
      return
    }
    complete(
      pending,
      value: FlutterError(
        code: "cancelled",
        message: "AMap search request was cancelled.",
        details: ["requestId": pending.requestId, "operation": pending.operation]
      )
    )
    result(true)
  }

  func dispose() {
    let requests = Array(pendingById.values)
    for request in requests {
      complete(
        request,
        value: FlutterError(
          code: "cancelled",
          message: "AMap search handler was disposed.",
          details: ["requestId": request.requestId, "operation": request.operation]
        )
      )
    }
    search?.delegate = nil
    search = nil
  }

  func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
    guard let pending = pending(for: request) else { return }
    complete(pending, value: AmapPoiMapper.toChannelList(
      response?.pois ?? [], includeDistance: pending.operation != "searchKeyword"
    ))
  }

  func onReGeocodeSearchDone(
    _ request: AMapReGeocodeSearchRequest!,
    response: AMapReGeocodeSearchResponse!
  ) {
    guard let pending = pending(for: request) else { return }
    let point = request.location
    complete(
      pending,
      value: [
        "requestedLocation": AmapPoiMapper.pointMap(point),
        "coordinateType": "gcj02",
        "formattedAddress": string(response?.regeocode?.formattedAddress),
        "addressComponent": addressComponentMap(response?.regeocode?.addressComponent),
        "pois": AmapPoiMapper.toChannelList(response?.regeocode?.pois ?? []),
        "aois": (response?.regeocode?.aois ?? []).map(aoiMap),
        "roads": (response?.regeocode?.roads ?? []).map(roadMap),
        "roadIntersections": (response?.regeocode?.roadinters ?? []).map(roadInterMap)
      ] as [String: Any?]
    )
  }

  func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
    guard let requestObject = request as AnyObject?, let pending = pending(for: requestObject) else {
      return
    }

    let nsError = error as NSError? ?? NSError(domain: "AMapSearch", code: -1)
    complete(
      pending,
      value: FlutterError(
        code: "sdk_error",
        message: nsError.localizedDescription,
        details: [
          "nativeCode": nsError.code,
          "domain": nsError.domain,
          "requestId": pending.requestId,
          "operation": pending.operation,
          "platform": "ios"
        ]
      )
    )
  }

  private func ensureSearch(result: @escaping FlutterResult) -> AMapSearchAPI? {
    guard privacyContains && privacyShown && privacyAgreed else {
      result(
        FlutterError(
          code: "privacy_not_agreed",
          message: "AMap privacy status must be shown and agreed before search.",
          details: ["platform": "ios"]
        )
      )
      return nil
    }
    if search == nil {
      search = AMapSearchAPI()
      search?.delegate = self
    }
    return search
  }

  private func register(
    _ request: AnyObject,
    arguments: [String: Any],
    operation: String,
    result: @escaping FlutterResult
  ) -> PendingRequest? {
    let requestId = string(arguments, "requestId").trimmingCharacters(in: .whitespacesAndNewlines)
    let id = requestId.isEmpty ? "ios-\(UUID().uuidString)" : requestId
    guard pendingById[id] == nil else {
      result(
        FlutterError(
          code: "duplicate_request_id",
          message: "AMap requestId is already active.",
          details: ["requestId": id, "operation": operation]
        )
      )
      return nil
    }

    let timeoutMs = int(arguments, "timeoutMs", defaultValue: 10_000)
    guard timeoutMs > 0 else {
      result(invalidArguments("timeoutMs must be positive."))
      return nil
    }

    let pending = PendingRequest(
      requestId: id,
      operation: operation,
      objectId: ObjectIdentifier(request),
      result: result
    )
    pending.timer = Timer.scheduledTimer(withTimeInterval: Double(timeoutMs) / 1000, repeats: false) {
      [weak self, weak pending] _ in
      guard let self = self, let pending = pending else { return }
      self.complete(
        pending,
        value: FlutterError(
          code: "timeout",
          message: "AMap search request timed out.",
          details: ["requestId": pending.requestId, "operation": pending.operation]
        )
      )
    }
    pendingById[id] = pending
    pendingByObject[pending.objectId] = pending
    return pending
  }

  private func pending(for request: AnyObject?) -> PendingRequest? {
    guard let request = request else { return nil }
    return pendingByObject[ObjectIdentifier(request)]
  }

  private func complete(_ pending: PendingRequest, value: Any?) {
    guard pendingByObject.removeValue(forKey: pending.objectId) != nil else { return }
    pendingById.removeValue(forKey: pending.requestId)
    pending.timer?.invalidate()
    pending.result(value)
  }

  private func validPaging(_ arguments: [String: Any], result: @escaping FlutterResult) -> Bool {
    let pageSize = int(arguments, "pageSize", defaultValue: 20)
    let pageNum = int(arguments, "pageNum", defaultValue: 1)
    guard pageSize >= 1 && pageSize <= 25 && pageNum >= 1 else {
      result(invalidArguments("pageSize must be 1..25 and pageNum must be >= 1."))
      return false
    }
    return true
  }

  private func addressComponentMap(_ component: AMapAddressComponent?) -> [String: Any?]? {
    guard let component = component else { return nil }
    return [
      "country": string(component.country),
      "province": string(component.province),
      "city": string(component.city),
      "cityCode": string(component.citycode),
      "district": string(component.district),
      "adCode": string(component.adcode),
      "township": string(component.township),
      "townCode": string(component.towncode),
      "neighborhood": string(component.neighborhood),
      "building": string(component.building),
      "streetNumber": streetNumberMap(component.streetNumber)
    ]
  }

  private func streetNumberMap(_ streetNumber: AMapStreetNumber?) -> [String: Any?]? {
    guard let streetNumber = streetNumber else { return nil }
    return [
      "street": string(streetNumber.street),
      "number": string(streetNumber.number),
      "location": AmapPoiMapper.pointMap(streetNumber.location),
      "sdkDistanceMeters": Double(streetNumber.distance),
      "direction": string(streetNumber.direction)
    ]
  }

  private func aoiMap(_ aoi: AMapAOI) -> [String: Any?] {
    [
      "id": string(aoi.uid),
      "name": string(aoi.name),
      "adCode": string(aoi.adcode),
      "center": AmapPoiMapper.pointMap(aoi.location),
      "areaSquareMeters": Double(aoi.area),
      "containsPoint": nil,
      "distanceToBoundaryMeters": nil
    ]
  }

  private func roadMap(_ road: AMapRoad) -> [String: Any?] {
    [
      "id": string(road.uid),
      "name": string(road.name),
      "location": AmapPoiMapper.pointMap(road.location),
      "sdkDistanceMeters": Double(road.distance),
      "direction": string(road.direction)
    ]
  }

  private func roadInterMap(_ roadInter: AMapRoadInter) -> [String: Any?] {
    [
      "firstRoadId": string(roadInter.firstId),
      "firstRoadName": string(roadInter.firstName),
      "secondRoadId": string(roadInter.secondId),
      "secondRoadName": string(roadInter.secondName),
      "location": AmapPoiMapper.pointMap(roadInter.location),
      "sdkDistanceMeters": Double(roadInter.distance),
      "direction": string(roadInter.direction)
    ]
  }

  private func invalidArguments(_ message: String) -> FlutterError {
    FlutterError(code: "invalid_argument", message: message, details: nil)
  }

  private func string(_ arguments: [String: Any], _ key: String) -> String {
    arguments[key] as? String ?? ""
  }

  private func string(_ value: String?) -> String {
    value ?? ""
  }

  private func int(_ arguments: [String: Any], _ key: String, defaultValue: Int) -> Int {
    if let value = arguments[key] as? Int {
      return value
    }
    if let value = arguments[key] as? NSNumber {
      return value.intValue
    }
    return defaultValue
  }

  private func bool(_ arguments: [String: Any], _ key: String, defaultValue: Bool) -> Bool {
    if let value = arguments[key] as? Bool {
      return value
    }
    if let value = arguments[key] as? NSNumber {
      return value.boolValue
    }
    return defaultValue
  }

  private func validLatitude(_ value: Any?) -> Double? {
    let number = double(value)
    guard let number = number, number.isFinite, number >= -90, number <= 90 else {
      return nil
    }
    return number
  }

  private func validLongitude(_ value: Any?) -> Double? {
    let number = double(value)
    guard let number = number, number.isFinite, number >= -180, number <= 180 else {
      return nil
    }
    return number
  }

  private func double(_ value: Any?) -> Double? {
    if let value = value as? Double {
      return value
    }
    if let value = value as? NSNumber {
      return value.doubleValue
    }
    return nil
  }
}

private final class PendingRequest {
  let requestId: String
  let operation: String
  let objectId: ObjectIdentifier
  let result: FlutterResult
  var timer: Timer?

  init(
    requestId: String,
    operation: String,
    objectId: ObjectIdentifier,
    result: @escaping FlutterResult
  ) {
    self.requestId = requestId
    self.operation = operation
    self.objectId = objectId
    self.result = result
  }
}
#endif
