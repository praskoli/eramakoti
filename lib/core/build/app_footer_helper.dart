import 'package:package_info_plus/package_info_plus.dart';

import 'build_info.dart';
import 'build_mode_helper.dart';

class AppFooterHelper {
  static Future<String> getFooterText() async {
    final info = await PackageInfo.fromPlatform();

    final version = info.version;
    final buildNumber = info.buildNumber;
    final mode = getBuildModeLabel();

    final buildTime = BuildInfo.buildTime.trim();
    final gitHash = BuildInfo.gitHash.trim();

    final parts = <String>[
      'v$version ($buildNumber)',
      mode,
    ];

    if (buildTime.isNotEmpty) {
      parts.add(buildTime);
    }

    if (gitHash.isNotEmpty) {
      parts.add(gitHash);
    }

    return parts.join(' · ');
  }
}