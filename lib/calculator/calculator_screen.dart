import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/app_settings.dart';
import '../models/enums.dart';
import '../providers/providers.dart';
import 'calculator_button.dart';
import 'calculator_display.dart';
import 'calculator_logic.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _logic = CalculatorLogic();
  bool _showScientific = false;
  final List<CalcHistoryEntry> _history = [];
  bool _showHistory = false;
  Timer? _activationTimer;

  @override
  void initState() {
    super.initState();
    Vibration.hasVibrator().catchError((_) => false);
  }

  @override
  void dispose() {
    _activationTimer?.cancel();
    super.dispose();
  }

  void _onTitleLongPressStart() {
    // Start 3-second timer - show PIN dialog only after holding 3 seconds
    _activationTimer = Timer(const Duration(seconds: 3), () {
      HapticFeedback.heavyImpact();
      _showPinDialog();
    });
  }

  void _onTitleLongPressEnd() {
    _activationTimer?.cancel();
    _activationTimer = null;
  }

  void _showPinDialog() {
    // Check lockout
    final lockoutUntil = AppSettings.pinLockoutUntil;
    if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil)) {
      final remaining = lockoutUntil.difference(DateTime.now()).inMinutes;
      _showToast('Locked. Try again in $remaining minutes.');
      return;
    }

    String pin = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2a2a3a)),
        ),
        title: const Text(
          'Developer Code',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                letterSpacing: 12,
              ),
              textAlign: TextAlign.center,
              maxLength: 4,
              autofocus: true,
              onChanged: (value) => pin = value,
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  letterSpacing: 12,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.cyan.withOpacity(0.5)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00f0ff)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Attempts remaining: ${3 - AppSettings.pinAttempts}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _validatePin(pin);
            },
            child: const Text('Enter', style: TextStyle(color: Color(0xFF00f0ff))),
          ),
        ],
      ),
    );
  }

  void _validatePin(String pin) {
    if (pin == '1999') {
      AppSettings.pinAttempts = 0;
      AppSettings.pinLockoutUntil = null;
      if (mounted) {
        _showToast('Access granted');
        // Switch to bridge mode via Riverpod
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            ref.read(bridgeModeProvider.notifier).state = BridgeMode.bridge;
          }
        });
      }
    } else {
      final attempts = AppSettings.pinAttempts + 1;
      AppSettings.pinAttempts = attempts;
      if (attempts >= 3) {
        AppSettings.pinLockoutUntil = DateTime.now().add(const Duration(minutes: 5));
        AppSettings.pinAttempts = 0;
        _showDecoyScreen();
      } else {
        _showToast('Wrong code. ${3 - attempts} attempts remaining.');
      }
    }
  }

  void _showDecoyScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: const Text('Developer Options'),
            backgroundColor: const Color(0xFF1a1a2e),
            foregroundColor: Colors.white,
          ),
          backgroundColor: const Color(0xFF1a1a2e),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Animation Speed',
                    style: TextStyle(color: Colors.white70)),
                subtitle: const Text('0.5x',
                    style: TextStyle(color: Colors.white38)),
                value: false,
                onChanged: (_) {},
                activeColor: const Color(0xFF00f0ff),
              ),
              SwitchListTile(
                title: const Text('Debug Logging',
                    style: TextStyle(color: Colors.white70)),
                subtitle: const Text('Disabled',
                    style: TextStyle(color: Colors.white38)),
                value: false,
                onChanged: (_) {},
                activeColor: const Color(0xFF00f0ff),
              ),
              SwitchListTile(
                title: const Text('Show FPS Overlay',
                    style: TextStyle(color: Colors.white70)),
                value: false,
                onChanged: (_) {},
                activeColor: const Color(0xFF00f0ff),
              ),
              SwitchListTile(
                title: const Text('Layout Bounds',
                    style: TextStyle(color: Colors.white70)),
                value: false,
                onChanged: (_) {},
                activeColor: const Color(0xFF00f0ff),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF16213e),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_showHistory,
      onPopInvokedWithResult: (didPop, _) {
        if (_showHistory) {
          setState(() => _showHistory = false);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.calculatorDark.scaffoldBackgroundColor : AppTheme.calculatorLight.scaffoldBackgroundColor,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showHistory ? _buildHistory(isDark) : _buildCalculator(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildCalculator(bool isDark) {
    return Column(
      key: const ValueKey('calculator'),
      children: [
        // Display
        Expanded(
          flex: 2,
          child: GestureDetector(
            onLongPressStart: (_) => _onTitleLongPressStart(),
            onLongPressEnd: (_) => _onTitleLongPressEnd(),
            child: CalculatorDisplay(
              expression: _logic.expression,
              result: _logic.result,
            ),
          ),
        ),

        // Scientific row toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _showScientific = !_showScientific),
                child: Text(
                  _showScientific ? 'STD' : 'SCI',
                  style: TextStyle(
                    color: const Color(0xFF00f0ff),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _showHistory = true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history, color: Colors.white54, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'History',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Scientific buttons
        if (_showScientific) _buildScientificRow(),

        // Main button grid
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildButtonGrid(),
          ),
        ),
      ],
    );
  }

  Widget _buildScientificRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _sciBtn('sin', _logic.sin),
            _sciBtn('cos', _logic.cos),
            _sciBtn('tan', _logic.tan),
            _sciBtn('log', _logic.log),
            _sciBtn('ln', _logic.lnFunc),
            _sciBtn('√', _logic.sqrt),
            _sciBtn('x²', _logic.square),
            _sciBtn('π', _logic.pi),
            _sciBtn('e', _logic.euler),
          ],
        ),
      ),
    );
  }

  Widget _sciBtn(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
          setState(() {});
        },
        child: Container(
          width: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF533483).withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonGrid() {
    final buttons = [
      ['AC', '( )', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['+/-', '0', '.', '='],
    ];

    return Column(
      children: buttons.map((row) {
        return Expanded(
          child: Row(
            children: row.map((label) {
              ButtonType type;
              if (['+', '-', '×', '÷'].contains(label)) {
                type = ButtonType.operator;
              } else if (['AC', '( )', '%', '+/-'].contains(label)) {
                type = ButtonType.function;
              } else if (label == '=') {
                type = ButtonType.equals;
              } else {
                type = ButtonType.number;
              }

              return Expanded(
                child: CalculatorButton(
                  label: label,
                  type: type,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _handleButtonPress(label);
                    setState(() {});
                  },
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  void _handleButtonPress(String label) {
    switch (label) {
      case 'AC':
        _logic.clear();
        break;
      case '( )':
        // Simple parenthesis handling - not fully implemented for simplicity
        break;
      case '%':
        _logic.percentage();
        break;
      case '+/-':
        _logic.toggleSign();
        break;
      case '÷':
      case '×':
      case '-':
      case '+':
        _logic.inputOperator(label);
        break;
      case '=':
        if (_logic.expression.isNotEmpty) {
          final expr = _logic.expression;
          final res = _logic.result;
          _logic.evaluate();
          if (_logic.lastResult.isNotEmpty) {
            _history.insert(
              0,
              CalcHistoryEntry(
                expression: expr,
                result: res,
                timestamp: DateTime.now(),
              ),
            );
            if (_history.length > 50) _history.removeLast();
          }
        }
        break;
      case '.':
        _logic.inputDecimal();
        break;
      default:
        _logic.input(label);
    }
  }

  Widget _buildHistory(bool isDark) {
    return Column(
      key: const ValueKey('history'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _showHistory = false),
              ),
              const Text(
                'History',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_history.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _history.clear();
                    });
                  },
                  child: const Text('Clear', style: TextStyle(color: Color(0xFFe94560))),
                ),
            ],
          ),
        ),
        Expanded(
          child: _history.isEmpty
              ? const Center(
                  child: Text(
                    'No calculations yet',
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final entry = _history[index];
                    return GestureDetector(
                      onTap: () {
                        _logic.input(entry.result);
                        setState(() => _showHistory = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isDark
                              ? const Color(0xFF16213e).withOpacity(0.5)
                              : Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              entry.expression,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '= ${entry.result}',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatTime(entry.timestamp),
                              style: TextStyle(
                                color: isDark ? Colors.white24 : Colors.black26,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}