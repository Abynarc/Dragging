import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const WireDrawingApp());
}

class WireDrawingApp extends StatelessWidget {
  const WireDrawingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Калькулятор волочения',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Режимы расчёта')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RouteCalculationScreen(),
                    ),
                  ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Расчёт маршрута'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LinearRouteScreen(),
                    ),
                  ),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Расчёт линейного маршрута'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'by DK and IB',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}

class RouteCalculationScreen extends StatefulWidget {
  const RouteCalculationScreen({super.key});

  @override
  State<RouteCalculationScreen> createState() => _RouteCalculationScreenState();
}

class _RouteCalculationScreenState extends State<RouteCalculationScreen> {
  final List<TextEditingController> _diameterControllers = List.generate(
    16,
    (_) => TextEditingController(),
  );
  final List<double> _reductions = List.filled(15, 0);

  double _parseInput(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  void _calculateReductions() {
    try {
      for (int i = 1; i < 16; i++) {
        final double prev = _parseInput(_diameterControllers[i - 1].text);
        final double next = _parseInput(_diameterControllers[i].text);

        if (prev == 0 || next == 0) {
          _reductions[i - 1] = 0;
          continue;
        }

        _reductions[i - 1] = (1 - pow(next / prev, 2)) * 100;
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка в расчётах! Проверьте данные')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Расчёт маршрута')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (int i = 0; i < 16; i++) ...[
              ListTile(
                title: Text(i == 0 ? 'Заготовка' : 'Блок $i'),
                trailing: SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _diameterControllers[i],
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: i == 0 ? 'Диаметр' : 'Блок $i',
                    ),
                    onChanged: (value) => _calculateReductions(),
                  ),
                ),
              ),
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Обжатие: ${_reductions[i - 1].toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (i < 15) const Divider(),
            ],
          ],
        ),
      ),
    );
  }
}

class LinearRouteScreen extends StatefulWidget {
  const LinearRouteScreen({super.key});

  @override
  State<LinearRouteScreen> createState() => _LinearRouteScreenState();
}

class _LinearRouteScreenState extends State<LinearRouteScreen> {
  final TextEditingController _diameterRaw = TextEditingController();
  final TextEditingController _diameterFinal = TextEditingController();
  final TextEditingController _passes = TextEditingController();
  final TextEditingController _carbon = TextEditingController();

  double _totalReduction = 0;
  double _unitReduction = 0;
  double _vsrRaw1 = 0;
  double _vsrRaw2 = 0;
  double _vsrFinal1 = 0;
  double _vsrFinal2 = 0;
  List<Map<String, dynamic>> _routeSteps = [];

  double _parseInput(String value) {
    if (value.isEmpty) return 0;
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  void _calculate() {
    try {
      final double dRaw = _parseInput(_diameterRaw.text);
      final double dFinal = _parseInput(_diameterFinal.text);
      final int passes = int.tryParse(_passes.text) ?? 0;
      final double carbon = _parseInput(_carbon.text);

      if (dRaw == 0 || dFinal == 0 || passes == 0) {
        throw Exception('Неверные входные данные');
      }

      // Основные расчёты
      _totalReduction = (1 - pow(dFinal / dRaw, 2)) * 100;
      _unitReduction = (1 - pow(dFinal / dRaw, 1 / passes)) * 100;

      // ВСР заготовка (два значения)
      _vsrRaw1 = 100 * carbon + 53 - dRaw - 5;
      _vsrRaw2 = 100 * carbon + 53 - dRaw + 5;

      // ВСР готовый (два значения)
      final commonPart =
          0.6 * (carbon + dRaw / 40 + 0.01 * _unitReduction) * _totalReduction;

      // Первое значение ВСР готовый
      final denominator1 =
          log(sqrt(100 - _unitReduction)) / log(10) + 0.0005 * _unitReduction;
      _vsrFinal1 =
          _vsrRaw1 + (denominator1 != 0 ? commonPart / denominator1 : 0);

      // Второе значение ВСР готовый
      final denominator2 =
          log(sqrt(100 - _totalReduction)) / log(10) + 0.0005 * _totalReduction;
      _vsrFinal2 =
          _vsrRaw2 + (denominator2 != 0 ? commonPart / denominator2 : 0);

      // Расчёт маршрута с обжатиями между блоками
      _routeSteps = [];
      double currentDiameter = dRaw;
      double prevDiameter = dRaw;

      for (int i = 0; i <= passes; i++) {
        String reduction = '-';
        if (i > 0) {
          reduction =
              ((1 - pow(currentDiameter / prevDiameter, 2)) * 100)
                  .toStringAsFixed(2) +
              '%';
          prevDiameter = currentDiameter;
        }

        _routeSteps.add({
          'pass': i == 0 ? 'Заготовка' : 'Проход $i',
          'diameter': currentDiameter.toStringAsFixed(2),
          'reduction': reduction,
        });

        if (i < passes) {
          currentDiameter -= (dRaw - dFinal) / passes;
        }
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Линейный маршрут')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _diameterRaw,
                      decoration: const InputDecoration(
                        labelText: 'D Заготовки (мм)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _diameterFinal,
                      decoration: const InputDecoration(
                        labelText: 'D Чистовой (мм)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passes,
                decoration: const InputDecoration(
                  labelText: 'Число проходов',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _carbon,
                decoration: const InputDecoration(
                  labelText: 'Углерод (С)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _calculate,
                child: const Text('Рассчитать'),
              ),
              const SizedBox(height: 32),
              _buildResultRow(
                'Суммарное обжатие',
                '${_totalReduction.toStringAsFixed(2)} %',
              ),
              _buildResultRow(
                'Единичное обжатие',
                '${_unitReduction.toStringAsFixed(2)} %',
              ),
              _buildDoubleResultRow(
                'ВСР (Заготовка)',
                _vsrRaw1.toStringAsFixed(2),
                _vsrRaw2.toStringAsFixed(2),
              ),
              _buildDoubleResultRow(
                'ВСР (Готовый)',
                _vsrFinal1.toStringAsFixed(2),
                _vsrFinal2.toStringAsFixed(2),
              ),

              // Таблица маршрута
              const SizedBox(height: 24),
              const Text(
                'Маршрут волочения:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Table(
                border: TableBorder.all(color: Colors.grey),
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Colors.blueGrey),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Этап',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Диаметр (мм)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Обжатие (%)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  ..._routeSteps
                      .map(
                        (step) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(step['pass']),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(step['diameter']),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(step['reduction']),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubleResultRow(String title, String value1, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Row(
            children: [
              Text(
                value1,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(' - '),
              Text(
                value2,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
