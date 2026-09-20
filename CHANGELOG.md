## 0.1.0

* Fixed iOS searches timing out because Search SDK privacy status was not forwarded; report SDK initialization failure immediately.
* Added example paging, sorting, extension and timeout controls, masked Key fields, request parameters and reverse-geocode collection details.
* Documented unified Android SDK and iOS NO-IDFA dependencies for map/location/search coexistence.
* Added real-device SDK integration coverage and Android/iOS query evidence, including privacy refusal, invalid Key, paging, concurrency, cancellation, and timeout; network scenarios are tracked separately in the release report.
* Fixed late Android callbacks removing a newer request with a reused ID; release listeners and timers on completion.
* Fixed Dart timeout cleanup blocking or masking the original timeout error.
* Preserved POI distances through JSON round trips and normalized negative SDK distance sentinels to null.
* Removed the incomplete Swift Package manifest and integrated the iOS example through CocoaPods with the actual AMap SDKs.
* Added independent example request results, per-request cancellation, explicit privacy consent, and regression coverage.

* Added reverse geocoding with structured address, POI, AOI, road, and road-intersection models.
* Added `AmapSearchRequestOptions`, request IDs, default 10-second timeout, and `cancelRequest`.
* Added `AmapAroundSortRule` and native distance-sort mapping for nearby search.
* Changed POI coordinates and distance-like fields to nullable values instead of fake `(0,0)` / `0` defaults.
* Added Dart-side straight-line `distanceMeters` and preserved SDK raw distance as `sdkDistanceMeters`.
* Added validation for coordinates, radius, paging, keyword, and timeout; invalid input now throws `invalid_argument`.
* Updated the example app to demonstrate keyword search, nearby search, reverse geocoding, concurrent requests, and cancellation.
* Breaking change: callers must handle nullable POI coordinates and migrate business distance usage from `distance` to `distanceMeters`.

## 0.0.3

* Changed the Android AMap Search SDK dependency to `compileOnly`; host apps now explicitly provide `com.amap.api:search`.
* Added the AMap Search SDK dependency to the example Android app.

## 0.0.2

* Migrated the Android plugin build to AGP Built-in Kotlin on AGP 9+ to remove Flutter's Kotlin Gradle Plugin warning.

## 0.0.1

* Migrated Android AMap POI keyword and nearby search from the legacy plugin.
* Added iOS AMap POI keyword and nearby search implementation.
* Added privacy and API-key setup methods for both platforms.
* Added `AmapKeywordSearchQuery`, `AmapAroundSearchQuery`, and configurable nearby-search `radius`.
* Added normalized `SearchResultItem` fields while preserving legacy API/model aliases.
* Added `AmapSearchException` for native SDK errors.
