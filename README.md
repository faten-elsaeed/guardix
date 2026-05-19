# guardix

A Flutter plugin for device security checks on Android and iOS.

Detects three categories of security concerns:
- **Root / jailbreak** — su binaries, root apps, system write access (Android) · suspicious files, sandbox violations, dylib injection (iOS)
- **Emulator / simulator** — build fingerprints, hardware identifiers, environment variables
- **Developer mode** — developer options, USB debugging (Android) · debugger attachment, Frida instrumentation (iOS)

## Platform support

| Android | iOS |
|---------|-----|
| ✅ | ✅ |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  guardix: ^0.1.0
```

### Android setup

Add the following `<queries>` block to your app's `android/app/src/main/AndroidManifest.xml`
inside the root `<manifest>` tag:

```xml
<queries>
    <package android:name="com.topjohnwu.magisk" />
    <package android:name="eu.chainfire.supersu" />
    <package android:name="com.koushikdutta.superuser" />
    <package android:name="com.noshufou.android.su" />
    <package android:name="com.thirdparty.superuser" />
    <package android:name="com.yellowes.su" />
    <package android:name="com.zachspong.temprootremovejb" />
    <package android:name="com.ramdroid.appquarantine" />
    <package android:name="com.devadvance.rootcloak" />
    <package android:name="com.devadvance.rootcloakplus" />
    <package android:name="de.robv.android.xposed.installer" />
    <package android:name="com.saurik.substrate" />
</queries>
```

### iOS setup

Add the following to your app's `ios/Runner/Info.plist` inside the root `<dict>`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>cydia</string>
    <string>sileo</string>
    <string>zbra</string>
    <string>undecimus</string>
    <string>filza</string>
</array>
```

## Usage

```dart
import 'package:guardix/guardix.dart';

final status = await Guardix.getSecurityStatus();

// Check individual flags
print(status.isDeveloperMode);        // true / false
print(status.isEmulator);             // true / false
print(status.isRootedOrJailbroken);   // true / false

// Or check if anything is wrong at once
if (status.isCompromised) {
  // Block access, show warning, log the event, etc.
}
```

### Example — block the app on compromised devices

```dart
@override
void initState() {
  super.initState();
  _checkDevice();
}

Future<void> _checkDevice() async {
  final status = await Guardix.getSecurityStatus();
  if (status.isCompromised && mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Security check failed'),
        content: const Text(
          'This app cannot run on rooted, jailbroken, or compromised devices.'),
        actions: [
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
```

## API reference

### `Guardix.getSecurityStatus()`

Returns a `DeviceSecurityStatus` object.

### `DeviceSecurityStatus`

| Property | Type | Description |
|---|---|---|
| `isDeveloperMode` | `bool` | Developer options or USB debugging enabled |
| `isEmulator` | `bool` | Running on an emulator or simulator |
| `isRootedOrJailbroken` | `bool` | Device is rooted (Android) or jailbroken (iOS) |
| `isCompromised` | `bool` | `true` if any of the above are `true` |

## Important notes

- Detection can be bypassed by sophisticated tools such as Magisk Hide or Zygisk on
  Android and rootless jailbreaks on iOS. No purely user-space solution is bypass-proof.
- The `isCompromised` flag on emulators will be `true` for `isEmulator` — factor
  this into your logic during development.
- The encrypted binary check (`hasInjectedCode`) is skipped in debug builds to
  avoid false positives.

## License

MIT