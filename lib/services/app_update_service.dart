import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateResult {
  final bool force;
  final bool optional;
  final String? url;

  const AppUpdateResult._({
    required this.force,
    required this.optional,
    required this.url,
  });

  factory AppUpdateResult.none() {
    return const AppUpdateResult._(
      force: false,
      optional: false,
      url: null,
    );
  }

  factory AppUpdateResult.force(String url) {
    return AppUpdateResult._(
      force: true,
      optional: false,
      url: url,
    );
  }

  factory AppUpdateResult.optional(String url) {
    return AppUpdateResult._(
      force: false,
      optional: true,
      url: url,
    );
  }
}

class AppUpdateService {
  AppUpdateService._();

  static Future<AppUpdateResult> check() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      print('UPDATE_CHECK currentBuild=$currentBuild');

      print('UPDATE_CHECK before firestore read');
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version')
          .get();
      print('UPDATE_CHECK after firestore read');

      print('UPDATE_CHECK docExists=${doc.exists}');

      if (!doc.exists) {
        print('UPDATE_CHECK returning NONE because doc does not exist');
        return AppUpdateResult.none();
      }

      final data = doc.data();
      print('UPDATE_CHECK rawData=$data');

      if (data == null) {
        print('UPDATE_CHECK returning NONE because data is null');
        return AppUpdateResult.none();
      }

      final dynamic minRaw = data['min_version'];
      final dynamic latestRaw = data['latest_version'];
      final dynamic forceRaw = data['force_update'];
      final dynamic urlRaw = data['playstore_url'];

      print('UPDATE_CHECK minRaw=$minRaw');
      print('UPDATE_CHECK latestRaw=$latestRaw');
      print('UPDATE_CHECK forceRaw=$forceRaw');
      print('UPDATE_CHECK urlRaw=$urlRaw');

      final int minVersion = minRaw is num ? minRaw.toInt() : 0;
      final int latestVersion = latestRaw is num ? latestRaw.toInt() : 0;
      final bool forceUpdate = forceRaw is bool ? forceRaw : false;
      final String playUrl = urlRaw is String ? urlRaw.trim() : '';

      print(
        'UPDATE_CHECK parsed min=$minVersion latest=$latestVersion force=$forceUpdate playUrl=$playUrl',
      );

      if (playUrl.isEmpty) {
        print('UPDATE_CHECK returning NONE because playUrl is empty');
        return AppUpdateResult.none();
      }

      if (forceUpdate && currentBuild < minVersion) {
        print('UPDATE_CHECK returning FORCE');
        return AppUpdateResult.force(playUrl);
      }

      if (currentBuild < latestVersion) {
        print('UPDATE_CHECK returning OPTIONAL');
        return AppUpdateResult.optional(playUrl);
      }

      print('UPDATE_CHECK returning NONE because version is allowed');
      return AppUpdateResult.none();
    } catch (e, st) {
      print('UPDATE_CHECK exception=$e');
      print('UPDATE_CHECK stack=$st');
      return AppUpdateResult.none();
    }
  }
}