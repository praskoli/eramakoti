class MandaliWriterState {
  final String mandaliId;
  final String mandaliName;
  final String challengeId;
  final String challengeName;
  final int challengeTarget;
  final int challengeProgress;
  final int mandaliTotal;
  final int userContribution;
  final int currentBatchProgress;
  final int completedBatchCount;

  const MandaliWriterState({
    required this.mandaliId,
    required this.mandaliName,
    required this.challengeId,
    required this.challengeName,
    required this.challengeTarget,
    required this.challengeProgress,
    required this.mandaliTotal,
    required this.userContribution,
    required this.currentBatchProgress,
    required this.completedBatchCount,
  });

  int get currentBatchNumber => completedBatchCount + 1;

  double get challengeProgressPercent {
    if (challengeTarget <= 0) return 0;
    final raw = challengeProgress / challengeTarget;
    if (raw < 0) return 0;
    if (raw > 1) return 1;
    return raw;
  }

  double get batchProgressPercent {
    final clamped = currentBatchProgress.clamp(0, 108);
    return clamped / 108;
  }
}
