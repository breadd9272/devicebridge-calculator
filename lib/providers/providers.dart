import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/device_status.dart';
import '../services/socket_io_service.dart';
import '../services/heartbeat_service.dart';
import '../services/command_handler.dart';
import '../models/command_model.dart';

// ─── Bridge Mode Provider ──────────────────────────────────────────────

final bridgeModeProvider = StateProvider<BridgeMode>((ref) => BridgeMode.calculator);

// ─── Connection State Provider ─────────────────────────────────────────

class ConnectionNotifier extends StateNotifier<ConnectionStatus> {
  final SocketIOService _socketIO;
  final CommandHandler _commandHandler;
  final HeartbeatService _heartbeat;
  StreamSubscription? _commandSub;

  ConnectionNotifier(this._socketIO, this._commandHandler, this._heartbeat)
      : super(ConnectionStatus.disconnected) {
    _socketIO.onConnectionChanged = _onConnectionChanged;
    _socketIO.onCommandReceived = _onCommand;
  }

  void _onConnectionChanged(bool connected) {
    if (connected) {
      state = ConnectionStatus.connected;
      _heartbeat.start();
    } else if (state == ConnectionStatus.connected) {
      state = ConnectionStatus.disconnected;
      _heartbeat.stop();
    }
  }

  void _onCommand(CommandModel command) {
    _commandHandler.handleCommand(command);
    // Notify UI via command log provider
    _onCommandReceived?.call(command);
  }

  void Function(CommandModel)? _onCommandReceived;
  set onCommandReceived(void Function(CommandModel)? cb) => _onCommandReceived = cb;

  Future<void> connect(String token, {String? serverUrl}) async {
    state = ConnectionStatus.connecting;
    _socketIO.onCommandReceived = _onCommand;
    _socketIO.onConnectionChanged = _onConnectionChanged;
    await _socketIO.connect(token, serverUrl: serverUrl);
  }

  void disconnect() {
    _heartbeat.stop();
    _socketIO.disconnect();
    state = ConnectionStatus.disconnected;
  }

  @override
  void dispose() {
    _commandSub?.cancel();
    super.dispose();
  }
}

final connectionProvider =
    StateNotifierProvider<ConnectionNotifier, ConnectionStatus>((ref) {
  return ConnectionNotifier(
    SocketIOService(),
    CommandHandler(),
    HeartbeatService(),
  );
});

// ─── Device Status Provider ────────────────────────────────────────────

final deviceStatusProvider =
    StateNotifierProvider<DeviceStatusNotifier, DeviceStatus>((ref) {
  return DeviceStatusNotifier();
});

class DeviceStatusNotifier extends StateNotifier<DeviceStatus> {
  Timer? _refreshTimer;

  DeviceStatusNotifier() : super(DeviceStatus.initial());

  void startAutoRefresh() {
    stopAutoRefresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      refresh();
    });
    refresh();
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> refresh() async {
    try {
      final status = await HeartbeatService().getCurrentStatus();
      state = status;
    } catch (_) {}
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}

// ─── Command Log Provider ──────────────────────────────────────────────

final commandLogProvider =
    StateNotifierProvider<CommandLogNotifier, List<CommandModel>>((ref) {
  return CommandLogNotifier();
});

class CommandLogNotifier extends StateNotifier<List<CommandModel>> {
  static const maxEntries = 500;

  CommandLogNotifier() : super([]);

  void addCommand(CommandModel command) {
    state = [command, ...state];
    if (state.length > maxEntries) {
      state = state.sublist(0, maxEntries);
    }
  }

  void updateCommand(CommandModel updated) {
    state = state.map((c) => c.commandId == updated.commandId ? updated : c).toList();
  }

  void clear() {
    state = [];
  }

  List<CommandModel> getFiltered(CommandStatus? filter) {
    if (filter == null) return state;
    return state.where((c) => c.status == filter).toList();
  }
}