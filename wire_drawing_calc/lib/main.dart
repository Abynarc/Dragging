import 'package:flutter/material.dart';
import 'domain/calculations.dart';
import 'application/linear_calculation.dart';
import 'presentation/precision_theme.dart';
import 'presentation/precision_components.dart';

void main() => runApp(const WireDrawingApp());

class WireDrawingApp extends StatefulWidget {
  const WireDrawingApp({super.key});
  @override
  State<WireDrawingApp> createState() => _WireDrawingAppState();
}

class _WireDrawingAppState extends State<WireDrawingApp> {
  late bool _darkMode;
  bool _blur = false;
  @override
  void initState() {
    super.initState();
    _darkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  void _toggleDarkMode() => setState(() => _darkMode = !_darkMode);
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Калькулятор волочения',
    debugShowCheckedModeBanner: false,
    theme: precisionTheme(Brightness.light),
    darkTheme: precisionTheme(Brightness.dark),
    themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
    themeAnimationDuration: Duration.zero,
    builder:
        (context, child) => _Appearance(
          blur: _blur,
          toggleTheme: _toggleDarkMode,
          toggleBlur: () => setState(() => _blur = !_blur),
          child: child!,
        ),
    home: HomeScreen(darkMode: _darkMode, toggleDarkMode: _toggleDarkMode),
  );
}

class _Appearance extends InheritedWidget {
  const _Appearance({
    required this.blur,
    required this.toggleTheme,
    required this.toggleBlur,
    required super.child,
  });
  final bool blur;
  final VoidCallback toggleTheme, toggleBlur;
  static _Appearance? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Appearance>();
  @override
  bool updateShouldNotify(_Appearance oldWidget) => true;
}

class _Screen extends StatelessWidget {
  const _Screen({
    required this.title,
    required this.body,
    this.home = false,
    this.toggleTheme,
  });
  final String title;
  final Widget body;
  final bool home;
  final VoidCallback? toggleTheme;
  @override
  Widget build(BuildContext context) {
    final appearance = _Appearance.of(context);
    return PrecisionScaffold(
      title: title,
      body: body,
      blur: appearance?.blur ?? false,
      onToggleTheme: appearance?.toggleTheme ?? toggleTheme ?? () {},
      onToggleTransparency: appearance?.toggleBlur,
      onBack: home ? null : () => Navigator.maybePop(context),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.children, this.controller, this.storageKey});
  final List<Widget> children;
  final ScrollController? controller;
  final String? storageKey;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: storageKey == null ? null : PageStorageKey(storageKey),
    controller: controller,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class _Fields extends StatelessWidget {
  const _Fields({
    required this.children,
    this.crossAxisAlignment = WrapCrossAlignment.start,
  });
  final List<Widget> children;
  final WrapCrossAlignment crossAxisAlignment;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final columns = constraints.maxWidth >= 240 * scale ? 2 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 18,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

const _gap = SizedBox(height: 18);

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.darkMode,
    required this.toggleDarkMode,
  });
  final bool darkMode;
  final VoidCallback toggleDarkMode;
  @override
  Widget build(BuildContext context) => _Screen(
    title: 'Калькулятор волочения',
    home: true,
    toggleTheme: toggleDarkMode,
    body: _Content(
      children: [
        ExcludeSemantics(
          child: SizedBox(
            height: 84,
            child: CustomPaint(
              painter: _WireArt(PrecisionPalette.of(context).accent),
            ),
          ),
        ),
        const Text(
          'Выберите режим расчёта',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
        ),
        _gap,
        _menu(context, 'Расчёт маршрута', '01', const RouteCalculationScreen()),
        _gap,
        _menu(
          context,
          'Расчёт линейного маршрута',
          '02',
          const LinearRouteScreen(),
        ),
        _gap,
        _menu(
          context,
          'Расчёт цинка на заготовке',
          '03',
          const ZincCalculationScreen(),
        ),
        _gap,
        _menu(context, 'Справка и формулы', '04', const ReferenceScreen()),
        const SizedBox(height: 28),
        Text(
          'by DK and IB',
          textAlign: TextAlign.center,
          style: TextStyle(color: PrecisionPalette.of(context).muted),
        ),
      ],
    ),
  );
  Widget _menu(
    BuildContext context,
    String title,
    String number,
    Widget screen,
  ) {
    final p = PrecisionPalette.of(context);
    return ElevatedButton(
      onPressed:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          ),
      style: ElevatedButton.styleFrom(
        backgroundColor: p.surface,
        foregroundColor: p.ink,
        elevation: 0,
        minimumSize: const Size(48, 80),
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: p.line),
        ),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Text(number, style: TextStyle(color: p.accent)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: p.accent),
        ],
      ),
    );
  }
}

class _WireArt extends CustomPainter {
  _WireArt(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    canvas.translate(size.width / 2, 30);
    canvas.rotate(-.25);
    for (var i = 0; i < 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, i * 7), width: 190, height: 42),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WireArt oldDelegate) => color != oldDelegate.color;
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

  void _calculateReductions() {
    try {
      final reductions = routeReductions(
        _diameterControllers.map((controller) => controller.text).toList(),
      );
      for (var i = 0; i < reductions.length; i++) {
        _reductions[i] = reductions[i];
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
  Widget build(BuildContext context) => _Screen(
    title: 'Расчёт маршрута',
    body: _Content(
      storageKey: 'route',
      children: [
        for (var i = 0; i < _diameterControllers.length; i++) ...[
          PrecisionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrecisionNumberField(
                  controller: _diameterControllers[i],
                  label: i == 0 ? 'Заготовка' : 'Блок $i',
                  unit: 'мм',
                  onChanged: (_) => _calculateReductions(),
                ),
                if (i > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Обжатие: ${_reductions[i - 1].toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: PrecisionPalette.of(context).accent,
                      fontSize: 18,
                      fontFeatures: PrecisionTokens.numbers,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _gap,
        ],
      ],
    ),
  );
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

  final LinearCalculation _calculation = LinearCalculation();
  String? _error;
  double get _totalReduction => _calculation.result?.totalReduction ?? 0;
  double get _unitReduction => _calculation.result?.unitReduction ?? 0;
  double get _vsrRaw1 => _calculation.result?.vsrRaw1 ?? 0;
  double get _vsrRaw2 => _calculation.result?.vsrRaw2 ?? 0;
  double get _vsrFinal1 => _calculation.result?.vsrFinal1 ?? 0;
  double get _vsrFinal2 => _calculation.result?.vsrFinal2 ?? 0;
  List<double> get _reductions => _calculation.reductions;
  List<TextEditingController> _diameterControllers = [];
  List<ValueNotifier<double>> _reductionSignals = [];

  final FocusNode _diameterRawFocus = FocusNode();
  final FocusNode _diameterFinalFocus = FocusNode();
  final FocusNode _passesFocus = FocusNode();
  final FocusNode _carbonFocus = FocusNode();
  List<FocusNode> _diameterFocusNodes = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _carbonFocus.addListener(_handleCarbonFocus);
  }

  void _handleCarbonFocus() {
    if (_carbonFocus.hasFocus && _carbon.text.isEmpty) {
      _carbon.text = '0,';
      _carbon.selection = TextSelection.fromPosition(
        TextPosition(offset: _carbon.text.length),
      );
    } else if (!_carbonFocus.hasFocus && _carbon.text == '0,') {
      _carbon.clear();
    }
  }

  @override
  void dispose() {
    _diameterRaw.dispose();
    _diameterFinal.dispose();
    _passes.dispose();
    _carbon.dispose();
    for (var controller in _diameterControllers) {
      controller.dispose();
    }
    _diameterRawFocus.dispose();
    _diameterFinalFocus.dispose();
    _passesFocus.dispose();
    _carbonFocus.removeListener(_handleCarbonFocus);
    _carbonFocus.dispose();
    for (var focusNode in _diameterFocusNodes) {
      focusNode.dispose();
    }
    for (final signal in _reductionSignals) {
      signal.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _retireRouteFields() {
    final controllers = _diameterControllers;
    final nodes = _diameterFocusNodes;
    final signals = _reductionSignals;
    _diameterControllers = [];
    _diameterFocusNodes = [];
    _reductionSignals = [];
    // Old EditableText widgets must detach before their resources are disposed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in controllers) {
        controller.dispose();
      }
      for (final node in nodes) {
        node.dispose();
      }
      for (final signal in signals) {
        signal.dispose();
      }
    });
  }

  void _resetData() {
    FocusScope.of(context).unfocus();
    _diameterRaw.clear();
    _diameterFinal.clear();
    _passes.clear();
    _carbon.clear();
    _error = null;
    _calculation.reset();
    _retireRouteFields();
    setState(() {});
  }

  void _editDiameter(int index, String value) {
    _calculation.editDiameter(index, value);
    // Preserve the exact calculation path. Only the two neighboring displayed
    // reductions depend on this diameter; the form and other rows stay mounted.
    for (final reductionIndex in [index - 1, index]) {
      if (reductionIndex >= 0 && reductionIndex < _reductionSignals.length) {
        _reductionSignals[reductionIndex].value = _reductions[reductionIndex];
      }
    }
  }

  void _calculate() {
    try {
      FocusScope.of(context).unfocus();
      _calculation.calculate(
        rawDiameter: _diameterRaw.text,
        finalDiameter: _diameterFinal.text,
        passesText: _passes.text,
        carbonText: _carbon.text,
      );
      _error = null;
      _retireRouteFields();
      _diameterControllers =
          _calculation.diameters
              .map((value) => TextEditingController(text: value))
              .toList();
      _diameterFocusNodes = List.generate(
        _diameterControllers.length,
        (_) => FocusNode(),
      );
      _reductionSignals = _reductions.map(ValueNotifier<double>.new).toList();
      setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  String _formatCarbonInput(String input) {
    if (input.startsWith('.') || input.startsWith(',')) {
      return '0${input.replaceFirst(',', '.')}';
    }
    return input.replaceAll(',', '.');
  }

  @override
  Widget build(BuildContext context) => _Screen(
    title: 'Линейный маршрут',
    body: _Content(
      controller: _scrollController,
      children: [
        PrecisionPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Fields(
                children: [
                  PrecisionNumberField(
                    controller: _diameterRaw,
                    focusNode: _diameterRawFocus,
                    label: 'D Заг. (мм)',
                    unit: 'мм',
                  ),
                  PrecisionNumberField(
                    controller: _diameterFinal,
                    focusNode: _diameterFinalFocus,
                    label: 'D Чист. (мм)',
                    unit: 'мм',
                  ),
                  PrecisionNumberField(
                    controller: _passes,
                    focusNode: _passesFocus,
                    label: 'Число проходов',
                    integer: true,
                  ),
                  PrecisionNumberField(
                    controller: _carbon,
                    focusNode: _carbonFocus,
                    label: 'Углерод (С)',
                    unit: '%',
                    onChanged: (value) {
                      if (value.startsWith('.') || value.startsWith(',')) {
                        _carbon.text = _formatCarbonInput(value);
                        _carbon.selection = TextSelection.collapsed(
                          offset: _carbon.text.length,
                        );
                      }
                    },
                  ),
                ],
              ),
              _gap,
              PrecisionActions(onCalculate: _calculate, onReset: _resetData),
              if (_error != null) ...[_gap, PrecisionError(message: _error!)],
            ],
          ),
        ),
        _gap,
        PrecisionPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrecisionResultRow(
                label: 'Суммарное обжатие',
                value: '${_totalReduction.toStringAsFixed(2)} %',
              ),
              _gap,
              PrecisionResultRow(
                label: 'Единичное обжатие',
                value: '${_unitReduction.toStringAsFixed(2)} %',
              ),
              _gap,
              _range('ВСР заготовки', _vsrRaw1, _vsrRaw2),
              _gap,
              _range('ВСР готовой проволоки', _vsrFinal1, _vsrFinal2),
            ],
          ),
        ),
        _gap,
        for (var i = 0; i < _diameterControllers.length; i++) ...[
          PrecisionPanel(
            child: _Fields(
              children: [
                PrecisionNumberField(
                  controller: _diameterControllers[i],
                  focusNode: _diameterFocusNodes[i],
                  label: i == 0 ? 'Заготовка' : 'Проход $i',
                  unit: 'мм',
                  onChanged: (value) => _editDiameter(i, value),
                ),
                if (i == 0)
                  const PrecisionResultRow(label: 'Обжатие', value: '—')
                else
                  ValueListenableBuilder<double>(
                    valueListenable: _reductionSignals[i - 1],
                    builder:
                        (context, value, child) => PrecisionResultRow(
                          label: 'Обжатие',
                          value: '${value.toStringAsFixed(2)}%',
                        ),
                  ),
              ],
            ),
          ),
          _gap,
        ],
      ],
    ),
  );
  Widget _range(String label, double low, double high) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          Text(
            low.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 18,
              fontFeatures: PrecisionTokens.numbers,
            ),
          ),
          const Text('—'),
          Text(
            high.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 18,
              fontFeatures: PrecisionTokens.numbers,
            ),
          ),
        ],
      ),
    ],
  );
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
  final FocusNode _rawFocusNode = FocusNode();
  final FocusNode _finalFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _rawFocusNode.addListener(() => setState(() {}));
    _finalFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _diameterRawController.dispose();
    _diameterFinalController.dispose();
    _rawFocusNode.dispose();
    _finalFocusNode.dispose();
    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final result = calculateZinc(
      rawDiameter: _diameterRawController.text,
      finalDiameter: _diameterFinalController.text,
      group: _selectedGroup,
    );
    setState(() {
      _result = result.value;
      _errorMessage = result.error;
    });
  }

  void _reset() {
    FocusScope.of(context).unfocus();

    setState(() {
      _diameterRawController.clear();
      _diameterFinalController.clear();
      _selectedGroup = null;
      _result = 0;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) => _Screen(
    title: 'Цинк на заготовке',
    body: _Content(
      storageKey: 'zinc',
      children: [
        PrecisionPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Fields(
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  PrecisionNumberField(
                    controller: _diameterRawController,
                    focusNode: _rawFocusNode,
                    label: 'Диаметр заготовки',
                    unit: 'мм',
                  ),
                  PrecisionNumberField(
                    controller: _diameterFinalController,
                    focusNode: _finalFocusNode,
                    label: 'Диаметр готовой проволоки',
                    unit: 'мм',
                  ),
                ],
              ),
              _gap,
              const Text('Группа цинка'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final group in ['C', 'Ж', 'ОЖ'])
                    PrecisionControlSemantics(
                      selected: _selectedGroup == group,
                      label: 'Группа цинка ${group == 'C' ? 'С' : group}',
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              _selectedGroup == group
                                  ? PrecisionPalette.of(context).accent
                                  : PrecisionPalette.of(context).surface,
                          foregroundColor:
                              _selectedGroup == group
                                  ? PrecisionPalette.of(context).onAccent
                                  : PrecisionPalette.of(context).ink,
                        ),
                        onPressed: () => setState(() => _selectedGroup = group),
                        child: Text(group == 'C' ? 'С' : group),
                      ),
                    ),
                ],
              ),
              _gap,
              PrecisionActions(onCalculate: _calculate, onReset: _reset),
            ],
          ),
        ),
        _gap,
        if (_errorMessage.isNotEmpty) PrecisionError(message: _errorMessage),
        if (_result > 0)
          PrecisionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Количество цинка на заготовке должно быть не менее ${_result.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    color: PrecisionPalette.of(context).accent,
                    fontFeatures: PrecisionTokens.numbers,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('г/м²'),
              ],
            ),
          ),
        _gap,
        Text(
          'Поверхностная плотность цинка соответствует нормам, указанным в табл. 7 ГОСТ 7372-79.\n'
          'К - поправочный коэффициент, который принимает значения 1,1 для групп "С" и "Ж", а для группы "ОЖ" - 1,2-1,3',
          style: TextStyle(color: PrecisionPalette.of(context).muted),
        ),
      ],
    ),
  );
}

class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: _Screen(
      title: 'Справка и формулы',
      body: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            tabs: [
              Tab(
                height: MediaQuery.textScalerOf(context).scale(20) * 2 + 24,
                child: const Text(
                  'Формулы\nи источники',
                  textAlign: TextAlign.center,
                ),
              ),
              Tab(
                height: MediaQuery.textScalerOf(context).scale(20) * 2 + 24,
                child: const Text(
                  'Таблица\nплотности цинка',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [FormulasAndSourcesTab(), ZincDensityTableTab()],
            ),
          ),
        ],
      ),
    ),
  );
}

class FormulasAndSourcesTab extends StatelessWidget {
  const FormulasAndSourcesTab({super.key});
  @override
  Widget build(BuildContext context) => _Content(
    storageKey: 'formulas',
    children: [
      _buildFormulaCard(
        context,
        title: '1. Обжатие (уменьшение площади сечения)',
        formula: 'Обжатие (%) = [1 - (Dпосле/Dдо)^2] × 100',
        source: 'Грудев А.П. "Теория волочения проволоки", 1989',
      ),
      const SizedBox(height: 16),
      _buildFormulaCard(
        context,
        title: '2. Расчет диаметра после обжатия',
        formula: 'Dпосле = √(Dцель^2/(1 - Обжатие(%)/100))',
        source: 'Третьяков А.В. "Механические свойства металлов", 1960',
      ),
      const SizedBox(height: 16),
      _buildFormulaCard(
        context,
        title: '3. Суммарное обжатие',
        formula:
            'Суммарное обжатие (%) = (Dзаготовка^2 - Dчистовой^2)/Dзаготовка^2 × 100',
        source: 'Смирнов-Аляев Г.А. "Сопротивление материалов", 1968',
      ),
      const SizedBox(height: 16),
      _buildFormulaCard(
        context,
        title: '4. Единичное обжатие',
        formula:
            'Единичное обжатие (%) = [1 - ((100 - Сум.Обжат.)/100)^(1/N)] × 100\nгде N - число проходов',
        source: 'Зиновьев В.А. "Технология волочения металлов", 1974',
      ),
      const SizedBox(height: 16),
      _buildFormulaCard(
        context,
        title: '5. ВСР заготовки',
        formula: 'ВСРзагот = 100 × Углерод (С) + 53 - Dзаготовка ± 5',
        source: 'Рудман Л.И. "Технология производства проволоки", 1982',
      ),
      const SizedBox(height: 16),
      _buildFormulaCard(
        context,
        title: '6. ВСР готовой проволоки',
        formula:
            'ВСРготов = ВСРзагот + [0.6 × (Углерод + Dзаг/40 + 0.01 × Сум.Обжат.) × Сум.Обжат.] / [log10(√(100 - Сум.Обжат.)) + 0.0005 × Сум.Обжат.]',
        source: 'Рудман Л.И. "Технология производства проволоки", 1982',
      ),
      const SizedBox(height: 16),
      _buildFormulaCard(
        context,
        title: '7. Формула расчёта цинка на заготовке',
        formula:
            'Цинк на заготовке (г/м²) = (D_заг / D_кон) × P_кон × K\n\nГде:\n- D_заг — диаметр заготовки (мм),\n- D_кон — диаметр готовой проволоки (мм),\n- P_кон — норма цинка для конечного диаметра (г/м², по ГОСТ 7372-79, табл. 7),\n- K — поправочный коэффициент:\n  • 1.1 для групп С и Ж,\n  • 1.2–1.3 для группы ОЖ.',
        source:
            'Гуляев А.П. Технология волочения металлов. — М.: Металлургия, 1986',
      ),
    ],
  );
  Widget _buildFormulaCard(
    BuildContext context, {
    required String title,
    required String formula,
    required String source,
  }) => PrecisionPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        _gap,
        Text(
          formula,
          style: TextStyle(
            fontSize: 16,
            color: PrecisionPalette.of(context).accent,
          ),
        ),
        const Divider(height: 28),
        Text(
          source,
          style: TextStyle(color: PrecisionPalette.of(context).muted),
        ),
      ],
    ),
  );
}

class ZincDensityTableTab extends StatelessWidget {
  const ZincDensityTableTab({super.key});
  // Historical reference values intentionally remain separate from calculation data.
  static const rows = <List<String>>[
    ['0,18', '10', '20', '30'],
    ['От 0,20 до 0,24 включ.', '15', '20', '30'],
    ['Св. 0,24 до 0,32', '20', '25', '45'],
    ['Св. 0,32 до 0,38', '20', '25', '60'],
    ['Св. 0,38 до 0,45', '30', '40', '75'],
    ['Св. 0,45 до 0,55', '35', '40', '90'],
    ['Св. 0,55 до 0,65', '40', '50', '110'],
    ['Св. 0,65 до 0,75', '40', '50', '120'],
    ['Св. 0,75 до 0,95', '50', '70', '130'],
    ['Св. 0,95 до 1,15', '60', '80', '150'],
    ['Св. 1,15 до 1,40', '60', '90', '165'],
    ['Св. 1,40 до 1,80', '70', '100', '180'],
    ['Св. 1,80 до 2,40', '80', '110', '205'],
    ['Св. 2,40 до 3,00', '90', '125', '230'],
    ['Св. 3,00 до 3,80', '100', '135', '230'],
    ['Св. 3,80 до 4,40', '110', '150', '245'],
    ['Св. 4,40 до 5,10', '110', '165', '245'],
  ];
  @override
  Widget build(BuildContext context) => _Content(
    storageKey: 'reference-table',
    children: [
      const Text(
        'ГОСТ 7372-79, таб. №7',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      const Text('Номинальный диаметр, мм · Плотность цинка, г/м²'),
      _gap,
      LayoutBuilder(
        builder: (context, constraints) {
          final p = PrecisionPalette.of(context);
          final scale = MediaQuery.textScalerOf(context).scale(18) / 18;
          if (constraints.maxWidth >= 280 * scale) {
            return PrecisionPanel(
              child: Table(
                columnWidths: const {0: FlexColumnWidth(2.5)},
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder(
                  horizontalInside: BorderSide(color: p.line),
                ),
                children: [
                  for (final row in [
                    const ['Диаметр, мм', 'С', 'Ж', 'ОЖ'],
                    ...rows,
                  ])
                    TableRow(
                      children: [
                        for (var i = 0; i < 4; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 4,
                            ),
                            child: Text(
                              row[i],
                              textAlign:
                                  i == 0 ? TextAlign.start : TextAlign.right,
                              style: const TextStyle(
                                fontFeatures: PrecisionTokens.numbers,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            );
          }
          return Column(
            children: [
              for (final row in rows) ...[
                PrecisionPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        row[0],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 1; i < 4; i++)
                            Expanded(
                              child: Semantics(
                                label:
                                    'Группа ${['С', 'Ж', 'ОЖ'][i - 1]}, ${row[i]} граммов на квадратный метр',
                                excludeSemantics: true,
                                child: Column(
                                  children: [
                                    Text(
                                      ['С', 'Ж', 'ОЖ'][i - 1],
                                      style: TextStyle(color: p.muted),
                                    ),
                                    Text(
                                      row[i],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontFeatures: PrecisionTokens.numbers,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                _gap,
              ],
            ],
          );
        },
      ),
    ],
  );
}
