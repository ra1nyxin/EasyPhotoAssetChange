# EasyPhotoAssetChange (GeoModifier)

## 简介 / Introduction
EasyPhotoAssetChange 是一个专为 iOS 设计的轻量级工具，旨在绕过系统相册在修改照片地理位置时存在的地理围栏与“附近位置”推荐限制。通过直接调用底层 Photos 框架 API，用户可以在全球范围内精准修改照片的 GPS 坐标。

EasyPhotoAssetChange is a lightweight tool designed for iOS to bypass the geofencing and "nearby suggestions" limitations in the native Photos app when modifying photo locations. By directly invoking underlying Photos framework APIs, it allows users to precisely modify GPS coordinates globally.

---

## 核心功能与技术实现 / Core Features & Technical Implementation

### 1. 权限管理 / Permission Management
程序使用 `PHPhotoLibrary.requestAuthorization(for: .readWrite)` 获取相册完全访问权限。针对 iOS 17+ 引入的隐私清单要求，通过动态生成 `Info.plist` 并注入 `NSPhotoLibraryUsageDescription` 确保在沙箱环境下的合规性。

The app uses `PHPhotoLibrary.requestAuthorization(for: .readWrite)` to obtain full photo library access. Addressing iOS 17+ privacy manifest requirements, it dynamically generates an `Info.plist` with `NSPhotoLibraryUsageDescription` to ensure compliance within the sandbox.

### 2. 坐标修改逻辑 / Location Modification Logic
*   **资源检索 (Resource Retrieval)**: 使用 `PHAsset.fetchAssets(withLocalIdentifiers:options:)` 通过唯一标识符精准定位选定照片，避免全量扫描导致的 OOM (Out of Memory) 风险。
*   **原子化写入 (Atomic Write)**: 核心操作封装在 `PHPhotoLibrary.shared().performChanges(_:completionHandler:)` 闭包中。
*   **元数据覆盖 (Metadata Override)**: 实例化 `PHAssetChangeRequest(for: asset)` 并将其 `.location` 属性强制赋值为由 `MapKit` 拾取或手动输入的 `CLLocation` 对象。

*   **Resource Retrieval**: Uses `PHAsset.fetchAssets(withLocalIdentifiers:options:)` to pinpoint selected photos via unique identifiers, mitigating OOM risks.
*   **Atomic Write**: Core operations are encapsulated within `PHPhotoLibrary.shared().performChanges(_:completionHandler:)` closures.
*   **Metadata Override**: Instantiates `PHAssetChangeRequest(for: asset)` and forces its `.location` property to a `CLLocation` object sourced from `MapKit` or manual input.

### 3. 构建系统 / Build System
本项目采用“无 Xcode”理念，利用 GitHub Actions 驱动 `macos-14` 节点进行裸机编译：
*   **编译器**: `xcrun swiftc`.
*   **编译模式**: 使用 `-parse-as-library` 标志以支持 `@main` 入口，并开启 `-O -whole-module-optimization`。
*   **链接库**: 手动链接 `SwiftUI`, `Photos`, `PhotosUI`, `MapKit`, `UIKit` 框架。

The project adopts a "Xcode-free" philosophy, utilizing GitHub Actions to drive `macos-14` nodes for bare-metal compilation:
*   **Compiler**: `xcrun swiftc`.
*   **Mode**: Uses `-parse-as-library` flag to support `@main` entry, with `-O -whole-module-optimization` enabled.
*   **Linking**: Manually links `SwiftUI`, `Photos`, `PhotosUI`, `MapKit`, and `UIKit` frameworks.

---

## 已知问题与调试 / Known Issues & Debugging
目前在非越狱设备（iPhone 12, iOS 17+）上使用 Sideloadly 侧载安装时，可能会触发 `ApplicationVerificationFailed` 或 `Guru Meditation 556260@79` 错误。这通常是由于生成的 IPA 缺少合法的 `_CodeSignature` 或 Mach-O 头部 Load Commands 与 Sideloadly 的重签名引擎不匹配导致的。

Currently, sideloading on non-jailbroken devices (iPhone 12, iOS 17+) via Sideloadly may trigger `ApplicationVerificationFailed` or `Guru Meditation 556260@79` errors. This is typically caused by the absence of a valid `_CodeSignature` in the generated IPA or mismatching Mach-O header Load Commands with Sideloadly's re-signing engine.

---

## 贡献与协作 / Contribution & Collaboration
我们欢迎任何形式的 Pull Request (PR) 或 Issue 提交。特别是在以下领域：
*   优化无 Xcode 环境下的代码签名存根。
*   解决 `swiftc` 编译出的二进制在 Sideloadly 上的重签名兼容性问题。
*   适配 iOS 24+ 可能引入的新隐私沙箱策略。

We welcome any Pull Requests (PR) or Issues, especially in the following areas:
*   Optimizing code-signing stubs in Xcode-free environments.
*   Resolving re-signing compatibility issues for binaries compiled by `swiftc` on Sideloadly.
*   Adapting to potential new privacy sandbox policies in iOS 24+.
