import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'guardix_method_channel.dart';

/// Represents the security status of the current device.
///
/// Returned by [Guardix.getSecurityStatus].
///
class DeviceSecurityStatus {
  /// Whether developer mode or USB debugging is enabled.
  final bool isDeveloperMode;

  /// Whether the app is running on an emulator or simulator.
  final bool isEmulator;

  /// Whether the device is rooted (Android) or jailbroken (iOS).
  final bool isRootedOrJailbroken;

  /// Creates a [DeviceSecurityStatus] instance.
  const DeviceSecurityStatus({
    required this.isDeveloperMode,
    required this.isEmulator,
    required this.isRootedOrJailbroken,
  });


  @override
  String toString() =>
      'DeviceSecurityStatus('
      'isDeveloperMode: $isDeveloperMode, '
      'isEmulator: $isEmulator, '
      'isRootedOrJailbroken: $isRootedOrJailbroken)';
}

/// The platform interface for the guardix plugin.
///
/// Platform implementations must extend this class.
abstract class GuardixPlatform extends PlatformInterface {
  /// Constructs a [GuardixPlatform].
  GuardixPlatform() : super(token: _token);

  static final Object _token = Object();

  static GuardixPlatform _instance = MethodChannelGuardix();

  /// The default instance of [GuardixPlatform] to use.
  static GuardixPlatform get instance => _instance;

  /// Sets the default instance of [GuardixPlatform].
  static set instance(GuardixPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the current [DeviceSecurityStatus] of the device.
  ///
  /// Throws a [PlatformException] if the check fails.
  Future<DeviceSecurityStatus> getSecurityStatus();

  /// Checks if a mock/fake location is being injected.
  ///
  /// If [strictMode] is `true` (default), also returns `true` if any
  /// known GPS spoofing app is installed, even if not currently active.
  ///
  /// If [strictMode] is `false`, only returns `true` when mock location
  /// is actively being used.
  ///
  /// Note: on iOS, [strictMode] has no effect — only active simulation
  /// is detectable via Apple's CoreLocation API.
  Future<bool> checkMockLocation({bool strictMode = true});
}
