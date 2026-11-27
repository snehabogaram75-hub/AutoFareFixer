// ignore_for_file: avoid_print
import 'package:auto_fare_fixer/plate_reader.dart';

void main() {
  final cases = <String, String?>{
    'TS09AB1234': 'TS09AB1234',
    'TS 09 AB 1234': 'TS09AB1234',
    'TS-09-AB-1234': 'TS09AB1234',
    'IND TS09AB1234 BHARAT': 'TS09AB1234',
    'T509AB1234': 'TS09AB1234',
    'TS09A81234': 'TS09AB1234',
    'TS09AB1Z34': 'TS09AB1234',
    'AP39 Z 4567': 'AP39Z4567',
    'TS09AB12345': 'TS09AB1234',
    'HELLO WORLD': null,
  };
  var failed = 0;
  cases.forEach((input, expected) {
    final got = extractPlate(input);
    final ok = got == expected;
    if (!ok) failed++;
    print('${ok ? 'PASS' : 'FAIL'}  "$input" -> $got (expected $expected)');
  });
  print(failed == 0 ? 'All ${cases.length} checks passed' : '$failed failed');
}
