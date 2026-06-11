## 0.0.1

* Migrated Android AMap POI keyword and nearby search from the legacy plugin.
* Added iOS AMap POI keyword and nearby search implementation.
* Added privacy and API-key setup methods for both platforms.
* Added `AmapKeywordSearchQuery`, `AmapAroundSearchQuery`, and configurable nearby-search `radius`.
* Added normalized `SearchResultItem` fields while preserving legacy API/model aliases.
* Added `AmapSearchException` for native SDK errors.
