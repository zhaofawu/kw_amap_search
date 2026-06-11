#if canImport(AMapSearchKit) && canImport(AMapFoundationKit)
import AMapFoundationKit
import AMapSearchKit
import Flutter
import UIKit

final class AmapSearchHandler: NSObject, KwAmapSearchHandling, AMapSearchDelegate {
  private let search: AMapSearchAPI = AMapSearchAPI()
  private var pendingResults: [ObjectIdentifier: FlutterResult] = [:]
  private var privacyContains = false
  private var privacyShown = false

  override init() {
    super.init()
    search.delegate = self
  }

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

    // The iOS Search/Foundation headers expose privacy status enums but not the
    // Android-style static update method. We keep this method as a first-class
    // no-op state update so Flutter code can call the same compliance sequence
    // on both platforms before starting any search.
    privacyContains = arguments["hasContains"] as? Bool ?? false
    privacyShown = arguments["hasShow"] as? Bool ?? false
    result(nil)
  }

  func updatePrivacyAgree(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(invalidArguments("updatePrivacyAgree requires a map argument."))
      return
    }

    let hasAgree = arguments["hasAgree"] as? Bool ?? false
    AMapServices.shared().securityAgree = hasAgree
    AMapServices.shared().analysisAgree = hasAgree
    result(nil)
  }

  func searchKeyword(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(invalidArguments("searchKeyword requires a map argument."))
      return
    }

    let request = AMapPOIKeywordsSearchRequest()
    request.keywords = string(arguments, "keyword")
    request.city = string(arguments, "city")
    request.types = string(arguments, "types")
    request.offset = int(arguments, "pageSize", defaultValue: 20)
    request.page = int(arguments, "pageNum", defaultValue: 1)
    request.showFieldsType = AMapPOISearchShowFieldsType(rawValue: UInt.max)

    pendingResults[ObjectIdentifier(request)] = result
    search.aMapPOIKeywordsSearch(request)
  }

  func searchAround(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(invalidArguments("searchAround requires a map argument."))
      return
    }

    let latitude = double(arguments, "latitude", defaultValue: 0)
    let longitude = double(arguments, "longitude", defaultValue: 0)
    let radius = int(arguments, "radius", defaultValue: 1000)

    // Match the old Android implementation: placeholder coordinates mean the
    // caller has no usable center point yet, so return an empty result instead
    // of sending an invalid around-search request to the native SDK.
    if latitude == 0 || longitude == 0 {
      result([])
      return
    }

    let request = AMapPOIAroundSearchRequest()
    request.keywords = string(arguments, "keyword")
    request.city = string(arguments, "city")
    request.types = string(arguments, "types")
    request.offset = int(arguments, "pageSize", defaultValue: 20)
    request.page = int(arguments, "pageNum", defaultValue: 1)
    request.radius = min(max(radius, 1), 50000)
    request.location = AMapGeoPoint.location(
      withLatitude: CGFloat(latitude),
      longitude: CGFloat(longitude)
    )
    request.showFieldsType = AMapPOISearchShowFieldsType(rawValue: UInt.max)

    pendingResults[ObjectIdentifier(request)] = result
    search.aMapPOIAroundSearch(request)
  }

  func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
    guard let request = request else { return }
    let key = ObjectIdentifier(request)
    guard let result = pendingResults.removeValue(forKey: key) else { return }
    result(AmapPoiMapper.toChannelList(response?.pois ?? []))
  }

  func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
    guard let requestObject = request as AnyObject? else { return }
    let key = ObjectIdentifier(requestObject)
    guard let result = pendingResults.removeValue(forKey: key) else { return }

    let nsError = error as NSError? ?? NSError(domain: "AMapSearch", code: -1)
    result(
      FlutterError(
        code: "AMAP_SEARCH_ERROR",
        message: nsError.localizedDescription,
        details: [
          "errorCode": nsError.code,
          "domain": nsError.domain
        ]
      )
    )
  }

  private func invalidArguments(_ message: String) -> FlutterError {
    FlutterError(code: "AMAP_INVALID_ARGUMENTS", message: message, details: nil)
  }

  private func string(_ arguments: [String: Any], _ key: String) -> String {
    arguments[key] as? String ?? ""
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

  private func double(_ arguments: [String: Any], _ key: String, defaultValue: Double) -> Double {
    if let value = arguments[key] as? Double {
      return value
    }
    if let value = arguments[key] as? NSNumber {
      return value.doubleValue
    }
    return defaultValue
  }
}
#endif
