import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/app_settings.dart';
import 'models/enums.dart';
import 'providers/providers.dart';
import 'calculator/calculator_screen.dart';
import 'bridge/bridge_screen.dart';

class DeviceBridgeApp extends ConsumerStatefulWidget {
  const DeviceBridgeApp({super.key});

  @override
  ConsumerState<DeviceBridgeApp> createState() => _DeviceBridgeAppState();
}

class _DeviceBridgeAppState extends ConsumerState<DeviceBridgeApp> {
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _isDark = true; // Default dark
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(bridgeModeProvider);

    // Use different theme based on mode
    ThemeData theme;
    if (mode == BridgeMode.bridge) {
      theme = AppTheme.bridgeTheme;
    } else {
      theme = _isDark ? AppTheme.calculatorDark : AppTheme.calculatorLight;
    }

    return MaterialApp(
      title: 'Calculator Pro',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInCubic,
        switchOutCurve: Curves.easeOutCubic,
        child: mode == BridgeMode.bridge
            ? const BridgeScreen(key: ValueKey('bridge'))
            : _CalculatorWrapper(
                key: const ValueKey('calculator'),
                onBridgeActivated: () {
                  ref.read(bridgeModeProvider.notifier).state = BridgeMode.bridge;
                },
              ),
      ),
    );
  }
}

/// Wrapper that listens for bridge activation from the calculator screen
class _CalculatorWrapper extends StatelessWidget {
  final VoidCallback onBridgeActivated;

  const _CalculatorWrapper({super.key, required this.onBridgeActivated});

  @override
  Widget build(BuildContext context) {
    return const CalculatorScreen();
  }
}