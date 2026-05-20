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

  /// Returns `true` if any security concern is detected.
  ///
  /// Equivalent to checking if any of [isDeveloperMode],
  /// [isEmulator], or [isRootedOrJailbroken] is `true`.
  bool get isCompromised =>
      isDeveloperMode || isEmulator || isRootedOrJailbroken;

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
}
