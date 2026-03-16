import '../temples/temple_context_service.dart';
enum SupportMode {
  platform,
  temple,
  mandali,
}

class SupportModeResult {
  final SupportMode mode;
  final String label;

  const SupportModeResult({
    required this.mode,
    required this.label,
  });
}

class SupportModeService {
  static SupportModeResult resolve({
    required TempleContextService templeContext,
    String? mandaliName,
    bool forcePlatform = false,
  }) {
    // PLATFORM override
    if (forcePlatform) {
      return const SupportModeResult(
        mode: SupportMode.platform,
        label: 'eRamakoti Platform',
      );
    }

    // MANDALI support
    if (mandaliName != null) {
      return SupportModeResult(
        mode: SupportMode.mandali,
        label: mandaliName,
      );
    }

    // TEMPLE support
    if (templeContext.isTempleMode &&
        templeContext.currentTemple != null) {
      return SupportModeResult(
        mode: SupportMode.temple,
        label: templeContext.currentTemple!.name,
      );
    }

    // Default platform
    return const SupportModeResult(
      mode: SupportMode.platform,
      label: 'eRamakoti Platform',
    );
  }
}