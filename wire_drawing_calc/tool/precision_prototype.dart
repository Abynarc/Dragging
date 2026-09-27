// Separate developer entry point; not imported by the shipping application.
// flutter run --profile -t tool/precision_prototype.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kProfileMode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:wire_drawing_calc/application/linear_calculation.dart';
import 'package:wire_drawing_calc/presentation/precision_components.dart';
import 'package:wire_drawing_calc/presentation/precision_theme.dart';

void main() => runApp(const PrecisionPrototype());

class PrecisionPrototype extends StatefulWidget {
  const PrecisionPrototype({super.key});
  @override
  State<PrecisionPrototype> createState() => _PrecisionPrototypeState();
}

class _PrecisionPrototypeState extends State<PrecisionPrototype> {
  bool dark = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: precisionTheme(Brightness.light),
    darkTheme: precisionTheme(Brightness.dark),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    themeAnimationDuration: Duration.zero,
    home: PrototypePage(onToggleTheme: () => setState(() => dark = !dark)),
  );
}

class PrototypePage extends StatefulWidget {
  const PrototypePage({super.key, required this.onToggleTheme});
  final VoidCallback onToggleTheme;
  @override
  State<PrototypePage> createState() => _PrototypePageState();
}

class _PrototypePageState extends State<PrototypePage> {
  final calculation = LinearCalculation();
  final raw = TextEditingController(text: '6');
  final finished = TextEditingController(text: '1.2');
  final passes = TextEditingController(
    text:
        const int.fromEnvironment(
          'PROTOTYPE_PASSES',
          defaultValue: 15,
        ).toString(),
  );
  final carbon = TextEditingController(text: '0.45');
  final disabled = TextEditingController(text: '2.00');
  final scroll = ScrollController();
  List<TextEditingController> rows = [];
  bool blur = false, showError = false, recording = false;
  int group = 0, tab = 0;
  String? error;
  final frames = <Map<String, int>>[];
  Map<String, Object>? sampleConfig;

  @override
  void initState() {
    super.initState();
    calculate();
    SchedulerBinding.instance.addTimingsCallback(onTimings);
  }

  void onTimings(List<FrameTiming> timings) {
    if (!recording) return;
    for (final frame in timings) {
      if (frames.length >= 20000) break;
      frames.add({
        'buildUs': frame.buildDuration.inMicroseconds,
        'rasterUs': frame.rasterDuration.inMicroseconds,
        'totalUs': frame.totalSpan.inMicroseconds,
      });
    }
  }

  void replaceRows() {
    final old = rows;
    rows =
        calculation.diameters
            .map((v) => TextEditingController(text: v))
            .toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in old) {
        controller.dispose();
      }
    });
  }

  void calculate() {
    try {
      calculation.calculate(
        rawDiameter: raw.text,
        finalDiameter: finished.text,
        passesText: passes.text,
        carbonText: carbon.text,
      );
      replaceRows();
      error = null;
    } catch (e) {
      error = e.toString();
    }
  }

  void toggleRecording() {
    if (recording) {
      recording = false;
      // Android limits individual log entries. Emit short JSONL records after
      // sampling so log output does not affect the measured frames.
      debugPrint(
        'PRECISION_PROFILE ${jsonEncode({'type': 'sample', 'configuration': sampleConfig, 'frameCount': frames.length, 'truncated': frames.length >= 20000})}',
      );
      for (var i = 0; i < frames.length; i++) {
        debugPrint(
          'PRECISION_PROFILE ${jsonEncode({'type': 'frame', 'index': i, ...frames[i]})}',
        );
      }
      debugPrint('PRECISION_PROFILE ${jsonEncode({'type': 'end'})}');
    } else {
      frames.clear();
      sampleConfig = {
        'profileMode': kProfileMode,
        'startedUtc': DateTime.now().toUtc().toIso8601String(),
        'requestedBlur': blur,
        'passes': rows.length - 1,
        'brightness': Theme.of(context).brightness.name,
        'keyboardInset': MediaQuery.viewInsetsOf(context).bottom,
        'disableAnimations': MediaQuery.of(context).disableAnimations,
        'highContrast': MediaQuery.of(context).highContrast,
      };
      recording = true;
    }
    setState(() {});
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(onTimings);
    for (final c in [raw, finished, passes, carbon, disabled, ...rows]) {
      c.dispose();
    }
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = calculation.result;
    return PrecisionScaffold(
      title: 'Precision Glass · прототип',
      blur: blur,
      onToggleTheme: widget.onToggleTheme,
      navigation: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: PrecisionChoices(
          labels: const ['Маршрут', 'Компоненты'],
          selected: tab,
          onSelected: (value) => setState(() => tab = value),
        ),
      ),
      body: ListView.builder(
        controller: scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
        itemCount: tab == 0 ? rows.length + 3 : 3,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Размытие'),
                  value: blur,
                  onChanged: recording ? null : (v) => setState(() => blur = v),
                ),
                OutlinedButton(
                  onPressed: toggleRecording,
                  child: Text(
                    recording ? 'Завершить замер' : 'Записать времена кадров',
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          }
          if (tab == 1) {
            if (index == 2) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('by DK and IB', textAlign: TextAlign.center),
              );
            }
            return PrecisionPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrecisionChoices(
                    labels: const ['С', 'Ж', 'ОЖ'],
                    selected: group,
                    onSelected: (v) => setState(() => group = v),
                  ),
                  const SizedBox(height: 16),
                  PrecisionNumberField(
                    controller: disabled,
                    label: 'Недоступное поле',
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  const PrecisionActions(),
                  const SizedBox(height: 16),
                  PrecisionChoices(
                    labels: const ['Формулы и источники', 'Таблица цинка'],
                    selected: 0,
                    onSelected: null,
                  ),
                  const SizedBox(height: 16),
                  const PrecisionError(message: 'Неверные входные данные'),
                ],
              ),
            );
          }
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: PrecisionPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Линейный маршрут',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 18),
                    PrecisionNumberField(
                      controller: raw,
                      label: 'Диаметр заготовки',
                      unit: 'мм',
                    ),
                    const SizedBox(height: 16),
                    PrecisionNumberField(
                      controller: finished,
                      label: 'Чистовой диаметр',
                      unit: 'мм',
                    ),
                    const SizedBox(height: 16),
                    PrecisionNumberField(
                      controller: passes,
                      label: 'Число проходов',
                    ),
                    const SizedBox(height: 16),
                    PrecisionNumberField(
                      controller: carbon,
                      label: 'Углерод',
                      unit: '%',
                      error: showError ? 'Пример состояния ошибки' : null,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Показать ошибку поля'),
                      value: showError,
                      onChanged: (v) => setState(() => showError = v),
                    ),
                    PrecisionActions(
                      onCalculate: () => setState(calculate),
                      onReset: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() {
                          calculation.reset();
                          replaceRows();
                          error = null;
                          for (final c in [raw, finished, passes, carbon]) {
                            c.clear();
                          }
                        });
                      },
                    ),
                    if (error != null) PrecisionError(message: error!),
                    if (result != null) ...[
                      const SizedBox(height: 18),
                      PrecisionResultRow(
                        label: 'Общее обжатие',
                        value: '${result.totalReduction.toStringAsFixed(2)} %',
                      ),
                      PrecisionResultRow(
                        label: 'Единичное обжатие',
                        value: '${result.unitReduction.toStringAsFixed(2)} %',
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          if (index == rows.length + 2) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text('by DK and IB', textAlign: TextAlign.center),
            );
          }
          final row = index - 2;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PrecisionRouteRow(
              key: ValueKey('route-$row'),
              index: row,
              controller: rows[row],
              reduction:
                  row == 0
                      ? '—'
                      : '${calculation.reductions[row - 1].toStringAsFixed(2)} %',
              onChanged:
                  (value) =>
                      setState(() => calculation.editDiameter(row, value)),
            ),
          );
        },
      ),
    );
  }
}
