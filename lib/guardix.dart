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
}
