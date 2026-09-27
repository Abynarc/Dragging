import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wire_drawing_calc/presentation/precision_components.dart';
import 'package:wire_drawing_calc/presentation/precision_theme.dart';
import '../tool/precision_prototype.dart';

Future<void> reveal(WidgetTester tester, Finder target, double dy) async {
  for (var i = 0; i < 40 && target.hitTestable().evaluate().isEmpty; i++) {
    final state = tester.state<ScrollableState>(find.byType(Scrollable).first);
    state.position.jumpTo(
      (state.position.pixels + dy).clamp(
        state.position.minScrollExtent,
        state.position.maxScrollExtent,
      ),
    );
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('Units remain visible on an empty unfocused number field', (
    tester,
  ) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        theme: precisionTheme(Brightness.light),
        home: Scaffold(
          body: PrecisionNumberField(
            controller: controller,
            label: 'Диаметр',
            unit: 'мм',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('мм').hitTestable(), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  for (final dark in [false, true]) {
    test('Readable opaque text pairs: dark=$dark', () {
      final p = PrecisionPalette(dark);
      for (final pair in [
        [p.ink, p.surface],
        [p.muted, p.surface],
        [p.ink, p.background],
        [p.accent, p.surface],
        [p.onAccent, p.accent],
        [p.error, p.errorBackground],
      ]) {
        final a = pair[0].computeLuminance();
        final b = pair[1].computeLuminance();
        final ratio = (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
        expect(ratio, greaterThanOrEqualTo(4.5));
      }
    });
    for (final blur in [false, true]) {
      for (final size in [const Size(320, 640), const Size(640, 360)]) {
        for (final scale in [1.0, 2.0]) {
          for (final bottom in [24.0, 48.0]) {
            testWidgets(
              'Shell dark=$dark blur=$blur size=$size scale=$scale inset=$bottom',
              (tester) async {
                tester.view.devicePixelRatio = 1;
                tester.view.physicalSize = size;
                tester.view.viewPadding = FakeViewPadding(
                  top: 24,
                  bottom: bottom,
                );
                tester.view.padding = FakeViewPadding(top: 24, bottom: bottom);
                addTearDown(tester.view.reset);
                final controller = TextEditingController(text: '5,5');
                addTearDown(controller.dispose);
                await tester.pumpWidget(
                  MaterialApp(
                    theme: precisionTheme(
                      dark ? Brightness.dark : Brightness.light,
                    ),
                    builder:
                        (context, child) => MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(textScaler: TextScaler.linear(scale)),
                          child: child!,
                        ),
                    home: PrecisionScaffold(
                      title: 'Линейный маршрут',
                      blur: blur,
                      onToggleTheme: () {},
                      navigation: const SizedBox(
                        height: 48,
                        child: Center(child: Text('Навигация')),
                      ),
                      body: ListView(
                        children: [
                          PrecisionPanel(
                            child: Column(
                              children: [
                                PrecisionNumberField(
                                  controller: controller,
                                  label: 'Диаметр',
                                  unit: 'мм',
                                ),
                                const SizedBox(height: 16),
                                const PrecisionNumberFieldForTest(),
                                PrecisionActions(
                                  onCalculate: () {},
                                  onReset: () {},
                                ),
                                const PrecisionResultRow(
                                  label: 'Общее обжатие',
                                  value: '86.78 %',
                                ),
                                PrecisionChoices(
                                  labels: const [
                                    'Формулы и источники',
                                    'Таблица цинка',
                                  ],
                                  selected: 0,
                                  onSelected: (_) {},
                                ),
                                const PrecisionError(
                                  message: 'Неверные входные данные',
                                ),
                                const SizedBox(height: 500),
                                const Text('by DK and IB'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                expect(
                  find.byType(BackdropFilter),
                  findsNWidgets(blur ? 2 : 0),
                );
                await tester.tap(find.byType(TextField).first);
                // Android keyboard resize; bottom padding is consumed by IME.
                final keyboard = size.height > 400 ? 240.0 : 110.0;
                tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
                tester.view.padding = const FakeViewPadding(top: 24);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                final nav = tester.getRect(find.text('Навигация'));
                expect(nav.bottom, lessThanOrEqualTo(size.height - keyboard));
                tester.view.viewInsets = const FakeViewPadding();
                tester.view.padding = FakeViewPadding(top: 24, bottom: bottom);
                await tester.pumpAndSettle();
                final position =
                    tester
                        .state<ScrollableState>(find.byType(Scrollable).first)
                        .position;
                position.jumpTo(position.maxScrollExtent);
                await tester.pumpAndSettle();
                final footer = tester.getRect(find.text('by DK and IB'));
                expect(footer.bottom, lessThanOrEqualTo(size.height - bottom));
                expect(
                  tester.getRect(find.text('Навигация')).bottom,
                  lessThanOrEqualTo(size.height - bottom),
                );
                expect(tester.takeException(), isNull);
                await tester.pumpWidget(const SizedBox());
              },
            );
          }
        }
      }
    }
  }

  for (final highContrast in [false, true]) {
    testWidgets('Accessibility disables blur: highContrast=$highContrast', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              highContrast: highContrast,
              disableAnimations: !highContrast,
            ),
            child: PrecisionScaffold(
              title: 'Проверка',
              blur: true,
              onToggleTheme: () {},
              body: const Text('Текст'),
            ),
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);
    });
  }

  testWidgets('Prototype navigation with large text and landscape keyboard', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(640, 360);
    tester.view.padding = const FakeViewPadding(top: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
    tester.view.viewInsets = const FakeViewPadding(bottom: 110);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const PrecisionPrototype());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Компоненты'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.text('Компоненты')).bottom,
      lessThanOrEqualTo(250),
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Prototype edits survive theme changes and recalculate/reset', (
    tester,
  ) async {
    await tester.pumpWidget(const PrecisionPrototype());
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('route-1'));
    await reveal(tester, row, 250);
    final field = find.descendant(of: row, matching: find.byType(TextField));
    await tester.enterText(field, '4,30');
    await tester.pump();
    await tester.tap(find.byTooltip('Переключить тему'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, '4,30');
    await reveal(tester, find.text('Рассчитать'), -250);
    await tester.tap(find.text('Рассчитать'));
    await tester.pumpAndSettle();
    await reveal(tester, row, 250);
    expect(tester.widget<TextField>(field).controller!.text, isNot('4,30'));
    await reveal(tester, find.text('Сброс'), -250);
    await tester.tap(find.text('Сброс'));
    await tester.pumpAndSettle();
    expect(find.byType(PrecisionRouteRow), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

// A long validation message also exercises intrinsic height at large text scale.
class PrecisionNumberFieldForTest extends StatefulWidget {
  const PrecisionNumberFieldForTest({super.key});
  @override
  State<PrecisionNumberFieldForTest> createState() => _ErrorFieldState();
}

class _ErrorFieldState extends State<PrecisionNumberFieldForTest> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PrecisionNumberField(
    controller: controller,
    label: 'Чистовой диаметр',
    error: 'Чистовой диаметр должен быть меньше заготовки',
  );
}
