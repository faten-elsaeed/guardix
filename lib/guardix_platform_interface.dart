import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'guardix_method_channel.dart';

class DeviceSecurityStatus {
  final bool isDeveloperMode;
  final bool isEmulator;
  final bool isRootedOrJailbroken;

  const DeviceSecurityStatus({
    required this.isDeveloperMode,
    required this.isEmulator,
    required this.isRootedOrJailbroken,
  });

  bool get isCompromised =>
      isDeveloperMode || isEmulator || isRootedOrJailbroken;

  @override
  String toString() =>
      'DeviceSecurityStatus('
      'isDeveloperMode: $isDeveloperMode, '
      'isEmulator: $isEmulator, '
      'isRootedOrJailbroken: $isRootedOrJailbroken)';
}

abstract class GuardixPlatform extends PlatformInterface {
  GuardixPlatform() : super(token: _token);

  static final Object _token = Object();

  static GuardixPlatform _instance = MethodChannelGuardix();

  static GuardixPlatform get instance => _instance;

  static set instance(GuardixPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<DeviceSecurityStatus> getSecurityStatus();
}
