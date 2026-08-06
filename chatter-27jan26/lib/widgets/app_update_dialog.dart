import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lumosocial/common/managers/session_manager.dart';

class AppUpdateDialog extends StatelessWidget {
  final String appVersion;
  final String apkUrl;
  final String updateNotes;
  final bool isForceUpdate;

  const AppUpdateDialog({
    super.key,
    required this.appVersion,
    required this.apkUrl,
    required this.updateNotes,
    required this.isForceUpdate,
  });

  /// Check if a newer version is available and show the dialog
  static Future<void> checkAndShow() async {
    try {
      final settings = SessionManager.shared.getSettings();
      if (settings == null) return;

      final serverVersion = settings.appVersion ?? '1.0.0';
      final apkUrl = settings.apkUrl ?? 'https://social.equipmentmarket.ng/download-app';
      final updateNotes = settings.updateNotes ?? 'New features and improvements are available.';
      final isForceUpdate = (settings.isForceUpdate ?? 0) == 1;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isVersionHigher(serverVersion, currentVersion)) {
        if (Get.context != null) {
          showModalBottomSheet(
            context: Get.context!,
            isScrollControlled: true,
            isDismissible: !isForceUpdate,
            enableDrag: !isForceUpdate,
            backgroundColor: Colors.transparent,
            builder: (context) => AppUpdateDialog(
              appVersion: serverVersion,
              apkUrl: apkUrl,
              updateNotes: updateNotes,
              isForceUpdate: isForceUpdate,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("AppUpdateDialog check failed: $e");
    }
  }

  /// Helper to compare version strings e.g. "1.0.1" > "1.0.0"
  static bool _isVersionHigher(String serverVer, String currentVer) {
    try {
      List<int> serverParts = serverVer.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> currentParts = currentVer.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < max(serverParts.length, currentParts.length); i++) {
        int s = i < serverParts.length ? serverParts[i] : 0;
        int c = i < currentParts.length ? currentParts[i] : 0;
        if (s > c) return true;
        if (s < c) return false;
      }
    } catch (_) {}
    return false;
  }

  static int max(int a, int b) => a > b ? a : b;

  void _onUpdateTapped() async {
    try {
      final uri = Uri.parse(apkUrl.isNotEmpty ? apkUrl : 'https://social.equipmentmarket.ng/download-app');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not launch APK URL: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !isForceUpdate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
        decoration: const BoxDecoration(
          color: Color(0xFF151B28),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x77000000),
              blurRadius: 30,
              spreadRadius: 10,
              offset: Offset(0, -10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isForceUpdate)
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            const SizedBox(height: 20),

            // App Update Animated Icon Header
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF40E378), Color(0xFF188241)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF40E378).withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  )
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.system_update_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title & Version Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "New Update Available",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF40E378).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF40E378), width: 1),
                  ),
                  child: Text(
                    "v$appVersion",
                    style: const TextStyle(
                      color: Color(0xFF40E378),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),

            // Update Release Notes
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                updateNotes.isNotEmpty
                    ? updateNotes
                    : "A new version of LUMO Social is available with latest features, performance improvements, and bug fixes.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 26),

            // Buttons: Update Now & Later
            Row(
              children: [
                if (!isForceUpdate) ...[
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Later",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onUpdateTapped,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF40E378),
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: const Color(0xFF40E378).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Update Now",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
