import 'guardix_platform_interface.dart';
export 'guardix_platform_interface.dart' show DeviceSecurityStatus;

class Guardix {
  static Future<DeviceSecurityStatus> getSecurityStatus() {
    return GuardixPlatform.instance.getSecurityStatus();
  }
}
