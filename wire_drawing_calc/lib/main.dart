import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const WireDrawingApp());

class WireDrawingApp extends StatelessWidget {
  const WireDrawingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Калькулятор волочения',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReductionCalculator()),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Расчёт обжатия'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LinearRouteScreen()),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              child: const Text('Линейный маршрут'),
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

class ReductionCalculator extends StatefulWidget {
  const ReductionCalculator({super.key});

  @override
  State<ReductionCalculator> createState() => _ReductionCalculatorState();
}

class _ReductionCalculatorState extends State<ReductionCalculator> {
  final TextEditingController _diameterRaw = TextEditingController();
  final TextEditingController _diameterFinal = TextEditingController();
  final TextEditingController _passes = TextEditingController();

  String _totalReduction = '-';
  String _unitReduction = '-';
  String _vsrRaw = '-';
  String _vsrFinal = '-';

  void _calculate() {
    try {
      final dRaw = double.parse(_diameterRaw.text);
      final dFinal = double.parse(_diameterFinal.text);
      final passes = int.parse(_passes.text);

      final total = (pow(dRaw, 2) - pow(dFinal, 2)) / pow(dRaw, 2) * 100;
      final unit = (1 - pow((100 - total) / 100, 1 / passes)) * 100;
      final vsrRaw = 100 * dFinal + 53 - dRaw - 5;
      final vsrFinal = dRaw + (0.6 * (dFinal + dRaw / 40 + 0.01 * total) * total) / 
                      (log(sqrt(100 - total)) / log(10) + 0.0005 * total);

      setState(() {
        _totalReduction = total.toStringAsFixed(2);
        _unitReduction = unit.toStringAsFixed(2);
        _vsrRaw = vsrRaw.toStringAsFixed(2);
        _vsrFinal = vsrFinal.toStringAsFixed(2);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка в данных!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Расчёт обжатия')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _diameterRaw,
              decoration: const InputDecoration(
                labelText: 'Диаметр заготовки (мм)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _diameterFinal,
              decoration: const InputDecoration(
                labelText: 'Диаметр после волочения (мм)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('Рассчитать'),
            ),
            const SizedBox(height: 32),
            _buildResultCard('Суммарное обжатие', '$_totalReduction %'),
            _buildResultCard('Единичное обжатие', '$_unitReduction %'),
            _buildResultCard('ВСР заготовки', _vsrRaw),
            _buildResultCard('ВСР готового продукта', _vsrFinal),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  List<Map<String, dynamic>> _steps = [];

  void _calculateRoute() {
    try {
      final dRaw = double.parse(_diameterRaw.text);
      final dFinal = double.parse(_diameterFinal.text);
      final passes = int.parse(_passes.text);

      final steps = <Map<String, dynamic>>[];
      double current = dRaw;
      final reduction = (dRaw - dFinal) / passes;

      for (var i = 0; i <= passes; i++) {
        steps.add({
          'pass': i + 1,
          'diameter': current.toStringAsFixed(2),
          'reduction': (i == 0 ? '-' : reduction.toStringAsFixed(2)),
        });
        if (i != passes) current -= reduction;
      }

      setState(() => _steps = steps);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Проверьте введённые данные!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Линейный маршрут')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _diameterRaw,
                    decoration: const InputDecoration(
                      labelText: 'Начальный диаметр (мм)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _diameterFinal,
                    decoration: const InputDecoration(
                      labelText: 'Конечный диаметр (мм)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
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
            ElevatedButton(
              onPressed: _calculateRoute,
              child: const Text('Рассчитать маршрут'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Card(
                    child: ListTile(
                      title: Text('Проход ${step['pass']}'),
                      subtitle: Text('Диаметр: ${step['diameter']} мм'),
                      trailing: Text(
                        index == 0 ? 'Исходный' : 'Δ ${step['reduction']} мм',
                        style: TextStyle(
                          color: index == 0 ? Colors.grey : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}