class AgentDashboardModel {
  final String message;
  final int agentId;
  final String agentName;
  final int totalAcceptedLoans;
  final int underReviewLoans;
  final int approvedLoans;
  final int rejectedLoans;

  AgentDashboardModel({
    required this.message,
    required this.agentId,
    required this.agentName,
    required this.totalAcceptedLoans,
    required this.underReviewLoans,
    required this.approvedLoans,
    required this.rejectedLoans,
  });

  factory AgentDashboardModel.fromJson(Map<String, dynamic> json) {
    return AgentDashboardModel(
      message: json['message']?.toString() ?? '',
      agentId: int.tryParse(json['agentId'].toString()) ?? 0,
      agentName: json['agentName']?.toString() ?? '',
      totalAcceptedLoans:
          int.tryParse(json['totalAcceptedLoans'].toString()) ?? 0,
      underReviewLoans: int.tryParse(json['underReviewLoans'].toString()) ?? 0,
      approvedLoans: int.tryParse(json['approvedLoans'].toString()) ?? 0,
      rejectedLoans: int.tryParse(json['rejectedLoans'].toString()) ?? 0,
    );
  }
}
