import 'package:flutter/material.dart';
import 'package:guardix/guardix.dart';

void main() => runApp(const GuardixExampleApp());

class GuardixExampleApp extends StatelessWidget {
  const GuardixExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardix Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFDC2626)),
        useMaterial3: true,
      ),
      home: const SecurityCheckScreen(),
    );
  }
}

class SecurityCheckScreen extends StatefulWidget {
  const SecurityCheckScreen({super.key});

  @override
  State<SecurityCheckScreen> createState() => _SecurityCheckScreenState();
}

class _SecurityCheckScreenState extends State<SecurityCheckScreen> {
  DeviceSecurityStatus? _status;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  Future<void> _runChecks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final status = await Guardix.getSecurityStatus();
      if (mounted)
        setState(() {
          _status = status;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFFDC2626),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guardix',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Device security check',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _runChecks,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBanner(),
            const SizedBox(height: 20),
            const Text(
              'SECURITY CHECKS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            _buildCheckCard(
              icon: Icons.code,
              label: 'Developer mode',
              description: 'USB debugging & developer options',
              value: _status?.isDeveloperMode,
            ),
            const SizedBox(height: 8),
            _buildCheckCard(
              icon: Icons.phone_android_outlined,
              label: 'Emulator / simulator',
              description: 'Running on virtual device',
              value: _status?.isEmulator,
            ),
            const SizedBox(height: 8),
            _buildCheckCard(
              icon: Icons.lock_open_outlined,
              label: 'Root / jailbreak',
              description: 'System integrity',
              value: _status?.isRootedOrJailbroken,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _runChecks,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: const Text('Run checks again'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final isClean = _status != null && !_status!.isCompromised;
    final isWarn = _status != null && _status!.isCompromised;

    Color bg = _isLoading
        ? Colors.grey.shade100
        : isClean
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEE2E2);
    Color fg = _isLoading
        ? Colors.grey
        : isClean
        ? const Color(0xFF15803D)
        : const Color(0xFFDC2626);
    IconData ic = _isLoading
        ? Icons.shield_outlined
        : isClean
        ? Icons.shield
        : Icons.shield_outlined;
    String title = _isLoading
        ? 'Checking device…'
        : isClean
        ? 'Device looks clean'
        : 'Security issue detected';
    String sub = _isLoading
        ? 'Running security checks'
        : isClean
        ? 'No security issues detected'
        : _error ?? 'One or more checks failed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(ic, color: fg, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(fontSize: 12, color: fg.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckCard({
    required IconData icon,
    required String label,
    required String description,
    required bool? value,
  }) {
    final isLoading = value == null;
    final isWarn = value == true;
    Color iconBg = isLoading
        ? Colors.grey.shade100
        : isWarn
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFDCFCE7);
    Color iconFg = isLoading
        ? Colors.grey
        : isWarn
        ? const Color(0xFFDC2626)
        : const Color(0xFF15803D);
    String badge = isLoading
        ? '…'
        : isWarn
        ? 'Detected'
        : 'Clear';
    Color badgeBg = isLoading
        ? Colors.grey.shade100
        : isWarn
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFDCFCE7);
    Color badgeFg = isLoading
        ? Colors.grey
        : isWarn
        ? const Color(0xFFDC2626)
        : const Color(0xFF15803D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconFg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: badgeFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
