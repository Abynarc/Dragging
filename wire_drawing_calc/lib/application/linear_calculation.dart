import 'dart:collection';

import '../domain/calculations.dart';

/// Calculation state has no Flutter controllers, focus nodes, colors or widgets.
/// A manual row edit changes row reductions only; submit regenerates the route.
class LinearCalculation {
  LinearResult? _result;
  List<String> _diameters = [];
  List<double> _reductions = [];

  LinearResult? get result => _result;
  List<String> get diameters => UnmodifiableListView(_diameters);
  List<double> get reductions => UnmodifiableListView(_reductions);

  void calculate({
    required String rawDiameter,
    required String finalDiameter,
    required String passesText,
    required String carbonText,
  }) {
    // Validate/compute before replacing state: an error retains previous results.
    final next = calculateLinearRoute(
      rawDiameter: rawDiameter,
      finalDiameter: finalDiameter,
      passesText: passesText,
      carbonText: carbonText,
    );
    _result = next;
    _diameters = List.of(next.diameters);
    _reductions = List.of(next.reductions);
  }

  void editDiameter(int index, String value) {
    _diameters[index] = value;
    _reductions = routeReductions(_diameters);
  }

  void reset() {
    _result = null;
    _diameters = [];
    _reductions = [];
  }
}
