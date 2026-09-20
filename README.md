# kw_amap_search

`kw_amap_search` 是一个 Flutter 高德搜索插件，使用 Android/iOS 原生搜索 SDK，提供：

- 关键字 POI 搜索
- 周边 POI 搜索，支持 `types` 分类和距离/综合排序
- 逆地理编码，返回标准地址、行政区、POI、AOI、道路和路口
- 请求 ID、超时、逻辑取消和并发隔离
- 统一的错误模型 `AmapSearchException`

本插件只负责搜索 SDK 查询和数据映射，不负责地图渲染、设备定位、业务地标评分、服务区域校验或 UI 文案生成。

## 坐标和空值

- 本版输入输出只支持 GCJ-02，Channel 会传 `coordinateType: "gcj02"`。
- 插件不会静默转换 WGS84/BD09，也不会二次偏移 GCJ-02。
- `location`、`entryLocation`、`exitLocation` 都是 `AmapLatLng?`。缺失、非数字或越界坐标返回 `null`，不会伪造成 `(0,0)`。
- `distanceMeters` 是 Dart 层用请求点和 POI 坐标计算的近似球面直线距离。
- `sdkDistanceMeters` 是原生 SDK 返回的原始距离，可能为空，含义也可能因字段不同而不同。
- `[]` 只表示查询成功但没有结果；错误、取消、超时、SDK 缺失不会伪装成空列表。

## 平台依赖

### Android

Android 宿主 App 需要自行引入高德搜索 SDK。本插件 Android 端使用 `compileOnly` 编译高德搜索 SDK，便于多个高德插件共存时由宿主统一管理 SDK 版本。

```kotlin
implementation("com.amap.api:search:9.7.1")
```

本仓库 example 已包含这项依赖。

与地图、定位插件共存时，由宿主统一选择一套 SDK。如果地图插件已经提供包含搜索的 `3dmap-location-search` 合集，不要再加入上面的独立 `search` 依赖，否则会出现重复类。`compileOnly` 不会自动解决其他插件之间的重复依赖。

### iOS

插件 CocoaPods podspec 声明 NO-IDFA 依赖：

```ruby
s.dependency 'AMapFoundation-NO-IDFA', '1.9.0'
s.dependency 'AMapSearch-NO-IDFA', '9.8.0'
```

同一 iOS App 的地图、定位、搜索依赖必须统一使用 NO-IDFA 系列，不能与 `AMapFoundation`（IDFA 版）混用；混用会产生同名 `AMapFoundationKit.framework` 冲突。其他插件固定了 IDFA 依赖时，需要先由其维护者调整 podspec，宿主再统一版本，不要同时安装两套 Foundation。

共存验证采用 Android `3dmap-location-search:10.1.200_loc6.4.9_sea9.7.4`，iOS Map-NO-IDFA 9.7.0 / Location-NO-IDFA 2.12.2 / Search-NO-IDFA 9.8.0 / Foundation-NO-IDFA 1.9.0。地图插件的旧 Gradle/compileSdk 配置也需要适配宿主工具链；这不是对未修改的所有第三方插件组合的兼容承诺。

iOS 端通过 `AMapServices.shared().apiKey` 设置 Key，通过 `AMapSearchAPI.updatePrivacyShow` / `updatePrivacyAgree` 更新搜索 SDK 隐私状态，同时保留 Foundation 的 `securityAgree` 和 `analysisAgree` 设置。用户同意前不创建搜索 SDK，初始化失败返回 `not_initialized`，不会让请求一直等待。

本插件使用 CocoaPods 接入 iOS，不提供 SPM 包，避免 Flutter 自动选择不含高德 SDK 的 Swift Package。example 已配置 CocoaPods。若运行环境缺少 `AMapSearchKit` 或 `AMapFoundationKit`，插件会抛 `sdk_unavailable`。

当前固定的 `AMapFoundation-NO-IDFA 1.9.0` 不含 arm64 模拟器切片，Apple Silicon 上的 iOS 26+ 模拟器不受支持。本版已在 Android 12 和 iOS 16.5.1 真机验证真实 SDK 查询；本地运行 example 仍需配置签名及对应移动端 Key。

example 使用项目级配置，无需修改全局 Flutter 设置：

```yaml
flutter:
  config:
    enable-swift-package-manager: false
```

## 初始化

宿主先向用户展示隐私政策并取得同意，再配置 Key 和隐私状态。下面的 `true` 代表已取得真实同意，不应在启动时无条件调用：

```dart
await KwAmapSearch.setApiKey('android-key', 'ios-key');
await KwAmapSearch.updatePrivacyShow(true, true);
await KwAmapSearch.updatePrivacyAgree(true);
```

## 关键字搜索

```dart
final pois = await KwAmapSearch.searchByKeyword(
  const AmapKeywordSearchQuery(
    keyword: '咖啡',
    city: '上海',
    types: '050000',
    pageSize: 20,
    pageNum: 1,
  ),
);
```

关键词会去除首尾空白，空关键词抛 `invalid_argument`。

## 周边搜索

```dart
const point = AmapLatLng(latitude: 31.2304, longitude: 121.4737);

final pois = await KwAmapSearch.searchNearby(
  const AmapAroundSearchQuery(
    center: point,
    radius: 300,
    types: '050000|060000|070000',
    sortRule: AmapAroundSortRule.distance,
    pageSize: 25,
    pageNum: 1,
  ),
);
```

`types` 为空时使用高德 SDK 的上游默认分类范围，不等于全部 POI。插件不会把调用者指定的分类替换成内置分类。

## 逆地理编码

```dart
final result = await KwAmapSearch.reverseGeocode(
  const AmapReverseGeocodeQuery(
    point: AmapLatLng(latitude: 31.2304, longitude: 121.4737),
    radius: 300,
    includeExtensions: true,
  ),
);

print(result.formattedAddress);
print(result.addressComponent?.district);
print(result.pois.length);
print(result.aois.length);
```

`requestedLocation` 始终是原始请求点，不会替换成 POI 坐标或道路中心。关闭扩展信息时，`pois`、`aois`、`roads`、`roadIntersections` 返回空列表。

AOI 当前至少包含 `id`、`name`、`adCode`、`center`、`areaSquareMeters`。Android Search SDK 9.7.1 不提供 AOI 包含关系或边界距离，因此 `containsPoint` 和 `distanceToBoundaryMeters` 在该端保持 `null`。

### 平台字段差异

| 字段或能力 | Android 9.7.1 | iOS 9.8.0 |
| --- | --- | --- |
| 标准地址、行政区、门牌、道路、路口 | 映射 SDK 原始字段 | 映射 SDK 原始字段 |
| POI 坐标缺失 | `null` | `null` |
| `distanceMeters` | Dart 统一计算 | Dart 统一计算 |
| POI 原始距离 | SDK 整数转 `double?`，负值为 `null` | SDK 距离转 `double?`，负值为 `null` |
| AOI 中心、面积 | SDK 原始数据，缺失可空 | SDK 原始数据 |
| AOI 包含关系、边界距离 | SDK 未提供，返回 `null` | 本版保守返回 `null`，不从中心点推断 |
| 单请求取消 | 逻辑取消并解除监听 | 逻辑取消，不调用全局取消 |

普通文本缺失为空字符串，集合缺失为空列表。直辖市空 `city` 保持原值；逆解析的 POI 是 SDK 返回的子集，不等于完整周边搜索。两端结果覆盖可能不同。

## 请求控制

```dart
final future = KwAmapSearch.searchNearby(
  const AmapAroundSearchQuery(
    center: AmapLatLng(latitude: 31.2304, longitude: 121.4737),
  ),
  options: const AmapSearchRequestOptions(
    requestId: 'picker-nearby-1',
    timeout: Duration(seconds: 10),
  ),
);

final cancelled = await KwAmapSearch.cancelRequest('picker-nearby-1');
```

`cancelRequest` 是逻辑取消：返回 `true` 表示待完成请求被转为 `cancelled`，迟到原生回调会被丢弃；不保证原生 SDK 网络请求一定已经中止。省略 `requestId` 时插件内部会生成唯一 ID。活动 ID 重复会抛 `duplicate_request_id`。

请求结束后可以复用 ID，旧回调不会影响新请求。Dart 超时后会立即抛 `timeout`，原生取消失败或不响应不会阻塞这一结果；原生端也有独立的超时清理。

## 错误码

`AmapSearchException.code` 使用稳定字符串：

- `invalid_argument`
- `not_initialized`
- `privacy_not_agreed`
- `duplicate_request_id`
- `cancelled`
- `timeout`
- `sdk_unavailable`
- `sdk_error`

`details` 可能包含 `requestId`、`operation`、`platform`、`nativeCode` 等排障信息，不包含 Key。

Android 的隐私拒绝由高德 SDK 检查，以 `sdk_error` 和原生错误码返回；iOS 在创建搜索 SDK 前返回 `privacy_not_agreed`。两端都不会把失败转换成空列表。

## 迁移说明

旧便捷方法仍保留并转发到 Query API：

```dart
await KwAmapSearch.searchKeyword(keyword: '咖啡');
await KwAmapSearch.searchAround(latitude: 31.2304, longitude: 121.4737);
```

0.1.0 的主要迁移点：

- `SearchResultItem.location`、`entryLocation`、`exitLocation` 变为可空，使用前先判空。
- 业务距离优先使用 `distanceMeters`；旧 `distance` 只是 `sdkDistanceMeters` 的兼容别名。
- `toJson()` / `fromJson()` 保留已有距离；提供 `queryCenter` 时重新计算 `distanceMeters`。关键词查询的距离为 `null`，SDK 的负距离哨兵也转换为 `null`，有效的 `0` 保留。
- 周边搜索默认 `sortRule` 为 `AmapAroundSortRule.distance`。
- 无效坐标、半径、分页、空关键词会抛 `invalid_argument`，不再返回空列表。

## 示例

运行 example：

```bash
cd example
flutter run
```

示例页包含隐藏显示的 Key 输入、隐私同意、关键词搜索、周边搜索、逆地理编码和并发请求。可切换分类、半径、页码、每页条数、排序、扩展信息和超时；每个请求分别显示参数、ID、状态及取消按钮，逆解析可展开 AOI、道路和路口。再次点击查询即为显式重试，失败或取消不会清空另一个请求的结果。不内置真实 Key。

验证命令：

```bash
flutter analyze
flutter test
cd example
flutter test
flutter build apk --debug
flutter build ios --no-codesign
cd android
./gradlew :kw_amap_search:testDebugUnitTest
```

真机集成测试使用 `example/integration_test/`，直接调用原生 SDK，不使用模拟结果。将测试配置放在仓库外的私有 JSON 文件中：

```json
{
  "AMAP_ANDROID_KEY": "你的 Android 测试 Key",
  "AMAP_IOS_KEY": "你的 iOS 测试 Key",
  "AMAP_PRIVACY_AGREED": true
}
```

只有实际同意高德 SDK 隐私政策后才能设置 `AMAP_PRIVACY_AGREED`。在 `example/` 下执行：

```bash
flutter test integration_test -d <device-id> --no-uninstall --dart-define-from-file=/path/to/private/amap-test.json
```

覆盖真实分类与分页、四种固定坐标查询对照、并发、取消、超时、ID 复用、隐私拒绝和错误 Key。实时 POI 数据可能变化，断言失败时应检查上游结果，不要硬编码结果或直接忽略失败。未提供当前平台 Key 时，正常查询测试会跳过，跳过不代表验收通过。带测试 Key 的构建仅用于测试，不对外分发。

断网测试默认跳过。手动关闭测试设备网络后，单独运行：

```bash
flutter test integration_test/plugin_integration_test.dart -d <device-id> --no-uninstall --plain-name="offline request" --dart-define-from-file=/path/to/private/amap-test.json --dart-define=AMAP_TEST_OFFLINE=true
```

完成后恢复网络，再运行正常查询测试。测试不会自行更改设备网络设置。`--no-uninstall` 保留 App 及联网授权，避免测试默认卸载后下次安装需要重新授权；完成验收后应覆盖安装不带测试 Key 的普通 example。

iOS 重新安装测试 App 后可能再次要求联网授权。可添加 `--dart-define=AMAP_WAIT_FOR_NETWORK_PERMISSION=true`，测试会先等待最多 180 秒供用户授权并确认网络连通，再执行 SDK 断言。该预检仅访问高德域名，不发送 Key 或坐标、不执行 Web 搜索，也不会重试失败的 SDK 测试；断网测试自动跳过此预检。

断网命令另加 `--dart-define=AMAP_TEST_NETWORK_RECOVERY=true` 可验证同一进程恢复：看到 `offline error verified; restore network now` 后恢复设备网络，测试将在连通后显式重试原关键词请求，并验证一次逆解析成功。这是测试发起的重试，不是插件自动重试，也不替代 example 页面交互验收。

如果 iOS 新安装包需要联网校验才能启动，再加 `--dart-define=AMAP_TEST_MANUAL_OFFLINE=true`，保持联网启动；看到 `turn network off` 后再手动断网。测试确认网络不可达后才发起断网 SDK 请求。

页面真机测试及截图在 `example/` 下运行：

```bash
AMAP_SCREENSHOT_DIR=/path/to/private/screenshots flutter drive --driver=test_driver/acceptance.dart --target=integration_test/example_ui_test.dart -d <device-id> --dart-define-from-file=/path/to/private/amap-test.json
```

页面测试使用 Flutter 文本输入测试通道，查询仍调用真实原生 SDK。另加 `--dart-define=AMAP_TEST_UI_NETWORK_RECOVERY=true` 可验证页面断网报错和同进程重试：保持联网启动，按测试提示断网、恢复；每阶段最多等待 180 秒。

`native_regression_test.dart` 在 iOS Debug example 中调用测试专用 Swift Channel，验证 Search 隐私转发及 SDK 初始化失败立即返回。该 Channel 不编入 Release/Profile，也不包含真实 Key；XCTest 受环境限制时可用该真机回归验证这两条路径。
