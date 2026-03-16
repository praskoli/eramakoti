import '../../models/temple_config.dart';

class SupportTarget {
  final String upiId;
  final String payeeName;
  final String label;

  const SupportTarget({
    required this.upiId,
    required this.payeeName,
    required this.label,
  });
}

class SupportTargetResolver {
  static SupportTarget resolve({
    required TempleConfig? temple,
    required String defaultUpiId,
    required String defaultPayeeName,
    String defaultLabel = 'eRamakoti Support',
  }) {
    if (temple != null &&
        temple.supportEnabled &&
        temple.hasValidSupportConfig) {
      return SupportTarget(
        upiId: temple.upiId,
        payeeName: temple.payeeName,
        label: temple.name,
      );
    }

    return SupportTarget(
      upiId: defaultUpiId,
      payeeName: defaultPayeeName,
      label: defaultLabel,
    );
  }
}
