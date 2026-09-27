import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wire_drawing_calc/main.dart';

void main() {
  testWidgets('Home exposes all four working sections', (tester) async {
    await tester.pumpWidget(const WireDrawingApp());
    expect(find.text('Расчёт маршрута'), findsOneWidget);
    expect(find.text('Расчёт линейного маршрута'), findsOneWidget);
    expect(find.text('Расчёт цинка на заготовке'), findsOneWidget);
    expect(find.text('Справка и формулы'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(4));
  });
}
