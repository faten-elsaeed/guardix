import 'package:flutter/services.dart';
import 'guardix_platform_interface.dart';

/// The method channel implementation of [GuardixPlatform].
///
/// Uses a [MethodChannel] to communicate with the native
/// Android and iOS implementations.
class MethodChannelGuardix extends GuardixPlatform {
  /// The method channel used to communicate with native code.
  final MethodChannel _channel = const MethodChannel(
    'com.guardix.guardix/device_security',
  );

  /// Returns the current [DeviceSecurityStatus] from the native platform.
  @override
  Future<DeviceSecurityStatus> getSecurityStatus() async {
    final Map<dynamic, dynamic> result = await _channel.invokeMethod(
      'getSecurityStatus',
    );

    return DeviceSecurityStatus(
      isDeveloperMode: result['isDeveloperMode'] as bool? ?? false,
      isEmulator: result['isEmulator'] as bool? ?? false,
      isRootedOrJailbroken: result['isRootedOrJailbroken'] as bool? ?? false,
    );
  }
}
