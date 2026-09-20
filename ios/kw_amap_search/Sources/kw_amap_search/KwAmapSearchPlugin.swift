import Flutter
import UIKit

public class KwAmapSearchPlugin: NSObject, FlutterPlugin {
  private let handler: KwAmapSearchHandling

  public override init() {
    #if canImport(AMapSearchKit) && canImport(AMapFoundationKit)
      self.handler = AmapSearchHandler()
    #else
      self.handler = MissingAmapSearchHandler()
    #endif
    super.init()
  }

  deinit {
    handler.dispose()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "kw_amap_search",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(KwAmapSearchPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "setApiKey":
      handler.setApiKey(call, result: result)
    case "updatePrivacyShow":
      handler.updatePrivacyShow(call, result: result)
    case "updatePrivacyAgree":
      handler.updatePrivacyAgree(call, result: result)
    case "searchKeyword":
      handler.searchKeyword(call, result: result)
    case "searchAround":
      handler.searchAround(call, result: result)
    case "reverseGeocode":
      handler.reverseGeocode(call, result: result)
    case "cancelRequest":
      handler.cancelRequest(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

protocol KwAmapSearchHandling {
  func setApiKey(_ call: FlutterMethodCall, result: @escaping FlutterResult)
  func updatePrivacyShow(_ call: FlutterMethodCall, result: @escaping FlutterResult)
  func updatePrivacyAgree(_ call: FlutterMethodCall, result: @escaping FlutterResult)
  func searchKeyword(_ call: FlutterMethodCall, result: @escaping FlutterResult)
  func searchAround(_ call: FlutterMethodCall, result: @escaping FlutterResult)
  func reverseGeocode(_ call: FlutterMethodCall, result: @escaping FlutterResult)
  func cancelRequest(_ call: FlutterMethodCall, result: @escaping FlutterResult)
  func dispose()
}

private final class MissingAmapSearchHandler: KwAmapSearchHandling {
  private let error = FlutterError(
    code: "sdk_unavailable",
    message: "AMapSearchKit and AMapFoundationKit are required on iOS.",
    details: ["platform": "ios"]
  )

  func setApiKey(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(error)
  }

  func updatePrivacyShow(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(error)
  }

  func updatePrivacyAgree(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(error)
  }

  func searchKeyword(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(error)
  }

  func searchAround(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(error)
  }

  func reverseGeocode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(error)
  }

  func cancelRequest(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(error)
  }

  func dispose() {}
}
