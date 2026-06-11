# AMap Search Android Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the Android AMap search behavior from `gxcm_amap_search` into the new `kw_amap_search` plugin while preserving the new plugin identity.

**Architecture:** Keep `kw_amap_search` as the public Dart package and Android method channel name. Add Dart facade/platform-interface methods, add the POI result model, and adapt the legacy Kotlin implementation to `com.kw.kw_amap_search`.

**Tech Stack:** Flutter plugin, Dart method channels, Kotlin Android library, AMap Search SDK (`com.amap.api:search:latest.integration`), Flutter tests, Android unit/build verification.

---

### Task 1: Dart API Contract

**Files:**
- Modify: `lib/kw_amap_search.dart`
- Modify: `lib/kw_amap_search_platform_interface.dart`
- Modify: `lib/kw_amap_search_method_channel.dart`
- Create: `lib/search_result_item.dart`
- Modify: `test/kw_amap_search_test.dart`
- Modify: `test/kw_amap_search_method_channel_test.dart`

- [ ] Write failing tests for `KwAmapSearch` static API forwarding, method-channel arguments, and POI result parsing.
- [ ] Run `fvm flutter test test/kw_amap_search_test.dart test/kw_amap_search_method_channel_test.dart` and confirm failures reference missing methods/types.
- [ ] Implement the minimal Dart API and result model.
- [ ] Run the same tests and confirm they pass.

### Task 2: Android Native Migration

**Files:**
- Modify: `android/build.gradle.kts`
- Modify: `android/src/main/kotlin/com/kw/kw_amap_search/KwAmapSearchPlugin.kt`
- Create: `android/src/main/kotlin/com/kw/kw_amap_search/PoiUtil.kt`
- Modify: `android/src/test/kotlin/com/kw/kw_amap_search/KwAmapSearchPluginTest.kt`

- [ ] Add the AMap Search SDK dependency without changing existing Gradle versions.
- [ ] Port `setApiKey`, `updatePrivacyShow`, `updatePrivacyAgree`, `searchKeyword`, and `searchAround` to `KwAmapSearchPlugin`.
- [ ] Port POI-to-Map conversion to `PoiUtil`.
- [ ] Keep channel name `kw_amap_search` and package `com.kw.kw_amap_search`.
- [ ] Update Android tests only where constructors or handlers changed.

### Task 3: Verification

**Files:**
- All modified files.

- [ ] Run `dart format lib test`.
- [ ] Run `fvm flutter test`.
- [ ] Run `fvm flutter analyze`.
- [ ] Run an Android build or unit-test command that compiles the plugin against the AMap dependency.
- [ ] Review `git diff` to verify only the intended migration changed.

