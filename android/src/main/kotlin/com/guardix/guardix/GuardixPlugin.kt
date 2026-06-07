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

import android.util.Log

class GuardixPlugin : FlutterPlugin, MethodCallHandler {

    private val tag = "GuardixPlugin"

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
                val executor = java.util.concurrent.Executors.newSingleThreadExecutor()
                executor.execute {
                    try {
                        val status = mapOf(
                            "isDeveloperMode" to isDeveloperModeEnabled(),
                            "isEmulator" to isEmulator(),
                            "isRootedOrJailbroken" to isRooted()
                        )
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            result.success(status)
                        }
                    } catch (e: Exception) {
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            result.error("SECURITY_CHECK_FAILED", e.message, null)
                        }
                    } finally {
                        executor.shutdown()
                    }
                }
            }

            "isMockLocation" -> {
                val executor = java.util.concurrent.Executors.newSingleThreadExecutor()
                executor.execute {
                    try {
                        val strictMode = call.argument<Boolean>("strictMode") ?: true
                        val mockResult = isMockLocation(strictMode = strictMode)
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            result.success(mockResult)
                        }
                    } catch (e: Exception) {
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            result.error("MOCK_LOCATION_CHECK_FAILED", e.message, null)
                        }
                    } finally {
                        executor.shutdown()
                    }
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


    // ──────────────────────────────────────────────
    // Mock Location Detection
    // ──────────────────────────────────────────────
    private fun isMockLocation(strictMode: Boolean = true): Boolean {
        val isActiveMock = checkMockLocationApi31()
                || checkMockLocationApi23To30()
                || checkMockLocationPreApi23()
        return if (strictMode) {
            Log.d(tag, "strictMode enabled")
            isActiveMock || checkMockLocationApps()
        } else {
            Log.d(tag, "strictMode disabled")
            isActiveMock
        }

    }

    // Android 12+ (API 31+) — official isMock flag on Location object

    private fun checkMockLocationApi31(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        return try {
            val lm = context.getSystemService(Context.LOCATION_SERVICE)
                    as android.location.LocationManager

            val providers = lm.getProviders(true)
            if (providers.isEmpty()) return false

            val provider = when {
                providers.contains(android.location.LocationManager.GPS_PROVIDER) ->
                    android.location.LocationManager.GPS_PROVIDER

                providers.contains(android.location.LocationManager.NETWORK_PROVIDER) ->
                    android.location.LocationManager.NETWORK_PROVIDER

                else -> providers.first()
            }

            // First — check cached location but only trust it if fresh (< 30 seconds)
            val cached = lm.getLastKnownLocation(provider)
            if (cached != null) {
                val age = System.currentTimeMillis() - cached.time
                if (age < 30_000) {
                    // Fresh cache — trust the isMock flag directly
                    return cached.isMock
                }
                // Stale cache — if isMock is false we can trust it
                // Only if isMock is true do we need to verify with a fresh request
                if (!cached.isMock) return false
            }

            // Cache is stale AND was marked mock — verify with fresh location
            val latch = java.util.concurrent.CountDownLatch(1)
            var isMock = false
            val cancellationSignal = android.os.CancellationSignal()
            val executor = java.util.concurrent.Executors.newSingleThreadExecutor()

            lm.getCurrentLocation(provider, cancellationSignal, executor) { location ->
                if (location?.isMock == true) isMock = true
                latch.countDown()
            }

            // Reduced timeout to 3 seconds — only reaches here when cache was stale+mock
            val completed = latch.await(3, java.util.concurrent.TimeUnit.SECONDS)
            executor.shutdown()
            if (!completed) cancellationSignal.cancel()

            isMock
        } catch (e: SecurityException) {
            false
        } catch (e: Exception) {
            false
        }
    }


//    private fun checkMockLocationApi31(): Boolean {
//        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
//        return try {
//            val lm = context.getSystemService(Context.LOCATION_SERVICE) as android.location.LocationManager
//            val providers = lm.getProviders(true)
//            for (provider in providers) {
//                // getLastKnownLocation can be null — use requestSingleUpdate fallback
//                val location = lm.getLastKnownLocation(provider)
//
//                Log.d(tag, "location?.isMock")
//                Log.d(tag, location?.isMock.toString()) //print true
//                if (location?.isMock == true) return true
//            }
//            false
//        } catch (e: SecurityException) {
//            // Location permission not granted — fall through to other checks
//            false
//        } catch (e: Exception) {
//            false
//        }
//    }

    // Android 6.0 to 11 (API 23–30) — AppOps check
    private fun checkMockLocationApi23To30(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
        ) return false
        return try {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE)
                    as android.app.AppOpsManager
            appOps.checkOp(
                android.app.AppOpsManager.OPSTR_MOCK_LOCATION,
                android.os.Process.myUid(),
                context.packageName
            ) == android.app.AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }

    // Pre Android 6.0 (below API 23) — Settings.Secure flag
    private fun checkMockLocationPreApi23(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) return false
        return try {
            val setting = android.provider.Settings.Secure.getString(
                context.contentResolver,
                android.provider.Settings.Secure.ALLOW_MOCK_LOCATION
            )
            setting != null && setting != "0"
        } catch (e: Exception) {
            false
        }
    }

    // Check for known mock location / GPS spoofing apps — works even without location permission
    private fun checkMockLocationApps(): Boolean {
        val mockApps = arrayOf(
            "com.lexa.fakegps",
            "com.incorporateapps.fakegps.fre",
            "com.fakegps.mock",
            "com.blogspot.newapphorizons.fakegps",
            "com.hola.fakegps",
            "com.gsmartstudio.fakegps",
            "com.serenegiant.fakegps",
            "ru.gavrikov.mocklocations",
            "com.locationchanger",
            "com.location.changer",
            "com.fly.gps",
            "com.rosteam.gpsemulator",
            "com.gps.fake",
            "com.lexa.fakegpspro",
            "com.byterev.teleport"
        )
        val pm = context.packageManager
        return mockApps.any { pkg ->
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getPackageInfo(pkg, PackageManager.PackageInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    pm.getPackageInfo(pkg, PackageManager.GET_ACTIVITIES)
                }
                true
            } catch (e: Exception) {
                false
            }
        }
    }

}