import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wire_drawing_calc/main.dart';
import 'package:wire_drawing_calc/presentation/precision_theme.dart';
import 'calculation_regression_test.dart' as h;
import 'navigation_insets_test.dart' show navigationOverlaps;
import 'workflow_test.dart' show fillLinear;

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

void main() {
  test('Contrast on final solid and glass compositions', () {
    for (final dark in [false, true]) {
      final p = PrecisionPalette(dark);
      for (final background in [p.surface, p.background, p.soft]) {
        expect(contrast(p.ink, background), greaterThanOrEqualTo(4.5));
        expect(contrast(p.muted, background), greaterThanOrEqualTo(4.5));
        expect(contrast(p.line, background), greaterThanOrEqualTo(3));
        expect(contrast(p.accent, background), greaterThanOrEqualTo(4.5));
      }
      for (var i = 0; i <= 100; i++) {
        final backdrop = Color.lerp(p.aura, p.background, i / 100)!;
        final glass = Color.alphaBlend(p.glass, backdrop);
        expect(contrast(p.ink, glass), greaterThanOrEqualTo(4.5));
        expect(contrast(p.line, glass), greaterThanOrEqualTo(3));
      }
      expect(contrast(p.error, p.errorBackground), greaterThanOrEqualTo(4.5));
      expect(contrast(p.onAccent, p.accent), greaterThanOrEqualTo(4.5));
    }
  });

  for (final width in [320.0, 360.0, 390.0, 600.0, 1024.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        'All screens width=$width scale=$scale, both themes/orientations/IME',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          for (final dark in [false, true]) {
            for (final size in [Size(width, 800), Size(800, width)]) {
              tester.view.physicalSize = size;
              for (final name in [
                'home',
                'route',
                'linear',
                'zinc',
                'formulas',
                'table',
              ]) {
                final screen = switch (name) {
                  'home' => HomeScreen(darkMode: dark, toggleDarkMode: () {}),
                  'route' => const RouteCalculationScreen(),
                  'linear' => const LinearRouteScreen(),
                  'zinc' => const ZincCalculationScreen(),
                  _ => const ReferenceScreen(),
                };
                Future<void> mount(double keyboard) async {
                  await tester.pumpWidget(
                    MaterialApp(
                      theme: precisionTheme(
                        dark ? Brightness.dark : Brightness.light,
                      ),
                      home: MediaQuery(
                        data: MediaQueryData(
                          size: size,
                          textScaler: TextScaler.linear(scale),
                          viewPadding: const EdgeInsets.only(
                            top: 24,
                            bottom: 48,
                          ),
                          padding: EdgeInsets.only(
                            top: 24,
                            bottom: keyboard > 0 ? 0 : 48,
                          ),
                          viewInsets: EdgeInsets.only(bottom: keyboard),
                        ),
                        child: screen,
                      ),
                    ),
                  );
                  await tester.pumpAndSettle();
                }

                await tester.pumpWidget(const SizedBox());
                await mount(0);
                if (name == 'table') {
                  DefaultTabController.of(
                    tester.element(find.byType(TabBar)),
                  ).animateTo(1);
                  await tester.pumpAndSettle();
                }
                if (name == 'linear') await fillLinear(tester, '15');
                if (name == 'route') {
                  await h.input(tester, 0, '12345678901234567890.123456');
                  await h.input(tester, 1, '1');
                }
                for (final keyboard in [0.0, size.height * .35]) {
                  await mount(keyboard);
                  for (final end in [false, true]) {
                    for (final state in tester.stateList<ScrollableState>(
                      find.byType(Scrollable),
                    )) {
                      if (state.position.axis == Axis.vertical) {
                        state.position.jumpTo(
                          end ? state.position.maxScrollExtent : 0,
                        );
                      }
                    }
                    await tester.pumpAndSettle();
                    expect(
                      tester.takeException(),
                      isNull,
                      reason: '$name $size dark=$dark IME=$keyboard end=$end',
                    );
                    expect(
                      navigationOverlaps(
                        tester,
                        size.height,
                        48,
                        atScrollEnd: end,
                      ),
                      isEmpty,
                    );
                  }
                }
              }
            }
          }
          await tester.pumpWidget(const SizedBox());
        },
        timeout: const Timeout(Duration(minutes: 3)),
      );
    }
  }

  testWidgets(
    'Fields have spoken units, keyboard traversal and stable focus across resize',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 800);
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: precisionTheme(Brightness.light),
            home: const LinearRouteScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel(RegExp('D Заг.*мм')), findsWidgets);
        final fieldSemantics =
            tester
                .getSemantics(find.byType(TextField).first)
                .getSemanticsData();
        expect(fieldSemantics.label, contains('D Заг.'));
        expect(fieldSemantics.hasFlag(SemanticsFlag.isTextField), isTrue);
        final fields =
            tester.widgetList<EditableText>(find.byType(EditableText)).toList();
        fields[0].focusNode.requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(fields[1].focusNode.hasFocus, isTrue);
        await h.input(tester, 1, '2,75');
        fields[1].controller.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 2,
        );
        tester.view.physicalSize = const Size(800, 390);
        await tester.pumpAndSettle();
        expect(fields[1].focusNode.hasFocus, isTrue);
        expect(fields[1].controller.text, '2,75');
        expect(
          fields[1].controller.selection,
          const TextSelection(baseOffset: 0, extentOffset: 2),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'Home touch targets and transparency controls remain accessible',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(const WireDrawingApp());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(BackdropFilter), findsNothing);
        final themeSemantics =
            tester
                .getSemantics(find.byTooltip('Переключить тему'))
                .getSemanticsData();
        expect(themeSemantics.label, 'Переключить тему');
        expect(themeSemantics.hasAction(SemanticsAction.tap), isTrue);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await tester.tap(find.byTooltip('Без прозрачности'));
        await tester.pumpAndSettle();
        expect(find.byType(BackdropFilter), findsOneWidget);
        await tester.tap(find.byTooltip('Переключить тему'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      } finally {
        semantics.dispose();
      }
    },
  );
}
