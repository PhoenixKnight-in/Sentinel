/// Pure calculator logic — no Flutter dependencies.
/// Handles expression parsing and the secret unlock sequence.
class CalculatorLogic {
  String _display = '0';
  String _expression = '';
  double _firstOperand = 0;
  String _operator = '';
  bool _justEvaluated = false;
  bool _awaitingOperand = false;

  // Secret unlock sequence: "1947=" (India's independence year — memorable)
  // The sequence is accumulated as raw key presses, not the displayed result.
  final String _unlockCode = '1947=';
  String _keySequence = '';
  bool _unlockTriggered = false;

  String get display => _display;
  String get expression => _expression;
  bool get unlockTriggered => _unlockTriggered;

  void resetUnlock() => _unlockTriggered = false;

  /// Called for every button press. Returns the updated display string.
  String handleInput(String input) {
    _trackKeySequence(input);

    if (input == 'AC' || input == 'C') {
      return _handleClear(input);
    } else if (input == '+/-') {
      return _handleToggleSign();
    } else if (input == '%') {
      return _handlePercent();
    } else if ('+-×÷'.contains(input)) {
      return _handleOperator(input);
    } else if (input == '=') {
      return _handleEquals();
    } else if (input == '.') {
      return _handleDecimal();
    } else {
      return _handleDigit(input);
    }
  }

  void _trackKeySequence(String key) {
    _keySequence += key;
    // Keep only the last N chars where N = unlock code length
    if (_keySequence.length > _unlockCode.length) {
      _keySequence = _keySequence.substring(
        _keySequence.length - _unlockCode.length,
      );
    }
    if (_keySequence == _unlockCode) {
      _unlockTriggered = true;
      _keySequence = '';
    }
  }

  String _handleClear(String key) {
    if (key == 'AC') {
      _display = '0';
      _expression = '';
      _firstOperand = 0;
      _operator = '';
      _justEvaluated = false;
      _awaitingOperand = false;
    } else {
      // 'C' — clear current entry only
      _display = '0';
      _awaitingOperand = false;
    }
    return _display;
  }

  String _handleToggleSign() {
    if (_display != '0') {
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    }
    return _display;
  }

  String _handlePercent() {
    final value = double.tryParse(_display) ?? 0;
    _display = _formatNumber(value / 100);
    return _display;
  }

  String _handleOperator(String op) {
    if (_operator.isNotEmpty && !_awaitingOperand) {
      // Chain operations: compute previous result first
      _handleEquals();
    }
    _firstOperand = double.tryParse(_display) ?? 0;
    _operator = op;
    _expression = '${_formatNumber(_firstOperand)} $op';
    _awaitingOperand = true;
    _justEvaluated = false;
    return _display;
  }

  String _handleEquals() {
    if (_operator.isEmpty) return _display;

    final secondOperand = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = _firstOperand + secondOperand;
        break;
      case '-':
        result = _firstOperand - secondOperand;
        break;
      case '×':
        result = _firstOperand * secondOperand;
        break;
      case '÷':
        if (secondOperand == 0) {
          _display = 'Error';
          _expression = '';
          _operator = '';
          return _display;
        }
        result = _firstOperand / secondOperand;
        break;
    }

    _expression = '';
    _operator = '';
    _display = _formatNumber(result);
    _justEvaluated = true;
    _awaitingOperand = false;
    return _display;
  }

  String _handleDecimal() {
    if (_justEvaluated || _awaitingOperand) {
      _display = '0.';
      _awaitingOperand = false;
      _justEvaluated = false;
      return _display;
    }
    if (!_display.contains('.')) {
      _display = '$_display.';
    }
    return _display;
  }

  String _handleDigit(String digit) {
    if (_justEvaluated || _awaitingOperand) {
      _display = digit;
      _justEvaluated = false;
      _awaitingOperand = false;
    } else {
      if (_display == '0') {
        _display = digit;
      } else if (_display.length < 9) {
        _display = '$_display$digit';
      }
    }
    return _display;
  }

  String _formatNumber(double value) {
    if (value == value.truncateToDouble() && value.abs() < 1e9) {
      return value.toInt().toString();
    }
    // Trim trailing zeros after decimal
    String s = value.toStringAsFixed(8);
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    return s;
  }
}