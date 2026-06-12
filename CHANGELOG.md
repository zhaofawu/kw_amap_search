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
