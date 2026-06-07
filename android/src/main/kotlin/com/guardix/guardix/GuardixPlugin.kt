package com.guardix.guardix

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class GuardixPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    companion object {
        private const val CHANNEL_NAME = "com.guardix.guardix/device_security"
    }

    // ──────────────────────────────────────────────
    // FlutterPlugin lifecycle
    // ──────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ──────────────────────────────────────────────
    // Method calls from Dart
    // ──────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getSecurityStatus" -> {
                try {
                    val status = mapOf(
                        "isDeveloperMode" to isDeveloperModeEnabled(),
                        "isEmulator" to isEmulator(),
                        "isRootedOrJailbroken" to isRooted()
                    )
                    result.success(status)
                } catch (e: Exception) {
                    result.error("SECURITY_CHECK_FAILED", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    // ──────────────────────────────────────────────
    // Developer Mode Detection
    // ──────────────────────────────────────────────

    private fun isDeveloperModeEnabled(): Boolean {
        return isDeveloperOptionsEnabled() || isUsbDebuggingEnabled()
    }

    private fun isDeveloperOptionsEnabled(): Boolean {
        return try {
            Settings.Global.getInt(
                context.contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0
            ) != 0
        } catch (e: Exception) {
            false
        }
    }

    private fun isUsbDebuggingEnabled(): Boolean {
        return try {
            Settings.Global.getInt(
                context.contentResolver, Settings.Global.ADB_ENABLED, 0
            ) != 0
        } catch (e: Exception) {
            false
        }
    }

    // ──────────────────────────────────────────────
    // Emulator Detection
    // ──────────────────────────────────────────────

    private fun isEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic") || Build.FINGERPRINT.startsWith("unknown") || Build.MODEL.contains(
            "google_sdk",
            ignoreCase = true
        ) || Build.MODEL.contains("Emulator", ignoreCase = true) || Build.MODEL.contains(
            "Android SDK built for x86",
            ignoreCase = true
        ) || Build.MANUFACTURER.contains(
            "Genymotion",
            ignoreCase = true
        ) || Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic") || Build.PRODUCT.contains(
            "sdk",
            ignoreCase = true
        ) || Build.PRODUCT.contains("emulator", ignoreCase = true) || Build.HARDWARE.contains(
            "goldfish",
            ignoreCase = true
        ) || Build.HARDWARE.contains("ranchu", ignoreCase = true) || Build.BOARD.lowercase()
            .contains("nox") || Build.BOOTLOADER.lowercase()
            .contains("nox") || Build.HARDWARE.lowercase() == "vbox86" || Build.PRODUCT.lowercase() == "vbox86p" || Build.DEVICE.lowercase()
            .contains("vbox") || Build.FINGERPRINT.lowercase().contains("vbox"))
    }

    // ──────────────────────────────────────────────
    // Root Detection
    // ──────────────────────────────────────────────
    private fun isRooted(): Boolean {
        return checkSuBinary()
                || checkRootApps()
                || checkSystemWritable()
                || checkFrida()
                || checkZygiskAndShamiko()
    }

    private fun checkSuBinary(): Boolean {
        val paths = arrayOf(
            "/system/bin/su",
            "/system/xbin/su",
            "/sbin/su",
            "/data/local/su",
            "/data/local/bin/su",
            "/data/local/xbin/su",
            "/system/sd/xbin/su",
            "/system/app/Superuser.apk",
            "/cache/su",
            "/data/su",
            "/dev/su",
            // Magisk modern paths
            "/debug_ramdisk/su",
            "/sbin/.magisk/db",
            "/data/adb/magisk",
            "/data/adb/magisk.db",
            "/data/adb/modules",
            "/data/adb/post-fs-data.d",
            "/data/adb/service.d"
        )
        return paths.any { path ->
            try {
                java.io.File(path).exists()
            } catch (e: Exception) {
                false
            }
        }
    }

    private fun checkRootApps(): Boolean {
        val rootPackages = arrayOf(
            "com.topjohnwu.magisk",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.noshufou.android.su",
            "com.thirdparty.superuser",
            "com.yellowes.su",
            "com.zachspong.temprootremovejb",
            "com.ramdroid.appquarantine",
            "com.devadvance.rootcloak",
            "com.devadvance.rootcloakplus",
            "de.robv.android.xposed.installer",
            "com.saurik.substrate"
        )
        val pm = context.packageManager
        return rootPackages.any { pkg ->
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getPackageInfo(pkg, PackageManager.PackageInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION") pm.getPackageInfo(pkg, PackageManager.GET_ACTIVITIES)
                }
                true
            } catch (e: Exception) {
                false
            }
        }
    }

    private fun checkSystemWritable(): Boolean {
        // Method 1: try writing directly to /system
        return try {
            val file = java.io.File("/system/guardix_test")
            if (file.exists()) {
                // If this file exists, system was already written to
                return true
            }
            file.createNewFile().also { created ->
                if (created) file.delete()
            }
        } catch (e: Exception) {
            // Expected on non-rooted devices — /system is read-only
            false
        }
    }

    private fun isFridaPortOpen(): Boolean {
        val ports = intArrayOf(27042, 27043, 4444)
        for (port in ports) {
            try {
                val socket = java.net.Socket()
                socket.connect(
                    java.net.InetSocketAddress("127.0.0.1", port), 100
                )
                socket.close()
                return true
            } catch (e: Exception) {
                // port not open — continue
            }
        }
        return false
    }

    private fun isFridaLibraryLoaded(): Boolean {
        return checkMapsFile().first
    }

    private fun checkFrida(): Boolean {
        return isFridaPortOpen() || isFridaLibraryLoaded()
    }


    private fun checkZygiskAndShamiko(): Boolean {
        val paths = arrayOf(
            "/data/adb/modules/shamiko",
            "/data/adb/modules/zygisksu",
            "/data/adb/modules/.zygisk",
            "/data/misc/adb/shamiko"
        )
        for (path in paths) {
            try {
                if (java.io.File(path).exists()) return true
            } catch (e: Exception) {
                continue
            }
        }
        val (_, hasZygisk, hasShamiko) = checkMapsFile()
        return hasZygisk || hasShamiko
    }


    private fun checkMapsFile(): Triple<Boolean, Boolean, Boolean> {
        return try {
            val maps = java.io.File("/proc/self/maps").readText()
            Triple(
                suspiciousFridaPatterns.any { maps.contains(it, ignoreCase = true) },
                maps.contains("zygisk", ignoreCase = true),
                maps.contains("shamiko", ignoreCase = true)
            )
        } catch (e: Exception) {
            Triple(false, false, false)
        }
    }

    private val suspiciousFridaPatterns = listOf(
        "frida", "gadget", "injector", "libfrida", "frida-agent"
    )

}