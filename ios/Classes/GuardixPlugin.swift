import Flutter
import UIKit
import MachO
import Darwin

public class GuardixPlugin: NSObject, FlutterPlugin {

    static let channelName = "com.guardix.guardix/device_security"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = GuardixPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getSecurityStatus":
            let status: [String: Bool] = [
                "isDeveloperMode": isDeveloperModeEnabled(),
                "isEmulator": isSimulator(),
                "isRootedOrJailbroken": isJailbroken()
            ]
            result(status)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Developer Mode Detection

    private func isDeveloperModeEnabled() -> Bool {
        if #available(iOS 16.0, *) {
            var value: Int32 = 0
            var size = MemoryLayout<Int32>.size
            if sysctlbyname("security.mac.amfi.developer_mode_status",
                            &value, &size, nil, 0) == 0 {
                return value != 0
            }
        }
        return isDebuggerAttached()
            || isFridaDetected()
            || hasSuspiciousEnvironment()
            || hasInjectedCode()
    }

    private func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    private func isFridaDetected() -> Bool {
        if isFridaPortOpen() { return true }
        if isFridaLibraryLoaded() { return true }
        return false
    }

   private func isFridaPortOpen() -> Bool {
       let ports: [UInt16] = [27042, 27043, 4444]
       let group = DispatchGroup()
       let queue = DispatchQueue.global(qos: .userInitiated)
       let lock = NSLock()
       var detected = false

       for port in ports {
           group.enter()
           queue.async {

               defer { group.leave() }
                  lock.lock()
               let alreadyFound = detected
               lock.unlock()
               guard !alreadyFound else { return }

               var addr = sockaddr_in()
               addr.sin_family = sa_family_t(AF_INET)
               addr.sin_port = port.bigEndian
               addr.sin_addr.s_addr = inet_addr("127.0.0.1")

               let sock = socket(AF_INET, SOCK_STREAM, 0)
               guard sock >= 0 else { return }
               defer { close(sock) }

               var timeout = timeval(tv_sec: 0, tv_usec: 100_000)
               setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout,
                          socklen_t(MemoryLayout<timeval>.size))
               setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout,
                          socklen_t(MemoryLayout<timeval>.size))
               let connectResult = withUnsafePointer(to: &addr) {
                   $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                       connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                   }
               }
               if connectResult == 0 {
                   lock.lock()
                   detected = true
                   lock.unlock()
               }
           }
       }

       group.wait()
       return detected
   }

    private func isFridaLibraryLoaded() -> Bool {
        let suspiciousPatterns = [
            "frida", "FridaGadget", "frida-agent",
            "cynject", "libcycript",
            "SSLKillSwitch", "SSLKillSwitch2",
            "A-Bypass", "shadow",
            "objection", "needle",
            "zygisk", "shamiko"
        ]
        let count = _dyld_image_count()
        for i in 0..<count {
            guard let name = _dyld_get_image_name(i) else { continue }
            let lower = String(cString: name).lowercased()
            if suspiciousPatterns.contains(where: { lower.contains($0.lowercased()) }) {
                return true
            }
        }
        return false
    }

    private func hasSuspiciousEnvironment() -> Bool {
        let env = ProcessInfo.processInfo.environment
        let suspiciousKeys = [
            "DYLD_INSERT_LIBRARIES",
            "DYLD_LIBRARY_PATH",
            "DYLD_FRAMEWORK_PATH",
            "FRIDA_LOADER_DYLIB",
        ]
        for key in suspiciousKeys {
            if env[key] != nil { return true }
        }
        if env["SIMULATOR_DEVICE_NAME"] != nil { return true }
        return false
    }

    private func hasInjectedCode() -> Bool {
        #if DEBUG
        return false
        #else
        guard let header = _dyld_get_image_header(0) else { return false }

        var lc = UnsafeRawPointer(header)
            .advanced(by: MemoryLayout<mach_header_64>.size)

        let headerPtr = header.withMemoryRebound(
            to: mach_header_64.self, capacity: 1) { $0 }
        let ncmds = headerPtr.pointee.ncmds

        for _ in 0..<ncmds {
            let cmd = lc.load(as: load_command.self)
            if cmd.cmd == LC_ENCRYPTION_INFO_64 {
                let encCmd = lc.load(as: encryption_info_command_64.self)
                if encCmd.cryptid == 0 { return true }
            }
            lc = lc.advanced(by: Int(cmd.cmdsize))
        }
        return false
        #endif
    }

    // MARK: - Simulator Detection

    private func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        if ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil {
            return true
        }
        return false
        #endif
    }

    // MARK: - Jailbreak Detection

    private func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return checkSuspiciousFiles()
            || checkSuspiciousURLSchemes()
            || checkSandboxViolation()
            || checkSymlinks()
            || checkDylibs()
            || isFridaDetected()
        #endif
    }

    private func checkSuspiciousFiles() -> Bool {
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/usr/sbin/sshd",
            "/usr/bin/sshd",
            "/usr/libexec/sftp-server",
            "/etc/apt",
            "/etc/apt/sources.list.d",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/private/var/stash",
            "/private/var/tmp/cydia.log",
            "/bin/bash",
            "/usr/sbin/frida-server",
            "/usr/bin/cycript",
            "/usr/local/bin/cycript",
            "/usr/lib/libcycript.dylib",
            "/var/cache/apt",
            "/var/lib/apt",
            "/var/lib/cydia",
            "/var/log/syslog",
            "/bin/sh",
            "/usr/libexec/cydia/firmware.sh",
            "/var/jb/usr/bin/su",
            "/var/jb/bin/bash",
            "/var/jb/usr/sbin/sshd",
            "/var/jb/Library/MobileSubstrate",
            "/var/jb/Applications/Cydia.app",
            "/var/jb/Applications/Sileo.app",
            "/var/jb/usr/sbin/frida-server",
            "/var/jb/.installed_dopamine",
            "/var/jb/.installed_palera1n",
            "/.bootstrapped_electra",
            "/electra/jailbreakd",
            "/.installed_unc0ver",
            "/checkra1n"
        ]

        for path in suspiciousPaths {
            if FileManager.default.fileExists(atPath: path) { return true }
            if FileManager.default.isReadableFile(atPath: path) { return true }
        }
        return false
    }

    private func checkSuspiciousURLSchemes() -> Bool {
        let schemes = [
            "cydia://package/com.example.package",
            "sileo://package/com.example.package",
            "zbra://packages/com.example.package",
            "undecimus://",
            "filza://"
        ]
        for scheme in schemes {
            if let url = URL(string: scheme),
               UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        return false
    }

    private func checkSandboxViolation() -> Bool {
        let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
        do {
            try "jb_test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }

    private func checkSymlinks() -> Bool {
        let suspiciousSymlinks = [
            "/var/lib/undecimus/apt",
            "/Library/MobileSubstrate/DynamicLibraries",
            "/jb/amfid_payload.dylib",
            "/jb/libjailbreak.dylib",
            "/var/jb",
            "/var/jb/usr/lib/TweakInject",
            "/var/jb/Library/MobileSubstrate/DynamicLibraries"
        ]
        for path in suspiciousSymlinks {
            if FileManager.default.fileExists(atPath: path) { return true }
        }
        return false
    }

    private func checkDylibs() -> Bool {
        let suspiciousLibs = [
            "SubstrateLoader",
            "MobileSubstrate",
            "TweakInject",
            "cycript",
            "libcycript"
        ]
        let count = _dyld_image_count()
        for i in 0..<count {
            guard let imageName = _dyld_get_image_name(i) else { continue }
            let name = String(cString: imageName)
            for lib in suspiciousLibs {
                if name.lowercased().contains(lib.lowercased()) { return true }
            }
        }
        return false
    }
}