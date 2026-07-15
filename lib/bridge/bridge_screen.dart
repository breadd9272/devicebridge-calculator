import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_settings.dart';
import '../../models/enums.dart';
import '../../models/device_status.dart';
import '../../providers/providers.dart';
import '../../services/token_service.dart';
import '../../services/hardware/device_info_service.dart';
import 'connection_panel.dart';
import 'command_log_screen.dart';
import 'settings_screen.dart';

class BridgeScreen extends ConsumerStatefulWidget {
  const BridgeScreen({super.key});

  @override
  ConsumerState<BridgeScreen> createState() => _BridgeScreenState();
}

class _BridgeScreenState extends ConsumerState<BridgeScreen> {
  @override
  void initState() {
    super.initState();
    // Wire command log to connection notifier
    Future.microtask(() {
      ref.read(connectionProvider.notifier).onCommandReceived = (cmd) {
        ref.read(commandLogProvider.notifier).addCommand(cmd);
      };
      ref.read(deviceStatusProvider.notifier).startAutoRefresh();
    });
  }

  @override
  void dispose() {
    ref.read(deviceStatusProvider.notifier).stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionProvider);
    final deviceStatus = ref.watch(deviceStatusProvider);
    final recentCommands = ref.watch(commandLogProvider).take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.bridgeBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.bridgePrimary,
          onRefresh: () async {
            await ref.read(deviceStatusProvider.notifier).refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(connectionStatus),
                const SizedBox(height: 20),

                // Connection Status Card
                _buildConnectionCard(connectionStatus, deviceStatus),
                const SizedBox(height: 16),

                // Action Buttons Grid
                _buildActionGrid(connectionStatus),
                const SizedBox(height: 16),

                // Quick Stats Row
                _buildQuickStats(deviceStatus),
                const SizedBox(height: 16),

                // Recent Commands
                if (recentCommands.isNotEmpty) ...[
                  _buildRecentCommands(recentCommands),
                  const SizedBox(height: 16),
                ],

                // Version footer
                Center(
                  child: Text(
                    'DeviceBridge Pro v1.0.0',
                    style: const TextStyle(color: AppColors.bridgeTextSecondary, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ConnectionStatus status) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.bridgeTextSecondary, size: 22),
          onPressed: () => ref.read(bridgeModeProvider.notifier).state = BridgeMode.calculator,
          tooltip: 'Back to Calculator',
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: status == ConnectionStatus.connected
                ? AppColors.bridgeSuccess
                : status == ConnectionStatus.connecting
                    ? AppColors.bridgeWarning
                    : AppColors.bridgeTextSecondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'DeviceBridge',
          style: TextStyle(
            color: AppColors.bridgeTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        _buildStatusChip(status),
      ],
    );
  }

  Widget _buildStatusChip(ConnectionStatus status) {
    String label;
    Color color;
    switch (status) {
      case ConnectionStatus.connected:
        label = 'Connected';
        color = AppColors.bridgeSuccess;
        break;
      case ConnectionStatus.connecting:
        label = 'Connecting...';
        color = AppColors.bridgeWarning;
        break;
      case ConnectionStatus.error:
        label = 'Error';
        color = AppColors.bridgeError;
        break;
      case ConnectionStatus.disconnected:
        label = 'Disconnected';
        color = AppColors.bridgeTextSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(ConnectionStatus status, DeviceStatus deviceStatus) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bridgeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bridgeCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            status == ConnectionStatus.connected
                ? LucideIcons.link
                : LucideIcons.unlink,
            color: status == ConnectionStatus.connected
                ? AppColors.bridgeSuccess
                : status == ConnectionStatus.connecting
                    ? AppColors.bridgeWarning
                    : AppColors.bridgeError,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            _statusText(status),
            style: TextStyle(
              color: status == ConnectionStatus.connected
                  ? AppColors.bridgeSuccess
                  : AppColors.bridgeTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppSettings.serverUrl,
            style: const TextStyle(color: AppColors.bridgeTextSecondary, fontSize: 13),
          ),
          if (status == ConnectionStatus.connected) ...[
            const SizedBox(height: 12),
            Text(
              'Battery: ${deviceStatus.batteryLevel}% • ${deviceStatus.networkType.toUpperCase()}',
              style: const TextStyle(color: AppColors.bridgeTextSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _statusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected to Dashboard';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.error:
        return 'Connection Error';
      case ConnectionStatus.disconnected:
        return 'Not Connected';
    }
  }

  Widget _buildActionGrid(ConnectionStatus status) {
    final actions = [
      _GridAction(
        label: 'Connect',
        icon: LucideIcons.link,
        color: AppColors.bridgePrimary,
        onTap: () => _navigateTo(const ConnectionPanel()),
      ),
      _GridAction(
        label: 'Disconnect',
        icon: LucideIcons.unlink,
        color: AppColors.bridgeError,
        onTap: status == ConnectionStatus.connected
            ? () => ref.read(connectionProvider.notifier).disconnect()
            : null,
      ),
      _GridAction(
        label: 'Commands',
        icon: LucideIcons.terminal,
        color: AppColors.bridgeSecondary,
        onTap: () => _navigateTo(const CommandLogScreen()),
      ),
      _GridAction(
        label: 'Settings',
        icon: LucideIcons.settings,
        color: AppColors.bridgeTextSecondary,
        onTap: () => _navigateTo(const SettingsScreen()),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: actions.map((action) => _buildGridButton(action)).toList(),
    );
  }

  Widget _buildGridButton(_GridAction action) {
    final enabled = action.onTap != null;

    return Material(
      color: AppColors.bridgeCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? action.onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled ? AppColors.bridgeCardBorder : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: enabled ? action.color : AppColors.bridgeTextSecondary.withOpacity(0.3), size: 28),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: TextStyle(
                  color: enabled ? AppColors.bridgeTextPrimary : AppColors.bridgeTextSecondary.withOpacity(0.3),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(DeviceStatus status) {
    final stats = [
      _QuickStat(
        icon: status.isCharging ? LucideIcons.batteryCharging : LucideIcons.battery,
        label: '${status.batteryLevel}%',
        color: status.batteryLevel > 20 ? AppColors.bridgeSuccess : AppColors.bridgeError,
      ),
      _QuickStat(
        icon: status.networkType == 'wifi' ? LucideIcons.wifi : LucideIcons.signal,
        label: status.networkType.toUpperCase(),
        color: AppColors.bridgePrimary,
      ),
      _QuickStat(
        icon: LucideIcons.hardDrive,
        label: _formatBytes(status.storageUsedBytes ?? 0),
        color: AppColors.bridgeSecondary,
      ),
      _QuickStat(
        icon: LucideIcons.clock,
        label: _formatUptime(status.uptimeSeconds),
        color: AppColors.bridgeWarning,
      ),
    ];

    return Row(
      children: stats.map((s) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bridgeCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.bridgeCardBorder),
          ),
          child: Column(
            children: [
              Icon(s.icon, color: s.color, size: 20),
              const SizedBox(height: 4),
              Text(
                s.label,
                style: const TextStyle(color: AppColors.bridgeTextPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildRecentCommands(List recentCommands) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Commands',
              style: TextStyle(color: AppColors.bridgeTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () => _navigateTo(const CommandLogScreen()),
              child: const Text('View All', style: TextStyle(color: AppColors.bridgePrimary, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...recentCommands.map((cmd) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bridgeCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.bridgeCardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    cmd.status == CommandStatus.success ? Icons.check_circle : cmd.status == CommandStatus.error ? Icons.error : Icons.hourglass_top,
                    color: cmd.status == CommandStatus.success
                        ? AppColors.bridgeSuccess
                        : cmd.status == CommandStatus.error
                            ? AppColors.bridgeError
                            : AppColors.bridgeWarning,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cmd.action,
                      style: const TextStyle(color: AppColors.bridgeTextPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    cmd.status.name,
                    style: TextStyle(
                      color: cmd.status == CommandStatus.success
                          ? AppColors.bridgeSuccess
                          : cmd.status == CommandStatus.error
                              ? AppColors.bridgeError
                              : AppColors.bridgeWarning,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }

  String _formatUptime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }
}

class _GridAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _GridAction({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class _QuickStat {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickStat({required this.icon, required this.label, required this.color});
}