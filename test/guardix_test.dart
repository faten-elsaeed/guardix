import 'package:flutter_test/flutter_test.dart';
import 'package:guardix/guardix_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGuardixPlatform
    with MockPlatformInterfaceMixin
    implements GuardixPlatform {
  @override
  Future<DeviceSecurityStatus> getSecurityStatus() {
    throw UnimplementedError();
  }

  @override
  Future<bool> checkMockLocation({bool strictMode = true}) {
    throw UnimplementedError();
  }
}

void main() {}
