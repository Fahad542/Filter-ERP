class TechnicianDashboardKpis {
  final bool success;
  final int month;
  final int year;
  final String? from;
  final String? to;
  final String? businessTimeZone;
  final int jobsCompleted;
  final double revenueEarned;
  final double commissionEarned;

  TechnicianDashboardKpis({
    required this.success,
    required this.month,
    required this.year,
    this.from,
    this.to,
    this.businessTimeZone,
    required this.jobsCompleted,
    required this.revenueEarned,
    required this.commissionEarned,
  });

  factory TechnicianDashboardKpis.fromJson(Map<String, dynamic> json) {
    return TechnicianDashboardKpis(
      success: json['success'] ?? false,
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      from: json['from']?.toString(),
      to: json['to']?.toString(),
      businessTimeZone: json['businessTimeZone']?.toString(),
      jobsCompleted: json['jobsCompleted'] ?? 0,
      revenueEarned: (json['revenueEarned'] ?? 0).toDouble(),
      commissionEarned: (json['commissionEarned'] ?? 0).toDouble(),
    );
  }
}
