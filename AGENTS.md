# AGENTS.md

## 适用范围

- 本文件适用于整个仓库。
- 只有当某个子目录需要不同规则时，才在更近的目录新增 `AGENTS.md` 或 `AGENTS.override.md`。
- 本文件只记录长期有效的项目约定、发布规则和验证步骤，不写临时任务说明。

## 项目背景

- `kw_amap_search` 是一个 Flutter 高德地图 POI 关键字搜索和周边搜索插件，支持 Android 和 iOS。
- pub.dev 包名是 `kw_amap_search`，GitHub 仓库是 `https://github.com/zhaofawu/kw_amap_search`。
- 项目使用 MIT 协议。
- 除非用户明确同意破坏性变更，否则要保持旧插件 API 和旧模型字段别名兼容。
- 行为变化时，要同步更新 `README.md`、`CHANGELOG.md`、`example/` 和对应平台实现。

## 依赖策略

- Android 插件自身必须在 `android/build.gradle.kts` 中使用 `compileOnly` 引入高德搜索 SDK。
- Android 宿主 App 负责提供运行时高德 SDK 依赖。example app 应保留如下示例：

```kotlin
implementation("com.amap.api:search:9.7.1")
```

- 不要把 `implementation("com.amap.api:search:...")` 改回 Android 插件自身依赖，除非用户明确要求，并且说明版本冲突取舍。
- Android 原生单元测试如果需要高德类，可以继续使用 `testImplementation`。
- 保持 `android/build.gradle.kts` 里兼容 AGP 9+ Built-in Kotlin 的写法，避免重新触发 Flutter 的 Kotlin Gradle Plugin 警告。
- iOS 当前在 `ios/kw_amap_search.podspec` 中声明 `AMapFoundation-NO-IDFA` 和 `AMapSearch-NO-IDFA`。如果版本或依赖名变化，要同步更新 README 和 CHANGELOG。

## 变更规则

- 变更要聚焦，不做无关格式化或重构。
- 尽量保持被编辑文件原有换行格式；当前根目录大部分元数据和文档文件使用 CRLF。
- 公开 Dart API 变化必须同步测试和 README 示例。
- Method channel 协议变化必须同时检查 Dart、Android、iOS、测试和 example app。
- 不要移除隐私合规和 API Key 设置路径。高德隐私合规调用属于插件契约的一部分。
- 除非用户明确要求发布并确认最终发布步骤，否则不要执行 `flutter pub publish`。

## 验证命令

普通代码变更交付前，优先在仓库根目录运行：

```bash
flutter pub get
flutter analyze
flutter test
```

涉及 Android、Gradle 或 Kotlin 原生代码时，条件允许还要验证 example app：

```bash
cd example
flutter pub get
flutter build apk --debug
```

涉及 iOS、Swift 或 podspec 时，如果本机 Xcode/CocoaPods 环境可用，运行：

```bash
cd example
flutter pub get
flutter build ios --no-codesign
```

任何 pub.dev 发布前，必须先运行：

```bash
flutter pub publish --dry-run
```

dry-run 最好是零警告；如果仍有警告，必须向用户说明原因和风险。

## 发布检查清单

1. 确认用户确实要发布新的 pub.dev 版本。
2. 更新 `pubspec.yaml` 中的 `version:`。
3. 在 `CHANGELOG.md` 增加对应版本记录。
4. 如果 API、初始化方式或依赖策略变化，同步更新 `README.md` 和 `example/`。
5. 确认 `pubspec.yaml` 仍包含 `repository: https://github.com/zhaofawu/kw_amap_search`。
6. 新增文件时检查包内容和 `.pubignore`。
7. 检查 `git diff` 和 `git status --short --branch`。
8. 运行上面的验证命令。
9. 提交发布改动，提交信息通常使用 `Release x.y.z`。
10. 在干净 git 状态下再次运行 `flutter pub publish --dry-run`。
11. 执行 `flutter pub publish` 前必须让用户最终确认。
12. 发布提交准备好后，把 `main` 推送到 GitHub。

## GitHub 工作流

- 当 `gh` 已认证时，优先使用 GitHub CLI，而不是浏览器自动化。
- 使用下面命令检查认证和仓库权限：

```bash
gh auth status
gh repo view zhaofawu/kw_amap_search --json nameWithOwner,url,viewerPermission,defaultBranchRef
```

- 不要让用户在聊天里粘贴 GitHub token，也不要把 token 打印出来。
- 预期远端是 `git@github.com:zhaofawu/kw_amap_search.git`，默认分支是 `main`。

