# 0.1.0 发布前验证记录

日期：2026-09-21。检查对象为本仓库的 0.1.0 候选代码。本记录不代表已发布或通过真机验收。

## 已完成

| 检查 | 结果 |
| --- | --- |
| `flutter pub get` | 通过 |
| `flutter analyze --no-pub` | 无问题 |
| 根目录 `flutter test --no-pub` | 21 项通过 |
| example `flutter test --no-pub` | 5 项通过 |
| `./gradlew :kw_amap_search:testDebugUnitTest --offline` | 5 项通过 |
| example `flutter build apk --debug` | 通过 |
| example `flutter build ios --no-codesign --no-pub` | 通过 |
| iOS 依赖与产物检查 | Podfile.lock 包含高德依赖，Runner 符号包含真实 AmapSearchHandler 与逆解析回调 |
| Android 依赖策略 | 插件 compileOnly，example 提供运行时 implementation |
| 包版本、MIT、repository、迁移说明 | 已核对 |

原生版本保持 Android Search 9.7.1、iOS Search-NO-IDFA 9.8.0、Foundation-NO-IDFA 1.9.0。

回归覆盖：活动 ID 重复、取消与超时后复用 ID、迟到回调、Engine handler 清理、有效零坐标、负距离哨兵、距离 JSON 往返、取消通道挂起或报错、两个并发请求分别展示与单请求取消。固定数据测试包含 B0IASORQIR 和 B0I32YKT2M 的坐标、ID、分类及约 5 米 / 48 米距离。

发布前必须在干净提交上运行 `flutter pub publish --dry-run`。首次预检只有待提交改动及待删除旧 SPM 文件的 Git 状态警告，无包内容或元数据校验错误。

## 尚待真机验收

本机 `flutter devices --machine` 只发现 macOS 和 Chrome，没有 Android/iOS 设备。因此以下项目尚未验证，不能标记“双端运行完成”：

- 双端真实移动端 Key 下的关键词、分类、分页、逆解析扩展字段及距离排序。
- “兔喜快递”四种查询对照，记录时间、查询参数、POI ID/分类/坐标/距离及 SDK 差异。
- 断网、错误 Key、快速提交、页面退出、并发和单请求取消的真机行为。
- 与地图、定位插件共同运行时的 SDK 兼容性。
- iOS XCTest 运行、设备截图及崩溃日志检查。

测试使用 GCJ-02 坐标 `22.85687178770656, 108.28107380400866`。在 example 输入移动端 Key 并明确同意隐私政策后执行；不要将 Key 写入报告或仓库。

## 已知环境限制

- 当前 iOS 高德 Foundation 依赖不含 arm64 模拟器切片，Apple Silicon iOS 26+ 模拟器不受支持；真机架构构建已通过。
- 本版 iOS 使用 CocoaPods，未宣称支持 SPM。当前 Flutter 会提示未来迁移要求。
- Android Gradle 单元测试输出包含 example/Flutter 工具链的旧 Kotlin 配置提示及高德 PoiSearch 弃用提示；本轮保持 SDK 版本，插件自身 compileOnly 策略不变。
- 发布到 pub.dev 仍需按 AGENTS.md 取得最终发布确认。
