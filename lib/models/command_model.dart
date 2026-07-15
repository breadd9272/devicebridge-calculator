class CommandModel {
  final String commandId;
  final String action;
  final Map<String, dynamic> payload;
  final DateTime receivedAt;
  CommandStatus status;
  String? resultSummary;
  Map<String, dynamic>? resultData;
  DateTime? completedAt;

  CommandModel({
    required this.commandId,
    required this.action,
    this.payload = const {},
    DateTime? receivedAt,
    this.status = CommandStatus.pending,
    this.resultSummary,
    this.resultData,
    this.completedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  factory CommandModel.fromJson(Map<String, dynamic> json) {
    return CommandModel(
      commandId: json['commandId'] as String? ?? '',
      action: json['action'] as String? ?? '',
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'commandId': commandId,
    'action': action,
    'payload': payload,
    'receivedAt': receivedAt.toIso8601String(),
    'status': status.name,
    'resultSummary': resultSummary,
    'resultData': resultData,
    'completedAt': completedAt?.toIso8601String(),
  };
}