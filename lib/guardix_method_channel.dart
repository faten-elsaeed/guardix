import 'package:flutter/services.dart';
import 'guardix_platform_interface.dart';

class MethodChannelGuardix extends GuardixPlatform {
  final MethodChannel _channel = const MethodChannel(
    'com.guardix.guardix/device_security',
  );

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
