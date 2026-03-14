class MandaliCertificateInput {
  final String certificateId;
  final String mandaliId;
  final String mandaliName;
  final String challengeName;
  final int challengeTarget;
  final int recipientCount;
  final DateTime completedAt;

  const MandaliCertificateInput({
    required this.certificateId,
    required this.mandaliId,
    required this.mandaliName,
    required this.challengeName,
    required this.challengeTarget,
    required this.recipientCount,
    required this.completedAt,
  });

  String get fileName => '${certificateId}_mandali_certificate.pdf';
}