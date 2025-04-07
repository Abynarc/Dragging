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
    12,
    (_) => TextEditingController(),
  );
  final List<double> _reductions = List.filled(12, 0);

  double _parseInput(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  void _calculateReductions() {
    try {
      for (int i = 0; i < 12; i++) {
        if (i == 0) continue; // Пропускаем заготовку

        final double prev = _parseInput(_diameterControllers[i - 1].text);
        final double next = _parseInput(_diameterControllers[i].text);

        if (prev == 0 || next == 0) {
          _reductions[i] = 0;
          continue;
        }

        _reductions[i] = (1 - pow(next / prev, 2)) * 100;
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
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Этап')),
            DataColumn(label: Text('Диаметр (мм)')),
            DataColumn(label: Text('Обжатие (%)')),
          ],
          rows: [
            for (int i = 0; i < 12; i++)
              DataRow(
                cells: [
                  DataCell(Text(i == 0 ? 'Заготовка' : 'Блок $i')),
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _diameterControllers[i],
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          hintText: i == 0 ? 'Диаметр' : 'Блок $i',
                        ),
                        onChanged: (value) => _calculateReductions(),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(i > 0 ? _reductions[i].toStringAsFixed(2) : ''),
                  ),
                ],
              ),
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
  double _vsrRaw = 0;
  double _vsrFinal = 0;
  List<Map<String, dynamic>> _routeSteps = [];

  double _parseInput(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  void _calculate() {
    try {
      final double dRaw = _parseInput(_diameterRaw.text);
      final double dFinal = _parseInput(_diameterFinal.text);
      final int passes = int.tryParse(_passes.text) ?? 0;
      final double carbon = _parseInput(_carbon.text);

      // Основные расчёты
      _totalReduction = (pow(dRaw, 2) - pow(dFinal, 2)) / pow(dRaw, 2) * 100;
      _unitReduction =
          (1 - pow((100 - _totalReduction) / 100, 1 / passes)) * 100;
      _vsrRaw = 100 * dFinal + 53 - dRaw - 5;
      _vsrFinal =
          _vsrRaw +
          (0.6 * (dFinal + dRaw / 40 + 0.01 * _totalReduction) * carbon) /
              (log(sqrt(100 - _totalReduction)) / log(10) +
                  0.0005 * _totalReduction);

      // Расчёт маршрута (таблица 2)
      _routeSteps = [];
      double currentDiameter = dRaw;
      for (int i = 0; i <= passes; i++) {
        _routeSteps.add({
          'pass': i == 0 ? 'Заготовка' : 'Проход $i',
          'diameter': currentDiameter.toStringAsFixed(2),
          'reduction':
              i == 0
                  ? '-'
                  : ((currentDiameter - _routeSteps[i - 1]['diameter']) * -1)
                      .toStringAsFixed(2),
        });

        if (i < passes) {
          currentDiameter -= (dRaw - dFinal) / passes;
        }
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка в данных! Проверьте ввод')),
      );
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
                        labelText: 'D Заготовки',
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
                        labelText: 'D Чистовой',
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
              _buildResultRow('ВСР (Заготовка)', _vsrRaw.toStringAsFixed(2)),
              _buildResultRow('ВСР (Готовый)', _vsrFinal.toStringAsFixed(2)),

              // Таблица маршрута
              const SizedBox(height: 24),
              const Text(
                'Маршрут волочения:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DataTable(
                columns: const [
                  DataColumn(label: Text('Этап')),
                  DataColumn(label: Text('Диаметр (мм)')),
                  DataColumn(label: Text('Δ (мм)')),
                ],
                rows:
                    _routeSteps
                        .map(
                          (step) => DataRow(
                            cells: [
                              DataCell(Text(step['pass'])),
                              DataCell(Text(step['diameter'])),
                              DataCell(Text(step['reduction'])),
                            ],
                          ),
                        )
                        .toList(),
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
}
