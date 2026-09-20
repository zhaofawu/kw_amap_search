import Flutter
import UIKit
#if DEBUG
import AMapSearchKit
import AMapFoundationKit
import kw_amap_search
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    #if DEBUG
    FlutterMethodChannel(
      name: "kw_amap_search_example/native_tests",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    ).setMethodCallHandler { call, result in
      guard call.method == "privacyInitialization",
            let consent = call.arguments as? Bool, consent else {
        result(FlutterMethodNotImplemented)
        return
      }
      // Test-only entry point: no query is sent and the host Key is restored.
      let previousKey = AMapServices.shared().apiKey
      defer {
        AMapServices.shared().apiKey = previousKey
        AMapSearchAPI.updatePrivacyAgree(.didAgree)
      }
      AMapSearchAPI.updatePrivacyShow(.notShow, privacyInfo: .notContain)
      AMapSearchAPI.updatePrivacyAgree(.notAgree)
      let plugin = KwAmapSearchPlugin()
      plugin.handle(FlutterMethodCall(methodName: "setApiKey", arguments: [
        "iosKey": "00000000000000000000000000000000"
      ])) { _ in }
      plugin.handle(FlutterMethodCall(methodName: "updatePrivacyShow", arguments: [
        "hasContains": true, "hasShow": true
      ])) { _ in }
      plugin.handle(FlutterMethodCall(methodName: "updatePrivacyAgree", arguments: [
        "hasAgree": true
      ])) { _ in }
      let initialized = AMapSearchAPI() != nil
      AMapSearchAPI.updatePrivacyAgree(.notAgree)
      var failureCode: String?
      plugin.handle(FlutterMethodCall(methodName: "reverseGeocode", arguments: [
        "latitude": 22.85687178770656, "longitude": 108.28107380400866
      ])) { response in failureCode = (response as? FlutterError)?.code }
      result(["initialized": initialized, "failureCode": failureCode ?? "not_completed"])
    }
    #endif
  }
}
