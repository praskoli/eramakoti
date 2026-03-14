class MandaliWriterState {
  final String mandaliId;
  final String mandaliName;
  final String challengeId;
  final String challengeName;
  final int challengeTarget;
  final int challengeProgress;
  final String challengeStatus;
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
    required this.challengeStatus,
    required this.mandaliTotal,
    required this.userContribution,
    required this.currentBatchProgress,
    required this.completedBatchCount,
  });

  MandaliWriterState copyWith({
    String? mandaliId,
    String? mandaliName,
    String? challengeId,
    String? challengeName,
    int? challengeTarget,
    int? challengeProgress,
    String? challengeStatus,
    int? mandaliTotal,
    int? userContribution,
    int? currentBatchProgress,
    int? completedBatchCount,
  }) {
    return MandaliWriterState(
      mandaliId: mandaliId ?? this.mandaliId,
      mandaliName: mandaliName ?? this.mandaliName,
      challengeId: challengeId ?? this.challengeId,
      challengeName: challengeName ?? this.challengeName,
      challengeTarget: challengeTarget ?? this.challengeTarget,
      challengeProgress: challengeProgress ?? this.challengeProgress,
      challengeStatus: challengeStatus ?? this.challengeStatus,
      mandaliTotal: mandaliTotal ?? this.mandaliTotal,
      userContribution: userContribution ?? this.userContribution,
      currentBatchProgress: currentBatchProgress ?? this.currentBatchProgress,
      completedBatchCount: completedBatchCount ?? this.completedBatchCount,
    );
  }

  int get currentBatchNumber => completedBatchCount + 1;

  double get batchProgressPercent {
    final progress = currentBatchProgress.clamp(0, 108);
    return progress / 108.0;
  }

  double get challengeProgressPercent {
    if (challengeTarget <= 0) return 0.0;
    final progress = challengeProgress.clamp(0, challengeTarget);
    return progress / challengeTarget;
  }
}