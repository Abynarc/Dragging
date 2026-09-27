import 'dart:math' as math;

// Compatibility contract: preserve operation order, inclusive table boundaries,
// permissive parsing and rounding BEFORE calculating reductions of route rows.
double parseDiameter(String value) =>
    double.tryParse(value.replaceAll(',', '.')) ?? 0;

class CalculationException implements Exception {
  const CalculationException(this.message);
  final String message;
  @override
  String toString() => message;
}

double reduction(double previous, double next) {
  if (previous == 0 || next == 0) return 0;
  return (1 - math.pow(next / previous, 2)) * 100;
}

List<double> routeReductions(List<String> diameters) => [
  for (var i = 1; i < diameters.length; i++)
    reduction(parseDiameter(diameters[i - 1]), parseDiameter(diameters[i])),
];

class LinearResult {
  LinearResult({
    required this.totalReduction,
    required this.unitReduction,
    required this.vsrRaw1,
    required this.vsrRaw2,
    required this.vsrFinal1,
    required this.vsrFinal2,
    required List<String> diameters,
    required List<double> reductions,
  }) : diameters = List.unmodifiable(diameters),
       reductions = List.unmodifiable(reductions);
  final double totalReduction,
      unitReduction,
      vsrRaw1,
      vsrRaw2,
      vsrFinal1,
      vsrFinal2;
  final List<String> diameters;
  final List<double> reductions;
  List<double> get numbers => [
    totalReduction,
    unitReduction,
    vsrRaw1,
    vsrRaw2,
    vsrFinal1,
    vsrFinal2,
  ];
}

// The original explicitly guards only exact zero, not NaN or infinity.
double guardedVsrCorrection(double numerator, double denominator) =>
    denominator != 0 ? numerator / denominator : 0;

LinearResult calculateLinearRoute({
  required String rawDiameter,
  required String finalDiameter,
  required String passesText,
  required String carbonText,
}) {
  final double dRaw = parseDiameter(rawDiameter);
  final double dFinal = parseDiameter(finalDiameter);
  final int passes = int.tryParse(passesText) ?? 0;
  final double carbon = parseDiameter(carbonText);
  if (dRaw <= 0 || dFinal <= 0 || passes <= 0) {
    throw const CalculationException('Неверные входные данные');
  }
  if (dFinal >= dRaw) {
    throw const CalculationException(
      'Чистовой диаметр должен быть меньше заготовки',
    );
  }
  final double totalReduction = (1 - math.pow(dFinal / dRaw, 2)) * 100;
  final double unitReduction =
      (1 - math.pow((100 - totalReduction) / 100, 1 / passes)) * 100;
  final vsrRaw1 = 100 * carbon + 53 - dRaw - 5;
  final vsrRaw2 = 100 * carbon + 53 - dRaw + 5;
  final commonPart =
      0.6 * (carbon + dRaw / 40 + 0.01 * unitReduction) * totalReduction;
  final denominator =
      math.log(math.sqrt(100 - totalReduction)) / math.log(10) +
      0.0005 * totalReduction;
  final vsrFinal1 = vsrRaw1 + guardedVsrCorrection(commonPart, denominator);
  final vsrFinal2 = vsrRaw2 + guardedVsrCorrection(commonPart, denominator);
  final diameters = <String>[];
  double currentDiameter = dRaw;
  for (int i = 0; i <= passes; i++) {
    diameters.add(currentDiameter.toStringAsFixed(2));
    if (i < passes) currentDiameter *= math.sqrt(1 - unitReduction / 100);
  }
  diameters[passes] = dFinal.toStringAsFixed(2);
  return LinearResult(
    totalReduction: totalReduction,
    unitReduction: unitReduction,
    vsrRaw1: vsrRaw1,
    vsrRaw2: vsrRaw2,
    vsrFinal1: vsrFinal1,
    vsrFinal2: vsrFinal2,
    diameters: diameters,
    reductions: routeReductions(diameters),
  );
}

// This is the executable historical table, NOT the different reference-page table.
const List<Map<String, dynamic>> zincCalculationTable = [
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

double? zincValueForDiameter(double diameter, String group) {
  for (final row in zincCalculationTable) {
    final min = row['min'] as double;
    final max = row['max'] as double;
    if (diameter >= min && diameter <= max) {
      return row[group]?.toDouble();
    }
  }
  return null;
}

class ZincResult {
  const ZincResult({this.value = 0, this.error = ''});
  final double value;
  final String error;
}

ZincResult calculateZinc({
  required String rawDiameter,
  required String finalDiameter,
  required String? group,
}) {
  if (rawDiameter.isEmpty || finalDiameter.isEmpty) {
    return const ZincResult(
      error: 'Введите диаметры заготовки и готовой проволоки',
    );
  }
  if (group == null) {
    return const ZincResult(error: 'Выберите группу цинка (С, Ж или ОЖ)');
  }
  final double dRaw = parseDiameter(rawDiameter);
  final double dFinal = parseDiameter(finalDiameter);
  if (dFinal >= dRaw) {
    return const ZincResult(
      error: 'Диаметр готовой проволоки должен быть меньше диаметра заготовки',
    );
  }
  final double? pFinal = zincValueForDiameter(dFinal, group);
  if (pFinal == null) {
    return const ZincResult(error: 'Данной группы на заданном диаметре нет');
  }
  final double k = group == 'ОЖ' ? 1.2 : 1.1;
  return ZincResult(value: (dRaw / dFinal) * pFinal * k);
}
