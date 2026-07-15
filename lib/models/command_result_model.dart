class CommandResult {
  final String commandId;
  final bool success;
  final String? error;
  final Map<String, dynamic> data;
  final DateTime completedAt;

  const CommandResult({
    required this.commandId,
    required this.success,
    this.error,
    this.data = const {},
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  factory CommandResult.success(Map<String, dynamic> data) {
    return CommandResult(
      commandId: data['commandId'] as String? ?? '',
      success: true,
      data: data,
    );
  }

  factory CommandResult.failure(String commandId, String error) {
    return CommandResult(
      commandId: commandId,
      success: false,
      error: error,
    );
  }

  Map<String, dynamic> toJson() => {
    'commandId': commandId,
    'success': success,
    'error': error,
    'data': data,
    'completedAt': completedAt.toIso8601String(),
  };
}