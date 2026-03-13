class CertificateInput {
  final String certificateId;
  final String runId;
  final String uid;
  final String devoteeName;
  final int completedCount;
  final DateTime completedAt;
  final String certificateLanguage;

  const CertificateInput({
    required this.certificateId,
    required this.runId,
    required this.uid,
    required this.devoteeName,
    required this.completedCount,
    required this.completedAt,
    required this.certificateLanguage,
  });

  String get fileName => '${certificateId}_$certificateLanguage.pdf';
}