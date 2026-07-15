import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../models/enums.dart';

class CommandLogScreen extends ConsumerWidget {
  const CommandLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commands = ref.watch(commandLogProvider);
    CommandStatus? filter;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Scaffold(
          backgroundColor: AppColors.bridgeBg,
          appBar: AppBar(
            backgroundColor: AppColors.bridgeBg,
            foregroundColor: AppColors.bridgeTextPrimary,
            title: const Text('Command Log'),
            elevation: 0,
            actions: [
              PopupMenuButton<CommandStatus?>(
                icon: const Icon(Icons.filter_list, color: AppColors.bridgeTextSecondary),
                onSelected: (value) => setLocalState(() => filter = value),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('All')),
                  const PopupMenuItem(value: CommandStatus.success, child: Text('Success')),
                  const PopupMenuItem(value: CommandStatus.error, child: Text('Error')),
                ],
              ),
              if (commands.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.bridgeError),
                  onPressed: () => ref.read(commandLogProvider.notifier).clear(),
                ),
            ],
          ),
          body: commands.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.terminal, color: AppColors.bridgeTextSecondary, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'No commands received yet',
                        style: TextStyle(color: AppColors.bridgeTextSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: commands.length,
                  itemBuilder: (context, index) {
                    final cmd = commands[index];

                    // Apply filter
                    if (filter != null && cmd.status != filter) {
                      return const SizedBox.shrink();
                    }

                    return _CommandTile(command: cmd);
                  },
                ),
        );
      },
    );
  }
}

class _CommandTile extends StatelessWidget {
  final dynamic command;

  const _CommandTile({required this.command});

  @override
  Widget build(BuildContext context) {
    // Re-read the actual command type
    final cmd = command;
    final statusColor = _statusColor(cmd.status);
    final statusIcon = _statusIcon(cmd.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.bridgeCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bridgeCardBorder),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Icon(statusIcon, color: statusColor, size: 20),
        title: Text(
          cmd.action,
          style: const TextStyle(
            color: AppColors.bridgeTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _formatTime(cmd.receivedAt),
          style: const TextStyle(color: AppColors.bridgeTextSecondary, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            cmd.status.name.toUpperCase(),
            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        children: [
          if (cmd.resultSummary != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                cmd.resultSummary!,
                style: const TextStyle(color: AppColors.bridgeTextPrimary, fontSize: 13),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _formatJson(cmd.payload.toString()),
              style: const TextStyle(
                color: AppColors.bridgeTextSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(CommandStatus status) {
    switch (status) {
      case CommandStatus.success:
        return AppColors.bridgeSuccess;
      case CommandStatus.error:
      case CommandStatus.timeout:
        return AppColors.bridgeError;
      case CommandStatus.executing:
        return AppColors.bridgeWarning;
      default:
        return AppColors.bridgeTextSecondary;
    }
  }

  IconData _statusIcon(CommandStatus status) {
    switch (status) {
      case CommandStatus.success:
        return Icons.check_circle;
      case CommandStatus.error:
        return Icons.error;
      case CommandStatus.timeout:
        return Icons.timer_off;
      case CommandStatus.executing:
        return Icons.hourglass_top;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }

  String _formatJson(String raw) {
    try {
      // Try to pretty print if it looks like JSON
      if (raw.startsWith('{') || raw.startsWith('[')) {
        return raw;
      }
    } catch (_) {}
    return raw;
  }
}