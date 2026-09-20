import Flutter
import UIKit
import XCTest
import AMapSearchKit

// If your plugin has been explicitly set to "type: .dynamic" in the Package.swift,
// you will need to add your plugin as a dependency of RunnerTests within Xcode.

@testable import kw_amap_search

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testPrivacyConsentAllowsSearchSDKInitialization() {
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
    XCTAssertNotNil(AMapSearchAPI())
  }

  func testSearchInitializationFailureCompletesImmediately() {
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

    // Reproduce SDK initialization refusal while the plugin's local flags are set.
    AMapSearchAPI.updatePrivacyAgree(.notAgree)
    defer { AMapSearchAPI.updatePrivacyAgree(.didAgree) }
    let completed = expectation(description: "SDK initialization failure is reported")
    plugin.handle(FlutterMethodCall(methodName: "reverseGeocode", arguments: [
      "latitude": 22.85687178770656, "longitude": 108.28107380400866
    ])) { result in
      XCTAssertEqual((result as? FlutterError)?.code, "not_initialized")
      completed.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testGetPlatformVersion() {
    let plugin = KwAmapSearchPlugin()

    let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! String, "iOS " + UIDevice.current.systemVersion)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
