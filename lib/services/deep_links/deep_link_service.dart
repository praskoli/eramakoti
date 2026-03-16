import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../temples/temple_context_service.dart';

class DeepLinkService {
  DeepLinkService(this._templeContextService);

  final TempleContextService _templeContextService;
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    debugPrint('DeepLinkService.start called');

    try {
      final initialUri = await _appLinks.getInitialLink();
      debugPrint('Initial URI: $initialUri');

      if (initialUri != null) {
        await _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('Initial deep link error: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
          (uri) async {
        debugPrint('Stream URI: $uri');
        await _handleUri(uri);
      },
      onError: (error) {
        debugPrint('Deep link stream error: $error');
      },
    );
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  Future<void> _handleUri(Uri uri) async {
    debugPrint('Handling URI: $uri');

    final templeId = parseTempleId(uri);
    debugPrint('Parsed templeId: $templeId');

    if (templeId == null || templeId.isEmpty) return;

    final activated = await _templeContextService.activateTempleById(templeId);
    debugPrint('Temple activated: $activated');
  }

  String? parseTempleId(Uri uri) {
    if (uri.scheme == 'eramakoti' && uri.host == 'temple') {
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first.trim();
      }
    }

    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments.first == 'temple') {
      return uri.pathSegments[1].trim();
    }

    return null;
  }
}