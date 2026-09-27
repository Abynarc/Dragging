import 'dart:typed_data';

// Finite doubles are compared by their IEEE-754 bits, including signed zero.
// NaN payloads are not meaningful results; compare their classification instead.
Object? exactValues(Object? value) {
  if (value is double) {
    if (value.isNaN) return 'double:NaN';
    if (value.isInfinite) {
      return value.isNegative ? 'double:-Infinity' : 'double:Infinity';
    }
    final bytes = ByteData(8)..setFloat64(0, value);
    return 'double:${bytes.getUint64(0).toRadixString(16).padLeft(16, '0')}';
  }
  if (value is List) return value.map(exactValues).toList();
  if (value is Map) {
    return value.map((key, item) => MapEntry(key, exactValues(item)));
  }
  return value;
}
