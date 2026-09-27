import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wire_drawing_calc/domain/calculations.dart';
import 'package:wire_drawing_calc/application/linear_calculation.dart';
import 'support/exact_values.dart';

void main() {
  final baseline = jsonDecode(
    File('test/fixtures/raw_calculations_step4.json').readAsStringSync(),
  );
  final cases = baseline['cases'] as List;
  for (var i = 0; i < cases.length; i++) {
    final item = cases[i] as Map;
    test('Exact original raw result $i / ${item['kind']} / ${item['input']}', () {
      final values = List<String?>.from(item['input']);
      Object actual;
      switch (item['kind']) {
        case 'route':
          actual = routeReductions(
            List.generate(
              16,
              (index) => index < values.length ? values[index]! : '',
            ),
          );
        case 'linear':
          try {
            final result = calculateLinearRoute(
              rawDiameter: values[0]!,
              finalDiameter: values[1]!,
              passesText: values[2]!,
              carbonText: values[3]!,
            );
            actual = {
              'numbers': result.numbers,
              'diameters': result.diameters,
              'reductions': result.reductions,
              'error': '',
            };
          } on CalculationException catch (error) {
            actual = {
              'numbers': List<double>.filled(6, 0),
              'diameters': <String>[],
              'reductions': <double>[],
              'error': error.toString(),
            };
          }
        case 'zinc':
          final result = calculateZinc(
            rawDiameter: values[0]!,
            finalDiameter: values[1]!,
            group: values[2] == 'С' ? 'C' : values[2],
          );
          actual = {'value': result.value, 'error': result.error};
        default:
          fail('Unknown fixture type: ${item['kind']}');
      }
      expect(
        exactValues(actual),
        item['output'],
        reason:
            'No epsilon or additional rounding. Expected values came from original screen callbacks.',
      );
    });
  }

  test(
    'Zero-denominator guard preserves historical special-value behavior',
    () {
      expect(guardedVsrCorrection(123, 0), 0);
      expect(guardedVsrCorrection(double.nan, -0.0), 0);
      expect(guardedVsrCorrection(123, double.infinity), 0);
      expect(guardedVsrCorrection(123, double.nan).isNaN, isTrue);
      expect(guardedVsrCorrection(123, 2), 61.5);
    },
  );

  test(
    'Application state preserves manual edit, failed submit and exact regeneration',
    () {
      final state = LinearCalculation();
      void calculate() => state.calculate(
        rawDiameter: '5.5',
        finalDiameter: '2',
        passesText: '8',
        carbonText: '0.7',
      );
      calculate();
      final summary = state.result;
      final originalRows = List.of(state.diameters);
      state.editDiameter(2, '4.30');
      expect(identical(state.result, summary), isTrue);
      expect(state.reductions.map((r) => r.toStringAsFixed(2)).take(3), [
        '22.24',
        '21.39',
        '23.54',
      ]);
      expect(
        () => state.calculate(
          rawDiameter: '5',
          finalDiameter: '6',
          passesText: '8',
          carbonText: '0.7',
        ),
        throwsA(isA<CalculationException>()),
      );
      expect(state.diameters[2], '4.30');
      expect(identical(state.result, summary), isTrue);
      calculate();
      expect(state.diameters, originalRows);
      expect(() => state.diameters.clear(), throwsUnsupportedError);
      expect(() => state.reductions[0] = 0, throwsUnsupportedError);
      expect(() => state.result!.diameters.clear(), throwsUnsupportedError);
      for (var i = 0; i < 100; i++) {
        state.reset();
        state.reset();
        expect(state.result, isNull);
        expect(state.diameters, isEmpty);
        expect(state.reductions, isEmpty);
        calculate();
      }
    },
  );

  test(
    'Numeric exactness helper distinguishes signed zero and adjacent doubles',
    () {
      expect(exactValues(0.0), isNot(exactValues(-0.0)));
      expect(exactValues(1.0), isNot(exactValues(1.0000000000000002)));
      expect(exactValues(double.nan), 'double:NaN');
    },
  );

  test(
    'Calculation table stays independent of reference text and cannot mutate',
    () {
      expect(zincCalculationTable.length, 17);
      expect(zincValueForDiameter(.18, 'C'), 10);
      expect(zincValueForDiameter(.19, 'C'), 15);
      expect(zincValueForDiameter(.70, 'Ж'), 60);
      expect(zincValueForDiameter(.65, 'Ж'), 50);
      expect(zincValueForDiameter(.650001, 'Ж'), 60);
      expect(zincValueForDiameter(5.10, 'ОЖ'), 245);
      expect(zincValueForDiameter(5.100001, 'ОЖ'), isNull);
      expect(() => zincCalculationTable[0]['C'] = 999, throwsUnsupportedError);
    },
  );
}
