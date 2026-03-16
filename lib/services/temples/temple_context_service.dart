import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/temple_config.dart';
import 'temple_repository.dart';

class TempleContextService extends ChangeNotifier {
  TempleContextService({TempleRepository? repository})
      : _repository = repository ?? TempleRepository();

  static const String _prefsTempleIdKey = 'current_temple_id';

  final TempleRepository _repository;

  TempleConfig? _currentTemple;
  bool _initialized = false;
  bool _loading = false;

  TempleConfig? get currentTemple => _currentTemple;
  bool get isTempleMode => _currentTemple != null;
  bool get isInitialized => _initialized;
  bool get isLoading => _loading;
  String? get currentTempleId => _currentTemple?.id;

  Future<void> initialize() async {
    if (_initialized) return;

    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTempleId = prefs.getString(_prefsTempleIdKey);

      if (savedTempleId != null && savedTempleId.trim().isNotEmpty) {
        final temple = await _repository.fetchTempleById(savedTempleId.trim());

        if (temple != null) {
          _currentTemple = temple;
        } else {
          await prefs.remove(_prefsTempleIdKey);
          _currentTemple = null;
        }
      }
    } finally {
      _initialized = true;
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> activateTempleById(String templeId) async {
    final sanitizedId = templeId.trim();
    debugPrint('activateTempleById called with: $sanitizedId');

    if (sanitizedId.isEmpty) return false;

    _loading = true;
    notifyListeners();

    try {
      final temple = await _repository.fetchTempleById(sanitizedId);
      debugPrint('Fetched temple: ${temple?.id}');

      if (temple == null) {
        _loading = false;
        notifyListeners();
        return false;
      }

      _currentTemple = temple;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsTempleIdKey, temple.id);

      debugPrint('Temple context set: ${_currentTemple?.id}');
      return true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> clearTempleContext() async {
    _currentTemple = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsTempleIdKey);

    notifyListeners();
  }

  Future<void> refreshCurrentTemple() async {
    final templeId = _currentTemple?.id;
    if (templeId == null || templeId.isEmpty) return;

    _loading = true;
    notifyListeners();

    try {
      final temple = await _repository.fetchTempleById(templeId);

      if (temple == null) {
        await clearTempleContext();
        return;
      }

      _currentTemple = temple;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
