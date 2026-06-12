# kw_amap_search

`kw_amap_search` 是一个 Flutter 高德地图 POI 搜索插件，支持 Android 和 iOS。

它从旧插件 `gxcm_amap_search` 迁移了 Android 端能力，并补齐了 iOS 端实现。现有能力包括：

- 设置 Android/iOS 高德 Key
- 更新高德隐私合规状态
- 关键字 POI 搜索
- 周边 POI 搜索
- 周边搜索半径 `radius`
- 统一的 POI 结果模型
- 旧 API 和旧模型字段兼容
- 原生 SDK 错误透传为 `AmapSearchException`

## 平台依赖

### Android

插件内置依赖：

```kotlin
implementation("com.amap.api:search:9.7.1")
```

调用搜索前需要先配置 Android Key 和隐私状态。

### iOS

插件 podspec 内置依赖：

```ruby
s.dependency 'AMapFoundation-NO-IDFA', '1.9.0'
s.dependency 'AMapSearch-NO-IDFA', '9.8.0'
```

iOS 端通过 `AMapServices.shared().apiKey` 设置 Key，通过 `securityAgree` 和 `analysisAgree` 更新隐私同意状态。

## 初始化

建议在发起任何搜索前执行：

```dart
await KwAmapSearch.setApiKey('android-key', 'ios-key');
await KwAmapSearch.updatePrivacyShow(true, true);
await KwAmapSearch.updatePrivacyAgree(true);
```

## 关键字搜索

推荐使用 query object API：

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

旧 API 仍然可用：

```dart
final pois = await KwAmapSearch.searchKeyword(
  keyword: '咖啡',
  city: '上海',
);
```

## 周边搜索

```dart
final pois = await KwAmapSearch.searchNearby(
  const AmapAroundSearchQuery(
    center: AmapLatLng(latitude: 31.2304, longitude: 121.4737),
    keyword: '餐厅',
    city: '上海',
    radius: 1500,
  ),
);
```

旧 `searchAround` 也保留，并新增可选 `radius` 参数。默认值是 `1000` 米，保持旧 Android 实现的行为：

```dart
final pois = await KwAmapSearch.searchAround(
  latitude: 31.2304,
  longitude: 121.4737,
  keyword: '餐厅',
  radius: 1500,
);
```

## 结果模型

新代码建议使用清晰字段：

```dart
for (final poi in pois) {
  print('${poi.name} ${poi.address}');
  print('${poi.location.latitude}, ${poi.location.longitude}');
}
```

为了方便旧项目迁移，下列旧字段仍然可用：

```dart
poi.poiId;
poi.title;
poi.snippet;
poi.latLonPoint;
poi.indoorData;
poi.poiExtension;
poi.subPois;
```

旧模型构造方式也保留，例如 `SubPois(title: ...)`、`LatLonPoint(latitude: ...)`、`Photos(title: ...)`。

## 错误处理

原生 SDK 返回非成功状态时，插件会抛出 `AmapSearchException`，避免把“搜索失败”和“没有结果”混在一起：

```dart
try {
  final pois = await KwAmapSearch.searchByKeyword(
    const AmapKeywordSearchQuery(keyword: '咖啡'),
  );
} on AmapSearchException catch (error) {
  print(error.code);
  print(error.message);
  print(error.details);
}
```

## 示例

运行 example：

```bash
cd example
flutter run
```

示例页包含 Key 输入、隐私初始化、关键字搜索、周边搜索和结果列表。
