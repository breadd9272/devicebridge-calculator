import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../core/utils/app_settings.dart';
import '../../core/utils/logger.dart';
import '../../models/command_model.dart';
import '../../models/heartbeat_model.dart';
import '../../models/command_result_model.dart';

typedef CommandCallback = void Function(CommandModel command);
typedef ConnectionCallback = void Function(bool connected);
typedef HeartbeatAckCallback = void Function(bool ack);

class SocketIOService {
  static final SocketIOService _instance = SocketIOService._();
  factory SocketIOService() => _instance;
  SocketIOService._();

  IO.Socket? _socket;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 10;

  CommandCallback? onCommandReceived;
  ConnectionCallback? onConnectionChanged;

  String? _serverUrl;

  bool get isConnected => _isConnected;

  Future<void> connect(String? token, {String? serverUrl}) async {
    if (_isConnected) {
      AppLogger.w('SocketIO', 'Already connected, disconnecting first');
      await disconnect();
    }

    _serverUrl = serverUrl ?? AppSettings.serverUrl;
    _reconnectAttempts = 0;

    try {
      AppLogger.i('SocketIO', 'Connecting to $_serverUrl');

      final opts = IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setTimeout(10000)
          .build();

      _socket = IO.io(_serverUrl, opts);

      _socket!.onConnect((_) {
        _isConnected = true;
        _reconnectAttempts = 0;
        AppLogger.i('SocketIO', 'Connected to server');

        if (token != null && token.isNotEmpty) {
          _socket!.emitWithAck('authenticate', {'token': token}, (ack) {
            if (ack != null && ack is List && ack.isNotEmpty) {
              final data = ack[0] as Map<String, dynamic>;
              if (data['success'] == true) {
                AppLogger.i('SocketIO', 'Authenticated successfully');
                _socket!.emit('device:register', {
                  'status': 'online',
                });
                onConnectionChanged?.call(true);
              } else {
                AppLogger.e('SocketIO', 'Authentication failed: ${data['error']}');
                _isConnected = false;
                onConnectionChanged?.call(false);
              }
            }
          });
        }
      });

      _socket!.on('command', (data) {
        if (data is Map<String, dynamic>) {
          final command = CommandModel.fromJson(data);
          AppLogger.i('SocketIO', 'Command received: ${command.action}');
          onCommandReceived?.call(command);
        }
      });

      _socket!.onDisconnect((reason) {
        _isConnected = false;
        AppLogger.w('SocketIO', 'Disconnected: $reason');
        onConnectionChanged?.call(false);
        _scheduleReconnect(token);
      });

      _socket!.onConnectError((error) {
        AppLogger.e('SocketIO', 'Connection error: $error');
        _isConnected = false;
        onConnectionChanged?.call(false);
      });

      _socket!.onError((error) {
        AppLogger.e('SocketIO', 'Socket error: $error');
      });

      _socket!.connect();
    } catch (e) {
      AppLogger.e('SocketIO', 'Failed to connect', e);
      onConnectionChanged?.call(false);
      _scheduleReconnect(token);
    }
  }

  void _scheduleReconnect(String? token) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.w('SocketIO', 'Max reconnect attempts reached');
      return;
    }

    final delay = Duration(seconds: min(_reconnectAttempts * 2 + 1, 30));
    _reconnectAttempts++;

    AppLogger.i('SocketIO', 'Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect(token);
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = _maxReconnectAttempts; // prevent auto-reconnect
    if (_socket != null) {
      _socket!.emit('device:disconnect');
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    onConnectionChanged?.call(false);
    AppLogger.i('SocketIO', 'Disconnected');
  }

  void sendHeartbeat(HeartbeatModel heartbeat) {
    if (_isConnected && _socket != null) {
      _socket!.emit('device:heartbeat', heartbeat.toJson());
      AppLogger.d('SocketIO', 'Heartbeat sent');
    }
  }

  void sendCommandResult(CommandResult result) {
    if (_isConnected && _socket != null) {
      _socket!.emit('command:result', result.toJson());
      AppLogger.d('SocketIO', 'Command result sent for ${result.commandId}');
    }
  }

  void sendCommandError(String commandId, String error) {
    if (_isConnected && _socket != null) {
      final result = CommandResult.failure(commandId, error);
      _socket!.emit('command:result', result.toJson());
      AppLogger.d('SocketIO', 'Command error sent for $commandId');
    }
  }
}

int min(int a, int b) => a < b ? a : b;