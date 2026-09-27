import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'calculation_regression_test.dart' as h;
import 'reference/original_app.dart' as old;
import 'support/exact_values.dart';

const rawBaselinePath = 'test/fixtures/raw_calculations_step4.json';

void main() {
  testWidgets(
    'Frozen original callbacks: raw doubles, errors and seeded inputs',
    (tester) async {
      const record = bool.fromEnvironment('RECORD_STEP4');
      final file = File(rawBaselinePath);
      if (record && file.existsSync()) {
        fail('Refusing to overwrite the original raw baseline.');
      }
      tester.view.physicalSize = const Size(1100, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cases = <Map<String, Object?>>[];
      final random = Random(450405);

      final routeCases = <List<String>>[
        ['5.5', '4.85', '4.27'],
        ['5,5', '4,85', ''],
        ['0', '-0', '4', '5', '-4', '0', '3', ''],
        ['NaN', 'Infinity', '-Infinity', '1e309', '1e-300', 'x', ' '],
        for (var i = 0; i < 40; i++)
          [
            for (var j = 0; j < 16; j++)
              (random.nextDouble() * 20 - 2).toString(),
          ],
      ];
      for (final values in routeCases) {
        await h.mount(tester, const old.RouteCalculationScreen(), false);
        for (var i = 0; i < values.length; i++) {
          await h.input(tester, i, values[i]);
        }
        cases.add({
          'kind': 'route',
          'input': values,
          'output': exactValues(
            old.referenceRoute(
              tester.state(find.byType(old.RouteCalculationScreen)),
            ),
          ),
        });
      }

      final linearCases = <List<String>>[
        ['5.5', '2', '8', '0.7'],
        ['5,5', '2', '8', '0,7'],
        ['5', '4', '1', '0.2'],
        ['6', '1.2', '15', '0.45'],
        ['6', '1.2', '64', '0.45'],
        ['3', '2.99', '3', ''],
        ['1', '1e-200', '8', '0.7'],
        ['NaN', '2', '8', '0.7'],
        ['Infinity', '2', '8', '0.7'],
        ['5.5', '2', '8', 'NaN'],
        ['5.5', '2', '8', 'Infinity'],
        ['5.5', '2', '8', '0,0.7'],
        ['5.5', '2', '8', '-0'],
        ['', '', '', ''],
        ['0', '2', '8', '0.7'],
        ['5', '0', '8', '0.7'],
        ['5', '2', '0', '0.7'],
        ['5', '2', '-1', '0.7'],
        ['5', '2', '1.5', '0.7'],
        ['5', '5', '8', '0.7'],
        ['5', '6', '8', '0.7'],
        ['-5', '2', '8', '0.7'],
        for (var i = 0; i < 64; i++)
          (() {
            final d = 1 + random.nextDouble() * 15;
            return [
              d.toString(),
              (d * (.01 + random.nextDouble() * .98)).toString(),
              (1 + random.nextInt(64)).toString(),
              random.nextDouble().toString(),
            ];
          })(),
      ];
      for (final values in linearCases) {
        await h.mount(tester, const old.LinearRouteScreen(), false);
        for (var i = 0; i < 4; i++) {
          await h.input(tester, i, values[i]);
        }
        await h.calculate(tester);
        final result = old.referenceLinear(
          tester.state(find.byType(old.LinearRouteScreen)),
        );
        final snackbar = find.byType(SnackBar);
        result['error'] =
            snackbar.evaluate().isEmpty
                ? ''
                : (tester.widget<SnackBar>(snackbar).content as Text).data!;
        cases.add({
          'kind': 'linear',
          'input': values,
          'output': exactValues(result),
        });
      }

      final historic =
          jsonDecode(File(h.baselinePath).readAsStringSync())['cases'] as Map;
      final zincCases = <List<String?>>[
        for (final entry in historic.entries.where(
          (e) => (e.key as String).startsWith('zinc_'),
        ))
          List<String?>.from(entry.value['input'] as List),
        ['', '', null],
        ['5', '2', null],
        ['0', '0', null],
        ['0', '0', 'Ж'],
        ['5', '5', 'Ж'],
        ['5', '6', 'Ж'],
        ['x', '2', 'Ж'],
        ['5', 'x', 'Ж'],
        ['NaN', '2', 'Ж'],
        ['Infinity', '2', 'Ж'],
        ['5', 'NaN', 'Ж'],
        ['5', 'Infinity', 'Ж'],
        ['-5', '-2', 'Ж'],
        ['5', '-0', 'Ж'],
        ['5', '0.179999', 'Ж'],
        ['6', '5.10', 'ОЖ'],
        ['6', '5.100001', 'ОЖ'],
      ];
      for (final values in zincCases) {
        await h.mount(tester, const old.ZincCalculationScreen(), false);
        await h.input(tester, 0, values[0]!);
        await h.input(tester, 1, values[1]!);
        if (values[2] != null) {
          final choice = find.ancestor(
            of: find.text(values[2]!),
            matching: find.byType(InkWell),
          );
          tester.widget<InkWell>(choice.first).onTap!();
          await tester.pump();
        }
        await h.calculate(tester);
        cases.add({
          'kind': 'zinc',
          'input': values,
          'output': exactValues(
            old.referenceZinc(
              tester.state(find.byType(old.ZincCalculationScreen)),
            ),
          ),
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
      if (record) {
        file.writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert({'sourceSha256': 'a6a8286e9f9bda9abbf7366ef89fff9134b418ebfe985b6f55b70f07968cf4f1', 'seed': 450405, 'capture': 'Unchanged original Flutter callbacks; finite IEEE-754 bits, classified non-finite results', 'cases': cases})}\n',
        );
      } else {
        expect(cases, jsonDecode(file.readAsStringSync())['cases']);
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
