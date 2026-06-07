## 0.2.0

* Added mock/fake location detection as a separate method `Guardix.checkMockLocation()`
* `checkMockLocation()` supports `strictMode` option
    * `strictMode: true` (default) — also flags devices with known GPS spoofing apps installed, even if not currently active. Recommended for banking and fintech apps
    * `strictMode: false` — only flags when mock location is actively running
* Android mock location covers API 31+ (`Location.isMock`), API 23–30 (`AppOpsManager`), pre-API 23 (`Settings.Secure`), and 15 known spoofing apps
* iOS mock location uses `CLLocationSourceInformation.isSimulatedBySoftware` (iOS 15+)
* Added Frida detection for Android — port scan (27042, 27043, 4444) and `/proc/self/maps` analysis
* Added Shamiko and Zygisk detection
* Removed `isCompromised` — security policy is now the developer's decision

## 0.1.1

* Added dartdoc comments to all public API elements
* Added Swift Package Manager support for iOS

## 0.1.0

* Initial release
* Android: developer mode, USB debugging, emulator, root detection
* iOS: developer mode, Frida detection, simulator, jailbreak detection