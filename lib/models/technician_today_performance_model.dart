class TechnicianTodayPerformance {
  final bool? success;
  final int? completedJobs;
  final double? dailyRevenue;
  final double? todayEarned;
  final double? weeklyEarned;
  final int? monthCompletedJobs;
  final double? monthRevenue;

  TechnicianTodayPerformance({
    this.success,
    this.completedJobs,
    this.dailyRevenue,
    this.todayEarned,
    this.weeklyEarned,
    this.monthCompletedJobs,
    this.monthRevenue,
  });

  factory TechnicianTodayPerformance.fromJson(Map<String, dynamic> json) {
    return TechnicianTodayPerformance(
      success: json['success'],
      completedJobs: json['completedJobs'],
      dailyRevenue: json['dailyRevenue']?.toDouble(),
      todayEarned: json['todayEarned']?.toDouble(),
      weeklyEarned: json['weeklyEarned']?.toDouble(),
      monthCompletedJobs: json['monthCompletedJobs'],
      monthRevenue: json['monthRevenue']?.toDouble(),
    );
  }
}
