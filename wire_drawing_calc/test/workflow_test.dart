import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wire_drawing_calc/main.dart' as app;
import 'reference/original_app.dart' as old;
import 'calculation_regression_test.dart' as h;

const useOriginal = bool.fromEnvironment('USE_ORIGINAL');
Widget linear() =>
    useOriginal ? const old.LinearRouteScreen() : const app.LinearRouteScreen();
Widget zinc() =>
    useOriginal
        ? const old.ZincCalculationScreen()
        : const app.ZincCalculationScreen();

Future<void> fillLinear(WidgetTester tester, [String n = '8']) async {
  final values = ['5.5', '2', n, '0.7'];
  for (var i = 0; i < 4; i++) {
    await h.input(tester, i, values[i]);
  }
  await h.calculate(tester);
}

void pressReset(WidgetTester tester) =>
    tester
        .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Сброс'))
        .onPressed!();

void main() {
  testWidgets(
    'Repeated calculation releases replaced controllers and focus nodes',
    (tester) async {
      // This is a target regression test for the explicit lifecycle fix in step 5.
      await h.mount(tester, const app.LinearRouteScreen(), false);
      await fillLinear(tester);
      for (var i = 0; i < 25; i++) {
        final oldField = tester.widget<TextField>(find.byType(TextField).at(4));
        final oldEditable = tester.widget<EditableText>(
          find.byType(EditableText).at(4),
        );
        oldEditable.focusNode.requestFocus();
        await tester.pump();
        await fillLinear(tester, i.isEven ? '15' : '8');
        expect(
          () => oldField.controller!.addListener(() {}),
          throwsA(isA<FlutterError>()),
        );
        expect(
          () => oldEditable.focusNode.addListener(() {}),
          throwsA(isA<FlutterError>()),
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
    skip: useOriginal,
  );

  testWidgets(
    'Rebuilds preserve entered text, selection, focus and calculated values',
    (tester) async {
      Widget root(bool dark) => MaterialApp(
        theme: dark ? ThemeData.dark() : ThemeData.light(),
        home: linear(),
      );
      await tester.pumpWidget(root(false));
      await tester.pumpAndSettle();
      await fillLinear(tester);
      await h.input(tester, 6, '4.30');
      final field = tester.widget<TextField>(find.byType(TextField).at(6));
      final editable = tester.widget<EditableText>(
        find.byType(EditableText).at(6),
      );
      field.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 2,
      );
      editable.focusNode.requestFocus();
      await tester.pumpAndSettle();
      final scroll = tester
          .stateList<ScrollableState>(find.byType(Scrollable))
          .firstWhere((state) => state.position.axis == Axis.vertical);
      scroll.position.jumpTo(scroll.position.maxScrollExtent / 2);
      await tester.pumpAndSettle();
      final offset = scroll.position.pixels;
      final result = h.linearOutput(tester);
      await tester.pumpWidget(root(true));
      await tester.pumpAndSettle();
      expect(h.linearOutput(tester), result);
      expect(
        field.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 2),
      );
      expect(editable.focusNode.hasFocus, isTrue);
      expect(scroll.position.pixels, offset);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final dark in [false, true]) {
    testWidgets('Route editing, clearing and permissive input; dark=$dark', (
      tester,
    ) async {
      await h.mount(
        tester,
        useOriginal
            ? const old.RouteCalculationScreen()
            : const app.RouteCalculationScreen(),
        dark,
      );
      for (var i = 0; i < 3; i++) {
        await h.input(tester, i, ['5.5', '4.85', '4.27'][i]);
      }
      List<String> reductions() =>
          h.texts(tester).where((s) => s.startsWith('Обжатие: ')).toList();
      final base = reductions();
      expect(base.length, 15);
      expect(base.take(2), ['Обжатие: 22.24%', 'Обжатие: 22.49%']);
      await h.input(tester, 1, '');
      expect(reductions(), List.filled(15, 'Обжатие: 0.00%'));
      await h.input(tester, 1, '4,85');
      expect(reductions(), base);
      await h.input(tester, 2, '-4.27');
      expect(reductions(), base);
      await h.input(tester, 0, '4');
      await h.input(tester, 1, '5');
      expect(reductions().first, 'Обжатие: -56.25%');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Linear workflow, errors, editing and reset; dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1100, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await h.mount(tester, linear(), dark);
      await fillLinear(tester);
      final base = h.linearOutput(tester);
      await h.input(tester, 6, '4.30');
      final edited = h.linearOutput(tester);
      expect(
        (edited['summaryAndReductions'] as List).take(6),
        (base['summaryAndReductions'] as List).take(6),
      );
      expect((edited['summaryAndReductions'] as List).skip(6).take(3), [
        '22.24%',
        '21.39%',
        '23.54%',
      ]);
      await h.input(tester, 1, '6');
      await h.calculate(tester);
      expect(
        find.text('Чистовой диаметр должен быть меньше заготовки'),
        findsOneWidget,
      );
      expect(
        h.linearOutput(tester),
        edited,
        reason: 'Invalid input retains prior results.',
      );
      await h.input(tester, 1, '2');
      await h.calculate(tester);
      expect(h.linearOutput(tester), base);
      if (useOriginal) {
        expect(
          () => pressReset(tester),
          throwsUnsupportedError,
          reason: 'Explicit characterization of the known original defect.',
        );
      } else {
        // Focus the edited row too: disposing a still-mounted controller is unsafe.
        final editable = tester.widget<EditableText>(
          find.byType(EditableText).at(6),
        );
        editable.focusNode.requestFocus();
        await tester.pump();
        pressReset(tester);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(TextField), findsNWidgets(4));
        expect(
          tester
              .widgetList<TextField>(find.byType(TextField))
              .map((f) => f.controller!.text),
          everyElement(''),
        );
        expect((h.linearOutput(tester)['summaryAndReductions'] as List), [
          '0.00 %',
          '0.00 %',
          '0.00',
          '0.00',
          '0.00',
          '0.00',
        ]);
        pressReset(tester);
        await tester.pumpAndSettle();
        await fillLinear(tester, '1');
        expect(find.byType(TextField), findsNWidgets(6));
        await fillLinear(tester, '15');
        expect(find.byType(TextField), findsNWidgets(20));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Carbon focus, cursor, comma prefix, retained values; dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(1100, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await h.mount(tester, linear(), dark);
        final carbon = tester.widget<TextField>(find.byType(TextField).at(3));
        final editable = tester.widget<EditableText>(
          find.byType(EditableText).at(3),
        );
        editable.focusNode.requestFocus();
        await tester.pump();
        expect(carbon.controller!.text, '0,');
        expect(carbon.controller!.selection.baseOffset, 2);
        editable.focusNode.unfocus();
        await tester.pump();
        expect(carbon.controller!.text, '');
        await h.input(tester, 3, ',7');
        expect(carbon.controller!.text, '0.7');
        expect(carbon.controller!.selection.baseOffset, 3);
        editable.focusNode.requestFocus();
        await tester.pump();
        editable.focusNode.unfocus();
        await tester.pump();
        expect(carbon.controller!.text, '0.7');
        await h.input(tester, 3, '0,0.7');
        expect(
          carbon.controller!.text,
          '0,0.7',
          reason: 'Do not silently tighten old validation.',
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('Zinc error priority, clearing result and reset; dark=$dark', (
      tester,
    ) async {
      await h.mount(tester, zinc(), dark);
      await h.calculate(tester);
      expect(
        find.text('Введите диаметры заготовки и готовой проволоки'),
        findsOneWidget,
      );
      await h.input(tester, 0, '0');
      await h.input(tester, 1, '0');
      await h.calculate(tester);
      expect(find.text('Выберите группу цинка (С, Ж или ОЖ)'), findsOneWidget);
      tester
          .widget<InkWell>(
            find
                .ancestor(of: find.text('Ж'), matching: find.byType(InkWell))
                .first,
          )
          .onTap!();
      await h.calculate(tester);
      expect(
        find.text(
          'Диаметр готовой проволоки должен быть меньше диаметра заготовки',
        ),
        findsOneWidget,
      );
      await h.input(tester, 0, '5.5');
      await h.input(tester, 1, '2');
      await h.calculate(tester);
      final historic = jsonDecode(File(h.baselinePath).readAsStringSync());
      final result = historic['cases']['zinc_Ж_2']['output'] as String;
      expect(find.text(result), findsOneWidget);
      await h.input(tester, 1, '0.1');
      await h.calculate(tester);
      expect(
        find.text('Данной группы на заданном диаметре нет'),
        findsOneWidget,
      );
      expect(find.text(result), findsNothing);
      pressReset(tester);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .map((f) => f.controller!.text),
        everyElement(''),
      );
      await h.input(tester, 0, '5.5');
      await h.input(tester, 1, '2');
      await h.calculate(tester);
      expect(find.text('Выберите группу цинка (С, Ж или ОЖ)'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Theme and navigation do not create persistent calculations', (
    tester,
  ) async {
    await tester.pumpWidget(
      useOriginal ? const old.WireDrawingApp() : const app.WireDrawingApp(),
    );
    await tester.pumpAndSettle();
    tester.widget<IconButton>(find.byType(IconButton).first).onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Расчёт линейного маршрута'));
    await tester.pumpAndSettle();
    await fillLinear(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Расчёт линейного маршрута'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(4));
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller!.text),
      everyElement(''),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
