import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wire_drawing_calc/main.dart' as app;
import 'reference/original_app.dart' as old;
import 'calculation_regression_test.dart' as h;
import 'workflow_test.dart' as workflow;

// Turn on for redesigned UI acceptance. Legacy failures are reported explicitly;
// a green characterization run does NOT certify absence of overlaps.
const requireSafeUi = bool.fromEnvironment('REQUIRE_SAFE_UI');

List<String> navigationOverlaps(
  WidgetTester tester,
  double height,
  double bottom, {
  bool atScrollEnd = false,
}) {
  if (bottom == 0) return [];
  final blocked = Rect.fromLTRB(
    0,
    height - bottom,
    tester.view.physicalSize.width,
    height,
  );
  final issues = <String>[];
  final targets = find.byWidgetPredicate(
    (w) =>
        w is Text ||
        w is TextField ||
        w is IconButton ||
        w is ButtonStyleButton,
  );
  for (final element in targets.evaluate()) {
    final box = element.findRenderObject();
    if (box is! RenderBox || !box.hasSize) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    // Mounted scroll children can be outside the viewport. Do not report
    // invisible, clipped content as if Android painted over it.
    var visibleRect = rect;
    double? viewportBottom;
    RenderObject? ancestor = box.parent;
    while (ancestor != null) {
      if (ancestor is RenderBox &&
          (ancestor is RenderAbstractViewport ||
              ancestor is RenderClipRect ||
              ancestor is RenderClipRRect)) {
        visibleRect = visibleRect.intersect(
          ancestor.localToGlobal(Offset.zero) & ancestor.size,
        );
        if (ancestor is RenderAbstractViewport) {
          final edge =
              ancestor.localToGlobal(Offset.zero).dy + ancestor.size.height;
          if (viewportBottom == null || edge < viewportBottom) {
            viewportBottom = edge;
          }
        }
      }
      ancestor = ancestor.parent;
    }
    if (!visibleRect.isEmpty && visibleRect.overlaps(blocked)) {
      final widget = element.widget;
      issues.add(
        '${widget is Text ? widget.data : widget.runtimeType}: bottom=${rect.bottom} safeBottom=${height - bottom}',
      );
    }
    if (atScrollEnd &&
        viewportBottom != null &&
        rect.bottom > viewportBottom + .001 &&
        rect.left < blocked.right &&
        rect.right > 0) {
      issues.add(
        '${element.widget.runtimeType}: clipped below viewport at end of scroll',
      );
    }
  }
  return issues;
}

void main() {
  testWidgets(
    'Overlap detector rejects covered controls and accepts SafeArea',
    (tester) async {
      for (final safe in [false, true]) {
        Widget content = Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.light_mode)),
            const Text('by DK and IB'),
          ],
        );
        if (safe) content = SafeArea(child: content);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(800, 600),
                padding: EdgeInsets.only(bottom: 48),
                viewPadding: EdgeInsets.only(bottom: 48),
              ),
              child: Scaffold(body: content),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(navigationOverlaps(tester, 600, 48).isEmpty, safe);
      }
    },
  );

  testWidgets(
    'Android navigation contract: all old screens and future strict gate',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final report = <Map<String, Object>>[];
      var layoutErrors = <String>[];
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.startsWith('A RenderFlex overflowed')) {
          layoutErrors.add(message.split('\n').first);
        } else {
          previousErrorHandler?.call(details);
        }
      };
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      // Pairwise coverage: portrait/landscape, small screen, 100/150/200% text,
      // keyboard open/closed, no inset/gesture/three-button navigation, both themes.
      final profiles = [
        (const Size(360, 800), 1.0, 0.0),
        (const Size(800, 360), 1.0, 160.0),
        (const Size(320, 640), 1.5, 0.0),
        (const Size(360, 800), 2.0, 280.0),
      ];
      for (final dark in [false, true]) {
        for (final profile in profiles) {
          final (size, scale, keyboard) = profile;
          for (final bottom in [0.0, 24.0, 48.0]) {
            for (final screen in [
              'home',
              'route',
              'linear',
              'zinc',
              'formulas',
              'table',
            ]) {
              tester.view.physicalSize = size;
              final legacy = workflow.useOriginal;
              final widget = switch (screen) {
                'home' =>
                  legacy
                      ? old.HomeScreen(darkMode: dark, toggleDarkMode: () {})
                      : app.HomeScreen(darkMode: dark, toggleDarkMode: () {}),
                'route' =>
                  legacy
                      ? const old.RouteCalculationScreen()
                      : const app.RouteCalculationScreen(),
                'linear' => workflow.linear(),
                'zinc' => workflow.zinc(),
                _ =>
                  legacy
                      ? const old.ReferenceScreen()
                      : const app.ReferenceScreen(),
              };
              await tester.pumpWidget(const SizedBox.shrink());
              layoutErrors = [];
              await tester.pumpWidget(
                MaterialApp(
                  theme: dark ? ThemeData.dark() : ThemeData.light(),
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: size,
                      textScaler: TextScaler.linear(scale),
                      viewPadding: EdgeInsets.only(bottom: bottom),
                      padding: EdgeInsets.only(
                        bottom: keyboard > 0 ? 0 : bottom,
                      ),
                      viewInsets: EdgeInsets.only(bottom: keyboard),
                    ),
                    child: widget,
                  ),
                ),
              );
              void drainErrors() {
                Object? error;
                while ((error = tester.takeException()) != null) {
                  final message = error.toString();
                  if (!message.contains('overflowed')) fail(message);
                  layoutErrors.add(message.split('\n').first);
                }
              }

              drainErrors();
              await tester.pumpAndSettle();
              drainErrors();
              if (screen == 'table') {
                final element = tester.element(find.byType(TabBar));
                DefaultTabController.of(element).animateTo(1);
                await tester.pumpAndSettle();
                drainErrors();
              }
              final stages =
                  screen == 'linear' || screen == 'zinc'
                      ? ['initial', 'result', 'error', 'reset']
                      : ['initial'];
              for (final stage in stages) {
                if (stage == 'result') {
                  if (screen == 'linear') {
                    await workflow.fillLinear(tester);
                  } else {
                    await h.input(tester, 0, '5.5');
                    await h.input(tester, 1, '2');
                    tester
                        .widget<InkWell>(
                          find
                              .ancestor(
                                of: find.text('Ж'),
                                matching: find.byType(InkWell),
                              )
                              .first,
                        )
                        .onTap!();
                    await h.calculate(tester);
                  }
                } else if (stage == 'error') {
                  await h.input(tester, 1, '6');
                  await h.calculate(tester);
                } else if (stage == 'reset') {
                  if (legacy && screen == 'linear') {
                    expect(
                      () => workflow.pressReset(tester),
                      throwsUnsupportedError,
                    );
                  } else {
                    workflow.pressReset(tester);
                  }
                  await tester.pumpAndSettle();
                }
                drainErrors();
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
                  drainErrors();
                  final issues = navigationOverlaps(
                    tester,
                    size.height,
                    bottom,
                    atScrollEnd: end,
                  );
                  report.add({
                    'screen': screen,
                    'stage': stage,
                    'end': end,
                    'dark': dark,
                    'size': '${size.width}x${size.height}',
                    'textScale': scale,
                    'keyboard': keyboard,
                    'navigationInset': bottom,
                    'overlaps': issues,
                    'layoutErrors': List.of(layoutErrors),
                  });
                }
              }
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      FlutterError.onError = previousErrorHandler;
      final failures =
          report
              .where(
                (r) =>
                    (r['overlaps'] as List).isNotEmpty ||
                    (r['layoutErrors'] as List).isNotEmpty,
              )
              .toList();
      if (const bool.fromEnvironment('RECORD_NAV')) {
        final file = File(
          '../docs/verification/step-4/navigation-contract.json',
        );
        if (file.existsSync()) {
          fail('Refusing to overwrite original layout findings.');
        }
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert({'acceptancePassed': failures.isEmpty, 'strictGate': requireSafeUi, 'note': 'Pairwise widget matrix, not physical Android integration acceptance.', 'checks': report})}\n',
        );
      }
      if (requireSafeUi || !workflow.useOriginal) {
        expect(
          failures,
          isEmpty,
          reason:
              'System UI must not obscure redesigned content or hit targets.',
        );
      } else {
        expect(
          failures,
          isNotEmpty,
          reason:
              'Legacy defects must remain visible in characterization. Enable REQUIRE_SAFE_UI for redesigned acceptance.',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
