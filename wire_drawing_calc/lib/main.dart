import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

void main() {
  runApp(const WireDrawingApp());
}

class VersionChecker {
  static const String minSupportedVersion = '1.0.2';
  static const String minSupportedBuildNumber = '3';
  static const String appStoreUrl =
      'https://apps.rustore.ru/app/com.example.wire_drawing_calc';

  static Future<bool> isUpdateRequired() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final currentBuildNumber = packageInfo.buildNumber;

    // Проверяем, является ли текущая версия 1.0.1+2
    final bool isOldVersion =
        currentVersion == '1.0.1' && currentBuildNumber == '2';

    // Или проверяем, что версия меньше минимальной поддерживаемой
    final bool isVersionLower =
        _compareVersions(currentVersion, minSupportedVersion) < 0 ||
        (currentVersion == minSupportedVersion &&
            _compareBuildNumbers(currentBuildNumber, minSupportedBuildNumber) <
                0);

    return isOldVersion || isVersionLower;
  }

  // Сравнение версий вида X.Y.Z
  static int _compareVersions(String v1, String v2) {
    final v1Parts = v1.split('.').map(int.parse).toList();
    final v2Parts = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }
    return 0;
  }

  // Сравнение build numbers
  static int _compareBuildNumbers(String b1, String b2) {
    return int.parse(b1).compareTo(int.parse(b2));
  }

  static Future<void> showUpdateDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Требуется обновление'),
          content: const Text(
            'Для продолжения работы приложения необходимо обновить его до последней версии.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Обновить'),
              onPressed: () async {
                if (await canLaunch(appStoreUrl)) {
                  await launch(appStoreUrl);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  bool _isChecking = true;
  bool _updateRequired = false;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      final isUpdateRequired = await VersionChecker.isUpdateRequired();

      if (mounted) {
        setState(() {
          _isChecking = false;
          _updateRequired = isUpdateRequired;
        });

        if (isUpdateRequired) {
          await VersionChecker.showUpdateDialog(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _updateRequired = true;
        });
        await VersionChecker.showUpdateDialog(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_updateRequired) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Требуется обновление приложения'),
              ElevatedButton(
                onPressed: () => VersionChecker.showUpdateDialog(context),
                child: const Text('Обновить'),
              ),
            ],
          ),
        ),
      );
    }

    return _isChecking
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : const HomeScreen();
  }
}

// Остальной код остается без изменений...
class WireDrawingApp extends StatelessWidget {
  const WireDrawingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Калькулятор волочения',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AppStartupScreen(),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ZincCalculationScreen(),
                    ),
                  ),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Расчёт цинка на заготовке'),
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
  void dispose() {
    for (var controller in _diameterControllers) {
      controller.dispose();
    }
    super.dispose();
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

  List<TextEditingController> _diameterControllers = [];
  List<double> _reductions = [];

  @override
  void dispose() {
    _diameterRaw.dispose();
    _diameterFinal.dispose();
    _passes.dispose();
    _carbon.dispose();
    for (var controller in _diameterControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  double _parseInput(String value) {
    if (value.isEmpty) return 0;
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  void _resetData() {
    _diameterRaw.clear();
    _diameterFinal.clear();
    _passes.clear();
    _carbon.clear();
    for (var controller in _diameterControllers) {
      controller.dispose();
    }
    _diameterControllers.clear();
    _reductions.clear();
    _totalReduction = 0;
    _unitReduction = 0;
    _vsrRaw1 = 0;
    _vsrRaw2 = 0;
    _vsrFinal1 = 0;
    _vsrFinal2 = 0;
    setState(() {});
  }

  void _calculateReductions() {
    for (int i = 1; i < _diameterControllers.length; i++) {
      final double prev = _parseInput(_diameterControllers[i - 1].text);
      final double next = _parseInput(_diameterControllers[i].text);

      if (prev == 0 || next == 0) {
        _reductions[i - 1] = 0;
        continue;
      }

      _reductions[i - 1] = (1 - pow(next / prev, 2)) * 100;
    }
    setState(() {});
  }

  void _calculate() {
    try {
      final double dRaw = _parseInput(_diameterRaw.text);
      final double dFinal = _parseInput(_diameterFinal.text);
      final int passes = int.tryParse(_passes.text) ?? 0;
      final double carbon = _parseInput(_carbon.text);

      if (dRaw <= 0 || dFinal <= 0 || passes <= 0) {
        throw Exception('Неверные входные данные');
      }
      if (dFinal >= dRaw) {
        throw Exception('Чистовой диаметр должен быть меньше заготовки');
      }

      _totalReduction = (1 - pow(dFinal / dRaw, 2)) * 100;
      _unitReduction =
          (1 - pow((100 - _totalReduction) / 100, 1 / passes)) * 100;
      _vsrRaw1 = 100 * carbon + 53 - dRaw - 5;
      _vsrRaw2 = 100 * carbon + 53 - dRaw + 5;

      final commonPart =
          0.6 * (carbon + dRaw / 40 + 0.01 * _unitReduction) * _totalReduction;
      final denominator =
          log(sqrt(100 - _totalReduction)) / log(10) + 0.0005 * _totalReduction;

      _vsrFinal1 = _vsrRaw1 + (denominator != 0 ? commonPart / denominator : 0);
      _vsrFinal2 = _vsrRaw2 + (denominator != 0 ? commonPart / denominator : 0);

      _diameterControllers = List.generate(
        passes + 1,
        (_) => TextEditingController(),
      );
      _reductions = List.filled(passes, 0);

      double currentDiameter = dRaw;
      for (int i = 0; i <= passes; i++) {
        _diameterControllers[i].text = currentDiameter.toStringAsFixed(2);
        if (i < passes) {
          currentDiameter *= sqrt(1 - _unitReduction / 100);
        }
      }
      _diameterControllers[passes].text = dFinal.toStringAsFixed(2);
      _calculateReductions();

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
    }
  }

  String _formatCarbonInput(String input) {
    if (input.startsWith('.') || input.startsWith(',')) {
      return '0${input.replaceFirst(',', '.')}';
    }
    return input.replaceAll(',', '.');
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
                onChanged: (value) {
                  if (value.startsWith('.') || value.startsWith(',')) {
                    _carbon.text = _formatCarbonInput(value);
                    _carbon.selection = TextSelection.fromPosition(
                      TextPosition(offset: _carbon.text.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _resetData,
                    child: const Text('Сброс'),
                  ),
                  ElevatedButton(
                    onPressed: _calculate,
                    child: const Text('Рассчитать'),
                  ),
                ],
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
              const SizedBox(height: 24),
              if (_diameterControllers.isNotEmpty) ...[
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
                    ..._diameterControllers.asMap().entries.map((entry) {
                      final i = entry.key;
                      final controller = entry.value;
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(i == 0 ? 'Заготовка' : 'Проход $i'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              controller: controller,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: i == 0 ? 'Диаметр' : 'Блок $i',
                              ),
                              onChanged: (value) => _calculateReductions(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              i == 0
                                  ? '-'
                                  : '${_reductions[i - 1].toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
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

class ZincCalculationScreen extends StatefulWidget {
  const ZincCalculationScreen({super.key});

  @override
  State<ZincCalculationScreen> createState() => _ZincCalculationScreenState();
}

class _ZincCalculationScreenState extends State<ZincCalculationScreen> {
  final TextEditingController _diameterRawController = TextEditingController();
  final TextEditingController _diameterFinalController =
      TextEditingController();
  String? _selectedGroup;
  double _result = 0;
  String _errorMessage = '';

  final List<Map<String, dynamic>> _zincTable = [
    {'range': 'D = 0,18', 'min': 0.18, 'max': 0.18, 'C': 10, 'Ж': 20, 'ОЖ': 30},
    {
      'range': '0,18 < D ≤ 0,24',
      'min': 0.18,
      'max': 0.24,
      'C': 15,
      'Ж': 20,
      'ОЖ': 30,
    },
    {
      'range': '0,24 < D ≤ 0,32',
      'min': 0.24,
      'max': 0.32,
      'C': 20,
      'Ж': 25,
      'ОЖ': 45,
    },
    {
      'range': '0,32 < D ≤ 0,38',
      'min': 0.32,
      'max': 0.38,
      'C': 20,
      'Ж': 25,
      'ОЖ': 60,
    },
    {
      'range': '0,38 < D ≤ 0,45',
      'min': 0.38,
      'max': 0.45,
      'C': 30,
      'Ж': 40,
      'ОЖ': 75,
    },
    {
      'range': '0,45 < D ≤ 0,55',
      'min': 0.45,
      'max': 0.55,
      'C': 35,
      'Ж': 40,
      'ОЖ': 90,
    },
    {
      'range': '0,55 < D ≤ 0,65',
      'min': 0.55,
      'max': 0.65,
      'C': 40,
      'Ж': 50,
      'ОЖ': 110,
    },
    {
      'range': '0,65 < D ≤ 0,75',
      'min': 0.65,
      'max': 0.75,
      'C': 40,
      'Ж': 60,
      'ОЖ': 120,
    },
    {
      'range': '0,75 < D ≤ 0,95',
      'min': 0.75,
      'max': 0.95,
      'C': 50,
      'Ж': 70,
      'ОЖ': 130,
    },
    {
      'range': '0,95 < D ≤ 1,15',
      'min': 0.95,
      'max': 1.15,
      'C': 60,
      'Ж': 80,
      'ОЖ': 150,
    },
    {
      'range': '1,15 < D ≤ 1,40',
      'min': 1.15,
      'max': 1.40,
      'C': 60,
      'Ж': 90,
      'ОЖ': 165,
    },
    {
      'range': '1,40 < D ≤ 1,80',
      'min': 1.40,
      'max': 1.80,
      'C': 70,
      'Ж': 100,
      'ОЖ': 180,
    },
    {
      'range': '1,80 < D ≤ 2,40',
      'min': 1.80,
      'max': 2.40,
      'C': 80,
      'Ж': 110,
      'ОЖ': 205,
    },
    {
      'range': '2,40 < D ≤ 3,00',
      'min': 2.40,
      'max': 3.00,
      'C': 90,
      'Ж': 125,
      'ОЖ': 230,
    },
    {
      'range': '3,00 < D ≤ 3,80',
      'min': 3.00,
      'max': 3.80,
      'C': 100,
      'Ж': 135,
      'ОЖ': 230,
    },
    {
      'range': '3,80 < D ≤ 4,40',
      'min': 3.80,
      'max': 4.40,
      'C': 110,
      'Ж': 150,
      'ОЖ': 245,
    },
    {
      'range': '4,40 < D ≤ 5,10',
      'min': 4.40,
      'max': 5.10,
      'C': 110,
      'Ж': 165,
      'ОЖ': 245,
    },
  ];

  @override
  void dispose() {
    _diameterRawController.dispose();
    _diameterFinalController.dispose();
    super.dispose();
  }

  double _parseInput(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  double? _getZincValueForDiameter(double diameter, String group) {
    for (var row in _zincTable) {
      final range = row['range'] as String;
      final min = row['min'] as double;
      final max = row['max'] as double;

      if (diameter >= min && diameter <= max) {
        return row[group]?.toDouble();
      }
    }
    return null;
  }

  void _calculate() {
    setState(() {
      _errorMessage = '';
      _result = 0;
    });

    if (_diameterRawController.text.isEmpty ||
        _diameterFinalController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Введите диаметры заготовки и готовой проволоки';
      });
      return;
    }

    if (_selectedGroup == null) {
      setState(() {
        _errorMessage = 'Выберите группу цинка (С, Ж или ОЖ)';
      });
      return;
    }

    final double dRaw = _parseInput(_diameterRawController.text);
    final double dFinal = _parseInput(_diameterFinalController.text);

    if (dFinal >= dRaw) {
      setState(() {
        _errorMessage =
            'Диаметр готовой проволоки должен быть меньше диаметра заготовки';
      });
      return;
    }

    final double? pFinal = _getZincValueForDiameter(dFinal, _selectedGroup!);

    if (pFinal == null) {
      setState(() {
        _errorMessage = 'Данной группы на заданном диаметре нет';
      });
      return;
    }

    final double k = _selectedGroup == 'ОЖ' ? 1.2 : 1.1;
    setState(() {
      _result = (dRaw / dFinal) * pFinal * k;
    });
  }

  void _reset() {
    setState(() {
      _diameterRawController.clear();
      _diameterFinalController.clear();
      _selectedGroup = null;
      _result = 0;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Расчёт цинка на заготовке')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _diameterRawController,
                      decoration: const InputDecoration(
                        labelText: 'Диаметр заготовки (мм)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _diameterFinalController,
                      decoration: const InputDecoration(
                        labelText: 'Диаметр готовой проволоки (мм)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Группа цинка:', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => setState(() => _selectedGroup = 'C'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _selectedGroup == 'C' ? Colors.blue : null,
                            foregroundColor:
                                _selectedGroup == 'C' ? Colors.white : null,
                          ),
                          child: const Text('С'),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() => _selectedGroup = 'Ж'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _selectedGroup == 'Ж' ? Colors.blue : null,
                            foregroundColor:
                                _selectedGroup == 'Ж' ? Colors.white : null,
                          ),
                          child: const Text('Ж'),
                        ),
                        ElevatedButton(
                          onPressed:
                              () => setState(() => _selectedGroup = 'ОЖ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _selectedGroup == 'ОЖ' ? Colors.blue : null,
                            foregroundColor:
                                _selectedGroup == 'ОЖ' ? Colors.white : null,
                          ),
                          child: const Text('ОЖ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _reset,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 50),
                          ),
                          child: const Text('Сброс'),
                        ),
                        ElevatedButton(
                          onPressed: _calculate,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 50),
                          ),
                          child: const Text('Рассчитать'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_result > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Количество цинка на заготовке должно быть не менее ${_result.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey[200],
            child: const Text(
              'Поверхностная плотность цинка соответствовует нормам, указанным в табл. 7 ГОСТ 7372-79.\n'
              'К - поправочный коэффициент, который принимает значения 1,1 для групп "С" и "Ж", а для группы "ОЖ" - 1,2-1,3',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
