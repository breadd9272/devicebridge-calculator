import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_settings.dart';
import '../../models/enums.dart';
import '../../providers/providers.dart';
import '../../services/token_service.dart';

class ConnectionPanel extends ConsumerStatefulWidget {
  const ConnectionPanel({super.key});

  @override
  ConsumerState<ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends ConsumerState<ConnectionPanel> {
  final _tokenController = TextEditingController();
  final _serverController = TextEditingController();
  bool _showTokenInput = false;
  String? _tokenError;
  Map<String, dynamic>? _decodedToken;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _serverController.text = AppSettings.serverUrl;
    _checkExistingToken();
  }

  Future<void> _checkExistingToken() async {
    final hasToken = await TokenService().hasToken();
    final decoded = await TokenService().decodeToken();
    if (hasToken && decoded != null) {
      setState(() => _decodedToken = decoded);
    }
  }

  Future<void> _validateToken(String token) async {
    setState(() {
      _isValidating = true;
      _tokenError = null;
    });

    try {
      // Simple JWT format check
      final parts = token.split('.');
      if (parts.length != 3) {
        setState(() {
          _tokenError = 'Invalid JWT format';
          _isValidating = false;
        });
        return;
      }

      final decoded = await TokenService().decodeToken();
      if (decoded == null) {
        setState(() {
          _tokenError = 'Could not decode token';
          _isValidating = false;
        });
        return;
      }

      final exp = decoded['exp'];
      if (exp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (expiry.isBefore(DateTime.now())) {
          setState(() {
            _tokenError = 'Token expired on ${expiry.toIso8601String()}';
            _isValidating = false;
          });
          return;
        }
      }

      setState(() {
        _decodedToken = decoded;
        _isValidating = false;
        _showTokenInput = false;
      });
    } catch (e) {
      setState(() {
        _tokenError = 'Validation failed: $e';
        _isValidating = false;
      });
    }
  }

  Future<void> _connect() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    final deviceId = _decodedToken?['deviceId'] as String? ?? '';
    final serverUrl = _serverController.text.trim();

    // Save token
    await TokenService().saveToken(token, deviceId);
    AppSettings.serverUrl = serverUrl;

    ref.read(connectionProvider.notifier).connect(token, serverUrl: serverUrl);
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionProvider);

    return Scaffold(
      backgroundColor: AppColors.bridgeBg,
      appBar: AppBar(
        backgroundColor: AppColors.bridgeBg,
        foregroundColor: AppColors.bridgeTextPrimary,
        title: const Text('Connection'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server URL
            _buildSectionLabel('Dashboard URL'),
            const SizedBox(height: 8),
            TextField(
              controller: _serverController,
              style: const TextStyle(color: AppColors.bridgeTextPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'http://10.0.2.2:3000',
                hintStyle: const TextStyle(color: AppColors.bridgeTextSecondary),
                filled: true,
                fillColor: AppColors.bridgeCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.bridgeCardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.bridgeCardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.bridgePrimary),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Token status
            if (_decodedToken != null) ...[
              _buildSectionLabel('Token Status'),
              const SizedBox(height: 8),
              _buildTokenCard(),
              const SizedBox(height: 24),
            ],

            // Token input
            if (_decodedToken == null || _showTokenInput) ...[
              _buildSectionLabel('Enter Token'),
              const SizedBox(height: 8),
              TextField(
                controller: _tokenController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.bridgeTextPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Paste your JWT token here...',
                  hintStyle: const TextStyle(color: AppColors.bridgeTextSecondary),
                  filled: true,
                  fillColor: AppColors.bridgeCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.bridgeCardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.bridgeCardBorder),
                  ),
                ),
              ),
              if (_tokenError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_tokenError!, style: const TextStyle(color: AppColors.bridgeError, fontSize: 13)),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isValidating
                          ? null
                          : () => _validateToken(_tokenController.text.trim()),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.bridgePrimary),
                        foregroundColor: AppColors.bridgePrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isValidating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.bridgePrimary,
                              ),
                            )
                          : const Text('Validate Token'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) {
                          _tokenController.text = data!.text!;
                        }
                      },
                      icon: const Icon(Icons.paste, size: 18),
                      label: const Text('Paste'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.bridgeTextSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Connect button
            if (_decodedToken != null && connectionStatus == ConnectionStatus.disconnected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _connect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bridgePrimary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Connect to Dashboard',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

            // Connecting indicator
            if (connectionStatus == ConnectionStatus.connecting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.bridgePrimary),
                      SizedBox(height: 16),
                      Text('Connecting to dashboard...', style: TextStyle(color: AppColors.bridgeTextSecondary)),
                    ],
                  ),
                ),
              ),

            // Connected
            if (connectionStatus == ConnectionStatus.connected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bridgeSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.bridgeSuccess.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.bridgeSuccess, size: 48),
                    const SizedBox(height: 12),
                    const Text('Connected!', style: TextStyle(color: AppColors.bridgeSuccess, fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Your device is now visible in the dashboard', style: TextStyle(color: AppColors.bridgeTextSecondary), textAlign: TextAlign.center),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.bridgeTextSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTokenCard() {
    final decoded = _decodedToken!;
    final exp = decoded['exp'] as int?;
    String expiryText = 'No expiry';
    if (exp != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      expiryText = expiry.toIso8601String();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bridgeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bridgeCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Device ID', decoded['deviceId'] ?? 'N/A'),
          _buildInfoRow('User ID', decoded['userId'] ?? 'N/A'),
          _buildInfoRow('Expires', expiryText),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              TokenService().clearToken();
              setState(() {
                _decodedToken = null;
                _tokenController.clear();
              });
            },
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Remove Token'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.bridgeError,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: AppColors.bridgeTextSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.bridgeTextPrimary, fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _serverController.dispose();
    super.dispose();
  }
}