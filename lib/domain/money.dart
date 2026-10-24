class Money {
  static int parsePtBr(String value) {
    final result = tryParsePtBr(value);
    if (result == null) {
      throw const FormatException('Valor monetário inválido.');
    }
    return result;
  }

  static int? tryParsePtBr(String value) {
    var text = value.trim();
    var negative = text.startsWith('-');
    if (negative) text = text.substring(1).trimLeft();
    text = text.replaceFirst(RegExp(r'^R\$\s*'), '');
    if (text.startsWith('-')) {
      negative = true;
      text = text.substring(1).trimLeft();
    }
    if (!RegExp(r'^\d{1,3}(?:\.\d{3})*(?:,\d{1,2})?$|^\d+(?:,\d{1,2})?$')
        .hasMatch(text)) {
      return null;
    }
    final parts = text.replaceAll('.', '').split(',');
    var cents = int.parse(parts[0]) * 100;
    if (parts.length == 2) cents += int.parse(parts[1].padRight(2, '0'));
    return negative ? -cents : cents;
  }

  static String formatBr(int cents) {
    final negative = cents < 0;
    final absolute = cents.abs();
    final parts = [
      (absolute ~/ 100).toString(),
      (absolute % 100).toString().padLeft(2, '0'),
    ];
    parts[0] = parts[0].replaceAllMapped(
      RegExp(r'(?<=\d)(?=(\d{3})+$)'),
      (_) => '.',
    );
    return '${negative ? '-' : ''}R\$ ${parts.join(',')}';
  }
}
