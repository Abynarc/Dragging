import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wire_drawing_calc/main.dart';

// Records outputs of the real, unchanged screens, never a copied formula.
// Recording is intentionally refused once the baseline exists.
const recordBaseline = bool.fromEnvironment('RECORD_CALCULATION_BASELINE');
const baselinePath = 'test/fixtures/calculations_v3_0_0_11.json';

Future<void> mount(WidgetTester tester, Widget screen, bool dark) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? ThemeData.dark() : ThemeData.light(),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> input(WidgetTester tester, int index, String value) async {
  final field = tester.widget<TextField>(find.byType(TextField).at(index));
  // Use the actual controller and change handler; no scrolling/layout dependency.
  field.controller!.text = value;
  field.onChanged?.call(value);
  await tester.pump();
}

Future<void> calculate(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'Рассчитать');
  tester.widget<ElevatedButton>(button).onPressed!();
  await tester.pumpAndSettle();
}

List<String> texts(WidgetTester tester) =>
    tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
        .toList();

Map<String, Object> linearOutput(WidgetTester tester) => {
  'summaryAndReductions':
      texts(tester)
          .where((text) => RegExp(r'^-?\d+\.\d{2}( ?%)?$').hasMatch(text))
          .toList(),
  'diameters':
      tester
          .widgetList<TextField>(find.byType(TextField))
          .skip(4)
          .map((field) => field.controller!.text)
          .toList(),
};

Future<Map<String, Object>> collect(WidgetTester tester, bool dark) async {
  final output = <String, Object>{};
  final routes = <String, List<String>>{
    'all_15_passes': [
      '5.5',
      '5.2',
      '4.9',
      '4.6',
      '4.3',
      '4.0',
      '3.7',
      '3.4',
      '3.1',
      '2.8',
      '2.5',
      '2.2',
      '1.9',
      '1.6',
      '1.3',
      '1.0',
    ],
    'comma': ['5,5', '4,85', '4,27'],
    'increase_negative_zero': ['4', '5', '-4', '0', '3', ''],
  };
  for (final entry in routes.entries) {
    await mount(tester, const RouteCalculationScreen(), dark);
    for (var i = 0; i < entry.value.length; i++) {
      await input(tester, i, entry.value[i]);
    }
    final reductions =
        texts(tester).where((text) => text.startsWith('Обжатие: ')).toList();
    expect(reductions.length, 15);
    output['route_${entry.key}'] = {'input': entry.value, 'output': reductions};
  }

  final linearCases = [
    ['5.5', '2', '8', '0.7'],
    ['5,5', '2', '8', '0,7'],
    ['5', '4', '1', '0.2'],
    ['6', '1.2', '15', '0.45'],
    ['3', '2.99', '3', ''],
    ['1', '0.18', '5', '0'],
  ];
  for (var caseIndex = 0; caseIndex < linearCases.length; caseIndex++) {
    await mount(tester, const LinearRouteScreen(), dark);
    final values = linearCases[caseIndex];
    for (var i = 0; i < values.length; i++) {
      await input(tester, i, values[i]);
    }
    await calculate(tester);
    final result = linearOutput(tester);
    expect((result['diameters']! as List).length, int.parse(values[2]) + 1);
    expect(
      (result['summaryAndReductions']! as List).length,
      6 + int.parse(values[2]),
    );
    output['linear_$caseIndex'] = {'input': values, 'output': result};
    if (caseIndex == 0) {
      await input(tester, 6, '4.30'); // Edit pass 2 after calculation.
      output['linear_manual_edit'] = {
        'input': {'baseCase': 'linear_0', 'pass': 2, 'diameter': '4.30'},
        'output': linearOutput(tester),
      };
      await calculate(tester);
      expect(
        linearOutput(tester),
        result,
        reason: 'Recalculation must restore the generated route.',
      );
    }
  }

  // Every table row, every boundary and the values immediately around it,
  // including the historical 0.18–0.20 gap and the Ж=60 row.
  const bounds = [
    0.18,
    0.24,
    0.32,
    0.38,
    0.45,
    0.55,
    0.65,
    0.75,
    0.95,
    1.15,
    1.40,
    1.80,
    2.40,
    3.00,
    3.80,
    4.40,
    5.10,
  ];
  final diameters = <String>{'0.19', '0.20', '0.70', '2', '2,0'};
  for (var i = 0; i < bounds.length; i++) {
    for (final delta in [-0.000001, 0.0, 0.000001]) {
      diameters.add((bounds[i] + delta).toStringAsFixed(6));
    }
    if (i > 0) {
      diameters.add(((bounds[i - 1] + bounds[i]) / 2).toStringAsFixed(6));
    }
  }
  for (final group in ['С', 'Ж', 'ОЖ']) {
    await mount(tester, const ZincCalculationScreen(), dark);
    final choice = find.ancestor(
      of: find.text(group),
      matching: find.byType(InkWell),
    );
    tester.widget<InkWell>(choice.first).onTap!();
    await tester.pump();
    await input(tester, 0, '5.5');
    for (final diameter in diameters) {
      await input(tester, 1, diameter);
      await calculate(tester);
      final results =
          texts(tester)
              .where(
                (text) =>
                    text.startsWith(
                      'Количество цинка на заготовке должно быть не менее ',
                    ) ||
                    text == 'Данной группы на заданном диаметре нет',
              )
              .toList();
      expect(results.length, 1, reason: 'Zinc $diameter / $group');
      output['zinc_${group}_$diameter'] = {
        'input': ['5.5', diameter, group],
        'output': results.single,
      };
    }
  }
  await tester.pumpWidget(const SizedBox.shrink());
  return output;
}

void main() {
  testWidgets(
    'Current calculation baseline: exact outputs in both themes',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final baselineFile = File(baselinePath);
      if (recordBaseline && baselineFile.existsSync()) {
        fail(
          'Baseline already exists. Do not overwrite approved historical results.',
        );
      }
      final light = await collect(tester, false);
      final dark = await collect(tester, true);
      expect(dark, light, reason: 'Theme must never affect calculations.');
      // Independent anchors make an empty/incorrect capture fail during recording.
      final mainCase = light['linear_0']! as Map;
      final summary =
          (mainCase['output'] as Map)['summaryAndReductions'] as List;
      expect(summary.take(6).toList(), [
        '86.78 %',
        '22.35 %',
        '112.50',
        '122.50',
        '203.95',
        '213.95',
      ]);
      expect((light['zinc_С_2']! as Map)['output'], endsWith('242.00'));
      expect((light['zinc_Ж_2']! as Map)['output'], endsWith('332.75'));
      expect((light['zinc_ОЖ_2']! as Map)['output'], endsWith('676.50'));
      if (recordBaseline) {
        baselineFile.parent.createSync(recursive: true);
        baselineFile.writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert({'sourceCommit': 'c11bda0508019e5f977a36dbdef5116bcbf504f4', 'appVersion': '3.0.0+11', 'capture': 'Real Flutter screen callbacks and rendered output; both themes', 'cases': light})}\n',
        );
      } else {
        final baseline = jsonDecode(baselineFile.readAsStringSync()) as Map;
        expect(
          light,
          baseline['cases'],
          reason: 'Exact equality; no numeric tolerance.',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
