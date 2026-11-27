/// Extracts an Indian vehicle registration number (e.g. TS09AB1234) from
/// OCR text. Fixes common OCR confusions such as S/5, B/8, O/0.
String? extractPlate(String raw) {
  final text = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  for (final m in RegExp(r'[A-Z]{2}\d{2}[A-Z]{1,3}\d{4}').allMatches(text)) {
    if (m.end == text.length || !RegExp(r'[0-9]').hasMatch(text[m.end])) {
      return m.group(0);
    }
  }

  const toLetter = {'0': 'O', '1': 'I', '5': 'S', '8': 'B', '2': 'Z'};
  const toDigit = {
    'O': '0', 'Q': '0', 'D': '0', 'I': '1', 'L': '1',
    'S': '5', 'B': '8', 'Z': '2',
  };
  bool isLetter(String c) => RegExp(r'^[A-Z]$').hasMatch(c);
  bool isDigit(String c) => RegExp(r'^[0-9]$').hasMatch(c);

  for (final series in [2, 1, 3]) {
    final len = 4 + series + 4;
    for (var i = 0; i + len <= text.length; i++) {
      final window = text.substring(i, i + len);
      final out = StringBuffer();
      var ok = true;
      for (var k = 0; k < len; k++) {
        final letterPos = k < 2 || (k >= 4 && k < 4 + series);
        final ch = window[k];
        final fixed = letterPos ? (toLetter[ch] ?? ch) : (toDigit[ch] ?? ch);
        if (letterPos ? !isLetter(fixed) : !isDigit(fixed)) {
          ok = false;
          break;
        }
        out.write(fixed);
      }
      if (ok) return out.toString();
    }
  }
  return null;
}
