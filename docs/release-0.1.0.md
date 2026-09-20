# 0.1.0 发布前验证记录

日期：2026-09-21。检查对象为本仓库的 0.1.0 候选代码。本记录区分真实 SDK、页面自动化、固定数据单元测试与环境限制；发布状态以 pub.dev 为准。

## 已完成

| 检查 | 结果 |
| --- | --- |
| `flutter pub get` | 通过 |
| `flutter analyze --no-pub` | 无问题 |
| 根目录 `flutter test --no-pub` | 21 项通过 |
| example `flutter test --no-pub` | 7 项通过 |
| `./gradlew :kw_amap_search:testDebugUnitTest --offline` | 5 项通过 |
| example `flutter build apk --debug` | 通过 |
| example `flutter build ios --no-codesign --no-pub` | 通过 |
| iOS 依赖与产物检查 | Podfile.lock 包含高德依赖，Runner 符号包含真实 AmapSearchHandler 与逆解析回调 |
| Android 依赖策略 | 插件 compileOnly，example 提供运行时 implementation |
| Android 真机 SDK 集成 | 在线 6 项通过，另断网 1 项通过 |
| iOS 真机 SDK 集成 | 在线 5 项、隐私拒绝/错误 Key 1 项、断网及同进程恢复 1 项通过 |
| Android example 真机界面 | 三类查询、参数、分页、并发、单请求取消、超时、重试、快速操作、销毁通过；另同进程断网恢复通过 |
| iOS example 真机界面 | Profile 基础查询/重试及同进程断网恢复通过；Debug 共存宿主中完整三类查询、参数、分页、并发、单请求取消、超时、重试、快速操作、销毁通过 |
| iOS 原生隐私回归 | Debug example Swift Channel 的两项检查通过，未将 XCTest 算作执行通过 |
| 包版本、MIT、repository、迁移说明 | 已核对 |

原生版本保持 Android Search 9.7.1、iOS Search-NO-IDFA 9.8.0、Foundation-NO-IDFA 1.9.0。

回归覆盖：活动 ID 重复、取消与超时后复用 ID、迟到回调、Engine handler 清理、有效零坐标、负距离哨兵、距离 JSON 往返、取消通道挂起或报错、两个并发请求分别展示与单请求取消。固定数据测试包含 B0IASORQIR 和 B0I32YKT2M 的坐标、ID、分类及约 5 米 / 48 米距离。

发布前必须在干净提交上运行 `flutter pub publish --dry-run`。基线 `18910d6` 已通过零警告预检；本次工作区预检的唯一警告为未提交修改（退出码 65）。正式发布以最终干净提交上的零警告预检为前置条件。

## Android 真机查询验证

设备 ELS AN10，Android 12 / API 31，arm64 真机。Flutter 3.44.1，插件 0.1.0，Android Search SDK 9.7.1。生产插件代码基于 `18910d6`；新增集成测试直接通过 MethodChannel 调用原生 SDK，没有 mock 或 Web 服务回退。

在用户同意 SDK 隐私政策后，使用独立测试应用的 Android Key。Key 通过构建参数注入，不保存到源码或报告；测试 APK 不用于分发。

共同参数：GCJ-02 `22.85687178770656, 108.28107380400866`，半径 300 米，周边按原生距离模式排序，周边页面大小 25。

| 查询 | 返回结果 | 样本情况 |
| --- | --- | --- |
| 逆解析，扩展信息开启 | 18 POI、1 AOI、3 道路、0 路口 | 无兔喜；栖花里 `B0I32YKT2M` 计算距离 48.325 米，SDK 48 米 |
| 默认周边，关键词/分类为空 | 25 POI | 首批无兔喜 |
| 显式广分类周边 | 25 POI | 兔喜 `B0IASORQIR` 第一名，分类 `060400`，计算距离 5.299 米，SDK 5 米 |
| 关键词“兔喜”周边 | 2 POI | 兔喜 `B0IASORQIR` 第一名，另一条为兔喜驿站 |

显式分类采用需求文档的 `050000|060000|070000|080000|090000|100000|110000|120000|130000|140000|150000|160000|170000|190000`。查询时间及完整 POI 字段见 [Android 验收 JSON](android-0.1.0-2026-09-21.json)。

另已验证购物类 `060000` 的第 1/2 页（各 5 条，无重叠）、三类查询并发、关键词距离为空、逆解析关闭扩展后集合为空、AOI 包含关系保持未知、活动 ID 重复、单请求取消不影响另一请求、重复取消、取消后跨查询类型复用 ID、1ms 超时后复用 ID。

隐私拒绝返回 `sdk_error / nativeCode=555575`；全零无效测试 Key 返回 `sdk_error / nativeCode=1002`。用户手动关闭 Wi-Fi 和移动数据后，以新的关键词请求验证断网，返回 `sdk_error / nativeCode=1804`，没有假成功或无限挂起。

恢复网络后重新启动测试，四种样本查询、取消/超时及零值场景通过，分类分页中出现一次 `sdk_error / nativeCode=1800`。未改代码或放宽断言，单独重跑分类、分页及三类并发后通过。该次 1800 的具体上游原因未查明，不能声称所有恢复查询均无错误。后续另行完成了同进程断网后恢复的 UI 重试流程。原生错误被正常暴露，没有自动隐藏或重试。

查询测试期间读取该 example 包的 Android 进程退出记录，只发现测试工具触发的 `USER REQUESTED` 停止，未发现该轮的崩溃退出记录；这不替代长期稳定性验证。

### 零坐标直接 SDK 对照

曾因测试错误地要求 `(0,0)` 必定空成功而失败；没有修改正式插件来吞掉错误。临时原生对照直接使用 `GeocodeSearch`、`RegeocodeQuery(point, 300f, GeocodeSearch.AMAP)` 与 `EXTENSIONS_ALL`，绕过插件查询和映射，得到了相同结果：

| 坐标（纬度，经度） | 直接 SDK | 插件 |
| --- | --- | --- |
| 文档样本点 | 1000，18 POI | 成功，18 POI |
| `(0,0)` | 1008 | `sdk_error`，`nativeCode=1008` |
| `(0,108)` | 1000，0 POI | 成功，原请求坐标保留，0 POI |
| `(22,0)` | 1000，0 POI | 成功，原请求坐标保留，0 POI |

9.7.1 JAR 的 `AMapException.CODE_AMAP_INVALID_USER_SCODE` 常量值为 1008（MD5 安全码校验失败）。该错误只在上述全零坐标对照中出现，其高德内部原因未知；不能解释成“没有地点”，也不据此禁止合法零坐标。单轴为零的真实结果和 Dart 双零坐标单元测试共同验证插件不以零值判缺失。临时诊断 Channel 已移除。

## iOS 真机查询验证

设备 iPhone 14 Plus（iPhone14,8），iOS 16.5.1，arm64。Flutter 3.44.1，Search-NO-IDFA 9.8.0、Foundation-NO-IDFA 1.9.0。基于 `18910d6` 加本次隐私与初始化修复，使用真实移动端 Key、原生搜索 SDK；Key 不保存到源码和报告。

首次测试发现只设置 Foundation 隐私标志不足以初始化 Search SDK，导致请求等待至超时。现已转发 `AMapSearchAPI.updatePrivacyShow` 和 `updatePrivacyAgree`，并在初始化返回 nil 时立即返回 `not_initialized`。授权前仍返回 `privacy_not_agreed`，不会自动替用户同意。

重新安装测试 App 会触发 iOS 联网授权，授权前多次返回 `sdk_error / nativeCode=1806`（没有网络连接）。增加可选测试联网预检后，由用户授权，再运行原有 SDK 断言；不是吞掉 SDK 错误或修改正式插件的重试行为。

| 查询 | 返回结果 | 样本情况 |
| --- | --- | --- |
| 逆解析，扩展信息开启 | 18 POI、1 AOI、3 道路、0 路口 | 无兔喜；栖花里计算距离 48.325 米，SDK 48.3554 米 |
| 默认周边，关键词/分类为空 | 25 POI | 首批无兔喜 |
| 显式广分类周边 | 25 POI | 兔喜第一名，分类 `060400`，计算距离 5.299 米，SDK 5 米 |
| 关键词“兔喜”周边 | 2 POI | 兔喜第一名 |

共同参数与 Android 相同。查询时间、完整 POI 字段及版本见 [iOS 验收 JSON](ios-0.1.0-2026-09-21.json)。另通过购物类分页（两页各 5 条、无重叠）、三类查询并发、关键词距离为空、逆解析关闭扩展、重复活动 ID、单请求取消、重复取消、超时和 ID 复用，以及单轴零坐标和真实空结果测试。独立进程验证隐私拒绝返回 `privacy_not_agreed`、无效 Key 返回 `sdk_error / nativeCode=1002`。

断网/恢复另 1 项通过：先联网安装并启动，用户关闭 Wi-Fi 和蜂窝数据后返回 `sdk_error / nativeCode=1806`；保持同一进程，用户恢复网络后显式重试原关键词请求成功（空结果），随后逆解析返回非空地址。离线安装的前两次尝试因 iOS 无法完成新包签名/描述文件信任校验而未能启动，未算成 SDK 测试结果。后续另通过页面按钮完成同进程断网报错和恢复重试。

新增两项 Swift 隐私/初始化失败回归测试。Xcode 26.5 的 `build-for-testing` 已编译测试包，但在本机 iOS 16.5.1 真机执行被 `Logic Testing Unavailable` 拒绝；即使 `.xctestrun` 标识 `IsAppHostedTestBundle=true` 也未能运行。没有将 XCTest 算作通过。

替代执行采用 Debug example 的 `kw_amap_search_example/native_tests` Channel，由 `native_regression_test.dart` 调用真实 Swift/AMap 对象：隐私授权转发后可初始化 Search；撤销 SDK 隐私状态后插件立即返回 `not_initialized`。两项断言已在该 iPhone 通过。Runner Debug 增加 `DEBUG` 编译条件；Release/Profile 不含此入口。签名团队只通过仓库外 xcconfig 注入。

## 页面真机回归

`example_ui_test.dart` 挂载真实 `MyApp`，通过输入框及按钮执行 SDK 查询。文本输入使用 Flutter 测试通道避免系统键盘异步干扰，没有 mock 搜索 Channel。分别断言每个请求 ID 的终态，不以动画停止冒充网络请求完成。

Android 在线用例包括三类查询、购物分类第 2 页、非法半径、1ms 超时、恢复正常超时后的显式重试、并发单请求取消与独立成功、快速点击和页面销毁后重新挂载。iOS Profile 模式通过基础在线用例，Debug 共存用例也通过上述完整场景。iOS 取消初次断言因重复查询在点击前已完成而失败；改用本轮未查询过的有效半径后重跑通过，没有改变插件取消语义或放宽终态断言。

双端断网 UI 用例使用新的随机关键词避免缓存；先由真实 SDK 返回 `sdk_error` 并显示在页面，恢复网络后点击同一关键词查询，明确返回成功空结果。Android 网络经 ADB 临时关闭并恢复到原有开启状态；iOS 由用户切换。iOS 首次 UI 恢复运行因人工操作超过 90 秒等待窗口失败，窗口改为 180 秒后完整重跑通过，插件本身仍使用原有请求超时。

页面及网络恢复截图由 `test_driver/acceptance.dart` 生成。截图检查未发现文字重叠或结果区空白；大段参数正常换行。截图不包含真实 Key。固定样本和字段证据仍以本目录两份 JSON 为准。

- [Android 逆解析](screenshots/android-reverse.png)
- [iOS 逆解析](screenshots/ios-reverse.png)
- [Android 同进程网络恢复](screenshots/android-network-recovery.png)
- [iOS 同进程网络恢复](screenshots/ios-network-recovery.png)

## 多插件共存

隔离宿主同时依赖本仓库搜索插件、`kw_amap_location 0.0.2` 和 pub.dev 的 `amap_map 1.0.15`；不修改原始 location 仓库，不修改 Pub 缓存。

| 平台 | 统一后的运行时依赖 | 验证 |
| --- | --- | --- |
| Android | `3dmap-location-search:10.1.200_loc6.4.9_sea9.7.4` | 三插件构建通过；真机分类分页/三类并发、取消/超时/ID 复用共 2 项通过 |
| iOS | Map-NO-IDFA 9.7.0、Location-NO-IDFA 2.12.2、Search-NO-IDFA 9.8.0、Foundation-NO-IDFA 1.9.0 | 三插件无签名构建及真机完整 UI 用例通过，包括三类查询、分页、并发、单请求取消、超时、重试、快速操作、销毁 |

Android 删除隔离宿主的独立 `search` 运行时依赖，仅保留地图插件提供的合集；search/location 的 `compileOnly` 不变。临时地图副本将 AGP 3.5.4 调整为 9.0.1、compileSdk 35 调整为 36，以适配当前 Flutter 生命周期依赖。正式插件及 example 的独立 SDK 配置不变。

iOS 默认混用 IDFA 地图/定位与 NO-IDFA 搜索的组合实际构建失败，报同名 `amapfoundationkit.framework` 冲突。仅在隔离副本 podspec 统一为 NO-IDFA 后构建成功。不能据此宣称未修改的三个插件开箱即用；宿主需要先统一依赖策略。这里只验证三个插件注册、搜索运行和无重复依赖，不宣称已验收地图渲染或设备定位业务。

## 崩溃记录

导出并保留设备原有报告，没有删除手机崩溃日志。iOS 本轮发现一次 `Runner-2026-09-21-051614.ips`：`EXC_BREAKPOINT / SIGTRAP`，故障栈在 `lldb_image_notifier`、dyld 通知调试器和 Network QUIC 动态加载，没有本插件搜索栈帧。它发生在调试启动期间，原因未完全查明，不能写成“没有崩溃”或“已修复”。后续 Profile 界面/网络恢复、Debug 共存完整用例通过，最终再次导出未发现新增 Runner 崩溃报告；这不构成长期稳定性保证。Android 安装普通 example 后再次读取该包退出记录没有新增条目，较早检查仅有测试工具触发的停止记录。

## 已知环境限制

- 当前 iOS 高德 Foundation 依赖不含 arm64 模拟器切片，Apple Silicon iOS 26+ 模拟器不受支持；真机架构构建已通过。
- 本版 iOS 使用 CocoaPods，未宣称支持 SPM。当前 Flutter 会提示未来迁移要求。
- Android Gradle 单元测试输出包含 example/Flutter 工具链的旧 Kotlin 配置提示及高德 PoiSearch 弃用提示；本轮保持 SDK 版本，插件自身 compileOnly 策略不变。
- 发布到 pub.dev 仍需按 AGENTS.md 取得最终发布确认。
