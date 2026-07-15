import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../models/enums.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _deviceNameController;
  late TextEditingController _heartbeatController;
  late TextEditingController _serverUrlController;

  @override
  void initState() {
    super.initState();
    _deviceNameController = TextEditingController(text: 'My Device');
    _heartbeatController = TextEditingController(text: '30');
    _serverUrlController = TextEditingController(text: 'http://10.0.2.2:3000');
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _deviceNameController.text = 'My Device';
      _heartbeatController.text = '30';
      _serverUrlController.text = 'http://10.0.2.2:3000';
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionProvider);

    return Scaffold(
      backgroundColor: AppColors.bridgeBg,
      appBar: AppBar(
        backgroundColor: AppColors.bridgeBg,
        foregroundColor: AppColors.bridgeTextPrimary,
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Device section
          _buildSectionHeader('Device'),
          _buildSettingCard([
            _buildTextField(
              label: 'Device Name',
              controller: _deviceNameController,
              onSaved: (val) {},
            ),
            _buildTextField(
              label: 'Server URL',
              controller: _serverUrlController,
              onSaved: (val) {},
            ),
            _buildTextField(
              label: 'Heartbeat Interval (seconds)',
              controller: _heartbeatController,
              keyboardType: TextInputType.number,
              onSaved: (val) {},
            ),
          ]),

          const SizedBox(height: 24),

          // Connection section
          _buildSectionHeader('Connection'),
          _buildSettingCard([
            _buildSwitchTile(
              'Auto-connect on Startup',
              'Automatically connect when app opens',
              value: false,
              onChanged: (val) {},
            ),
            const Divider(color: AppColors.bridgeCardBorder, height: 1),
            _buildSwitchTile(
              'Background Service',
              'Keep running when app is closed',
              value: connectionStatus == ConnectionStatus.connected,
              onChanged: null,
            ),
          ]),

          const SizedBox(height: 24),

          // Danger zone
          _buildSectionHeader('Danger Zone'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bridgeCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.bridgeError.withOpacity(0.3)),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.bridgeError),
              title: const Text('Clear All Data', style: TextStyle(color: AppColors.bridgeError)),
              subtitle: const Text('Reset everything, delete token', style: TextStyle(color: AppColors.bridgeTextSecondary, fontSize: 12)),
              onTap: () => _showClearDataDialog(),
            ),
          ),

          const SizedBox(height: 24),

          // About
          _buildSectionHeader('About'),
          _buildSettingCard([
            _buildInfoRow('App', 'Calculator Pro v1.0.0'),
            _buildInfoRow('Engine', 'DeviceBridge Pro v1.0'),
            _buildInfoRow('Framework', 'Flutter 3.24+'),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.bridgeTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bridgeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bridgeCardBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    required void Function(String) onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.bridgeTextSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppColors.bridgeTextPrimary, fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.bridgeCardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.bridgePrimary),
              ),
            ),
            onSubmitted: onSaved,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, {required bool value, required void Function(bool)? onChanged}) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: AppColors.bridgeTextPrimary, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.bridgeTextSecondary, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.bridgePrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.bridgeTextSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(color: AppColors.bridgeTextPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bridgeCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Data?', style: TextStyle(color: AppColors.bridgeTextPrimary)),
        content: const Text(
          'This will disconnect, delete your token, and reset all settings.',
          style: TextStyle(color: AppColors.bridgeTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.bridgeTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(connectionProvider.notifier).disconnect();
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.bridgeError)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _heartbeatController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }
}