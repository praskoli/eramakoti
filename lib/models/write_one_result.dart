class WriteOneResult {
  final int currentRunCount;
  final int totalCount;
  final int todayCount;
  final bool batchCompleted;
  final bool runCompleted;

  WriteOneResult({
    required this.currentRunCount,
    required this.totalCount,
    required this.todayCount,
    required this.batchCompleted,
    required this.runCompleted,
  });
}