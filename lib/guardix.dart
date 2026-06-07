/// A Flutter plugin for device security checks.
///
/// Detects root/jailbreak, emulator/simulator, and developer
/// mode on Android and iOS.
///
/// ## Usage
/// ```dart
/// final status = await Guardix.getSecurityStatus();
/// if (status.isCompromised) {
///   // handle compromised device
/// }
/// ```
library;

import 'guardix_platform_interface.dart';
export 'guardix_platform_interface.dart' show DeviceSecurityStatus;

/// Main entry point for the guardix plugin.
///
/// Use [getSecurityStatus] to check the security state of the device.
class Guardix {
  Guardix._();

  /// Returns the current [DeviceSecurityStatus] of the device.
  ///
  /// Queries the native platform for three security checks:
  /// - [DeviceSecurityStatus.isDeveloperMode]
  /// - [DeviceSecurityStatus.isEmulator]
  /// - [DeviceSecurityStatus.isRootedOrJailbroken]
  ///
  /// Throws a [PlatformException] if the native check fails.
  ///
  /// Example:
  /// ```dart
  /// final status = await Guardix.getSecurityStatus();
  /// if (status.isCompromised) {
  ///   print('Device is compromised!');
  /// }
  /// ```

  static Future<DeviceSecurityStatus> getSecurityStatus() {
    return GuardixPlatform.instance.getSecurityStatus();
  }

  /// Checks if a mock/fake location is being injected.
  ///
  /// [strictMode] `true` (default) — flags device if a known GPS spoofing
  /// app is installed, even if not currently active. Recommended for
  /// banking and fintech apps.
  ///
  /// [strictMode] `false` — only flags when mock location is actively
  /// running. Less strict, fewer false positives.
  ///
  /// Note: on iOS, [strictMode] has no effect — only active software
  /// simulation is detectable via Apple's CoreLocation API.
  ///
  /// Example:
  /// ```dart
  /// // Strict — for banking apps (default)
  /// final isMock = await Guardix.checkMockLocation();
  ///
  /// // Lenient — only flag active spoofing
  /// final isMock = await Guardix.checkMockLocation(strictMode: false);
  /// ```
  static Future<bool> checkMockLocation({bool strictMode = true}) {
    return GuardixPlatform.instance.checkMockLocation(strictMode: strictMode);
  }
}
