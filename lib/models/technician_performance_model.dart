class TechnicianPerformance {
  final bool? success;
  final int? totalJobs;
  final double? earned;
  final List<WeeklyOverview>? weeklyOverview;
  final List<dynamic>? recentJobs;

  TechnicianPerformance({
    this.success,
    this.totalJobs,
    this.earned,
    this.weeklyOverview,
    this.recentJobs,
  });

  factory TechnicianPerformance.fromJson(Map<String, dynamic> json) {
    return TechnicianPerformance(
      success: json['success'],
      totalJobs: json['totalJobs'],
      earned: json['earned']?.toDouble(),
      weeklyOverview: (json['weeklyOverview'] as List?)
          ?.map((e) => WeeklyOverview.fromJson(e))
          .toList(),
      recentJobs: json['recentJobs'],
    );
  }
}

class WeeklyOverview {
  final String? day;
  final double? amount;

  WeeklyOverview({this.day, this.amount});

  factory WeeklyOverview.fromJson(Map<String, dynamic> json) {
    return WeeklyOverview(
      day: json['day'],
      amount: json['amount']?.toDouble(),
    );
  }
}
