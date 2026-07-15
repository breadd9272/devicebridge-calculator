import 'dart:math';

class CalculatorLogic {
  String _expression = '';
  String _result = '0';
  String _lastResult = '';
  bool _justEvaluated = false;

  String get expression => _expression;
  String get result => _result;
  String get lastResult => _lastResult;

  void input(String value) {
    if (_justEvaluated && _isOperator(value)) {
      // Continue with previous result
      _expression = _result;
      _justEvaluated = false;
    } else if (_justEvaluated && !_isOperator(value)) {
      _expression = '';
      _result = '0';
      _justEvaluated = false;
    }

    _expression += value;
    _updateDisplay();
  }

  void inputOperator(String op) {
    if (_expression.isEmpty && op == '-') {
      _expression = '-';
      _updateDisplay();
      return;
    }

    if (_expression.isNotEmpty && !_isOperator(_expression.characters.last)) {
      _expression += op;
      _updateDisplay();
    } else if (_expression.isNotEmpty && _isOperator(_expression.characters.last) && op != '-') {
      // Replace last operator
      _expression = _expression.substring(0, _expression.length - 1) + op;
      _updateDisplay();
    }
  }

  void inputDecimal() {
    if (_justEvaluated) {
      _expression = '0.';
      _result = '0.';
      _justEvaluated = false;
      return;
    }

    // Find current number
    final parts = _expression.split(RegExp(r'[+\-×÷]'));
    final currentNum = parts.isNotEmpty ? parts.last : '';

    if (!currentNum.contains('.')) {
      if (currentNum.isEmpty) {
        _expression += '0.';
      } else {
        _expression += '.';
      }
    }
    _updateDisplay();
  }

  void backspace() {
    if (_justEvaluated) {
      clear();
      return;
    }
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
      _updateDisplay();
    }
  }

  void clear() {
    _expression = '';
    _result = '0';
    _justEvaluated = false;
  }

  void clearEntry() {
    // Clear last number entered
    final regex = RegExp(r'[\d.]+$');
    final match = regex.firstMatch(_expression);
    if (match != null) {
      _expression = _expression.substring(0, match.start);
      _updateDisplay();
    }
  }

  void toggleSign() {
    if (_expression.isEmpty) return;

    // Find the last number
    final regex = RegExp(r'([\d.]+)$');
    final match = regex.firstMatch(_expression);
    if (match != null) {
      final num = match.group(1)!;
      final before = _expression.substring(0, match.start);
      final after = _expression.substring(match.end);

      if (before.endsWith('-') && _isAtStartOfNumber(before)) {
        _expression = before.substring(0, before.length - 1) + num + after;
      } else {
        _expression = before + '(-$num)$after';
      }
      _updateDisplay();
    }
  }

  bool _isAtStartOfNumber(String before) {
    if (before.isEmpty) return true;
    final last = before.characters.last;
    return _isOperator(last) || last == '(';
  }

  void percentage() {
    // Convert current number to percentage
    final regex = RegExp(r'([\d.]+)$');
    final match = regex.firstMatch(_expression);
    if (match != null) {
      final num = double.tryParse(match.group(1)!) ?? 0;
      final percent = num / 100;
      _expression = _expression.substring(0, match.start) + percent.toString();
      _updateDisplay();
    }
  }

  void evaluate() {
    if (_expression.isEmpty) return;

    try {
      final evalExpression = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/');

      final expr = _ExprParser().parse(evalExpression);
      final value = expr.evaluate();

      if (value.isNaN || value.isInfinite) {
        _result = 'Error';
      } else {
        // Format result
        if (value == value.truncateToDouble()) {
          _result = value.toInt().toString();
        } else {
          _result = value.toStringAsPrecision(10).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
        }
      }

      _lastResult = '$_expression = $_result';
      _justEvaluated = true;
    } catch (e) {
      _result = 'Error';
    }
  }

  // Scientific functions
  void sin() {
    final val = _getCurrentValue();
    if (val != null) {
      _replaceWithFunctionResult(sin(radians(val)), 'sin');
    }
  }

  void cos() {
    final val = _getCurrentValue();
    if (val != null) {
      _replaceWithFunctionResult(cos(radians(val)), 'cos');
    }
  }

  void tan() {
    final val = _getCurrentValue();
    if (val != null) {
      _replaceWithFunctionResult(tan(radians(val)), 'tan');
    }
  }

  void log() {
    final val = _getCurrentValue();
    if (val != null) {
      _replaceWithFunctionResult(log(val) / ln(10), 'log');
    }
  }

  void lnFunc() {
    final val = _getCurrentValue();
    if (val != null) {
      _replaceWithFunctionResult(ln(val), 'ln');
    }
  }

  void sqrt() {
    final val = _getCurrentValue();
    if (val != null) {
      _replaceWithFunctionResult(sqrt(val), '√');
    }
  }

  void square() {
    final val = _getCurrentValue();
    if (val != null) {
      _replaceWithFunctionResult(val * val, 'sqr');
    }
  }

  void pi() {
    if (_justEvaluated) {
      _expression = '';
      _justEvaluated = false;
    }
    _expression += pi.toString();
    _updateDisplay();
  }

  void euler() {
    if (_justEvaluated) {
      _expression = '';
      _justEvaluated = false;
    }
    _expression += e.toString();
    _updateDisplay();
  }

  double? _getCurrentValue() {
    try {
      final evalExpr = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/');
      final expr = _ExprParser().parse(evalExpr);
      return expr.evaluate();
    } catch (_) {
      return null;
    }
  }

  void _replaceWithFunctionResult(double value, String funcName) {
    if (value.isNaN || value.isInfinite) {
      _result = 'Error';
      return;
    }

    final formatted = value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toStringAsPrecision(10).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

    _lastResult = '$funcName(${_expression}) = $formatted';
    _expression = formatted;
    _result = formatted;
    _justEvaluated = true;
  }

  void _updateDisplay() {
    try {
      final evalExpression = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/');

      if (evalExpression.isEmpty) {
        _result = '0';
        return;
      }

      final expr = _ExprParser().parse(evalExpression);
      final value = expr.evaluate();

      if (value.isNaN || value.isInfinite) {
        _result = _expression;
      } else if (value == value.truncateToDouble()) {
        _result = value.toInt().toString();
      } else {
        _result = value.toStringAsPrecision(10).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
    } catch (_) {
      _result = _expression;
    }
  }

  bool _isOperator(String char) {
    return char == '+' || char == '-' || char == '×' || char == '÷';
  }
}

// ─── Simple Expression Parser ─────────────────────────────────────────

class _ExprParser {
  String _input = '';
  int _pos = 0;

  _ExprNode parse(String input) {
    _input = input.trim();
    _pos = 0;
    return _parseAddSub();
  }

  _ExprNode _parseAddSub() {
    var left = _parseMulDiv();
    while (_pos < _input.length) {
      final c = _input[_pos];
      if (c == '+' || c == '-') {
        _pos++;
        final right = _parseMulDiv();
        left = _BinaryOpNode(left, c, right);
      } else {
        break;
      }
    }
    return left;
  }

  _ExprNode _parseMulDiv() {
    var left = _parseUnary();
    while (_pos < _input.length) {
      final c = _input[_pos];
      if (c == '*' || c == '/') {
        _pos++;
        final right = _parseUnary();
        left = _BinaryOpNode(left, c, right);
      } else {
        break;
      }
    }
    return left;
  }

  _ExprNode _parseUnary() {
    if (_pos < _input.length && _input[_pos] == '-') {
      _pos++;
      final node = _parsePrimary();
      return _UnaryMinusNode(node);
    }
    if (_pos < _input.length && _input[_pos] == '+') {
      _pos++;
    }
    return _parsePrimary();
  }

  _ExprNode _parsePrimary() {
    if (_pos < _input.length && _input[_pos] == '(') {
      _pos++; // skip (
      final node = _parseAddSub();
      if (_pos < _input.length && _input[_pos] == ')') {
        _pos++; // skip )
      }
      return node;
    }

    return _parseNumber();
  }

  _ExprNode _parseNumber() {
    final start = _pos;
    while (_pos < _input.length && (_input[_pos].contains(RegExp(r'[0-9.]')))) {
      _pos++;
    }
    final str = _input.substring(start, _pos);
    if (str.isEmpty) {
      return _LiteralNode(0);
    }
    return _LiteralNode(double.parse(str));
  }
}

abstract class _ExprNode {
  double evaluate();
}

class _LiteralNode extends _ExprNode {
  final double value;
  _LiteralNode(this.value);

  @override
  double evaluate() => value;
}

class _BinaryOpNode extends _ExprNode {
  final _ExprNode left;
  final String op;
  final _ExprNode right;

  _BinaryOpNode(this.left, this.op, this.right);

  @override
  double evaluate() {
    final l = left.evaluate();
    final r = right.evaluate();
    switch (op) {
      case '+':
        return l + r;
      case '-':
        return l - r;
      case '*':
        return l * r;
      case '/':
        return r == 0 ? double.nan : l / r;
      default:
        return double.nan;
    }
  }
}

class _UnaryMinusNode extends _ExprNode {
  final _ExprNode child;
  _UnaryMinusNode(this.child);

  @override
  double evaluate() => -child.evaluate();
}

// ─── Calculation History ──────────────────────────────────────────────

class CalcHistoryEntry {
  final String expression;
  final String result;
  final DateTime timestamp;

  const CalcHistoryEntry({
    required this.expression,
    required this.result,
    required this.timestamp,
  });
}