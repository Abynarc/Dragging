import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wire_drawing_calc/main.dart' as app;
import 'package:wire_drawing_calc/presentation/precision_components.dart';
import 'calculation_regression_test.dart' as h;
import 'workflow_test.dart' show fillLinear, pressReset;

void main() {
  testWidgets(
    'Manual edit rebuilds adjacent reductions only and releases signals',
    (tester) async {
      await h.mount(tester, const app.LinearRouteScreen(), false);
      await fillLinear(tester);
      final form = tester.widget<TextField>(find.byType(TextField).first);
      final rows =
          tester
              .widgetList<PrecisionResultRow>(find.byType(PrecisionResultRow))
              .toList();
      final builders =
          tester
              .widgetList<ValueListenableBuilder<double>>(
                find.byType(ValueListenableBuilder<double>),
              )
              .toList();
      // Field 4 is raw route diameter; edit route diameter 3, affecting reductions 2 and 3.
      await h.input(tester, 7, '3.77');
      final updated =
          tester
              .widgetList<PrecisionResultRow>(find.byType(PrecisionResultRow))
              .toList();
      expect(
        identical(form, tester.widget<TextField>(find.byType(TextField).first)),
        isTrue,
      );
      expect(updated.length, rows.length);
      expect(
        [
          for (var i = 0; i < rows.length; i++)
            if (!identical(rows[i], updated[i])) i,
        ].length,
        2,
      );
      expect(
        updated.where((r) => r.label == 'Обжатие').map((r) => r.value),
        isNot(rows.where((r) => r.label == 'Обжатие').map((r) => r.value)),
      );
      pressReset(tester);
      await tester.pump();
      for (final builder in builders) {
        expect(
          () => builder.valueListenable.addListener(() {}),
          throwsFlutterError,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
