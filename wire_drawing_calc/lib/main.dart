import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:math' as math;

void main() {
  runApp(const WireDrawingApp());
}

class WireDrawingApp extends StatefulWidget {
  const WireDrawingApp({super.key});

  @override
  State<WireDrawingApp> createState() => _WireDrawingAppState();
}

class _WireDrawingAppState extends State<WireDrawingApp> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _darkMode =
        WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
  }

  void _toggleDarkMode() {
    setState(() {
      _darkMode = !_darkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Калькулятор волочения',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(surface: Colors.white),
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.grey[300],
          displayColor: Colors.grey[300],
        ),
      ),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(darkMode: _darkMode, toggleDarkMode: _toggleDarkMode),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  final bool darkMode;
  final VoidCallback toggleDarkMode;

  const HomeScreen({
    super.key,
    required this.darkMode,
    required this.toggleDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 44),
          SizedBox(
            height: screenHeight * 0.3,
            width: double.infinity,
            child: Image.asset(
              'assets/background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.blueGrey,
                  child: const Center(
                    child: Icon(Icons.image, size: 50, color: Colors.white),
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: screenHeight * 0.04,
              bottom: screenHeight * 0.03,
              left: screenWidth * 0.07,
            ),
            child: Text(
              'Выберите\nрежим расчёта',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: screenHeight * 0.03,
                fontWeight: FontWeight.w800,
                color: darkMode ? Colors.grey[300] : const Color(0xFF1F2024),
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.01,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildMenuButton(
                    context,
                    'Расчёт маршрута',
                    const RouteCalculationScreen(),
                    buttonHeight: screenHeight * 0.075,
                    fontSize: 15,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  _buildMenuButton(
                    context,
                    'Расчёт линейного маршрута',
                    const LinearRouteScreen(),
                    buttonHeight: screenHeight * 0.075,
                    fontSize: 15,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  _buildMenuButton(
                    context,
                    'Расчёт цинка на заготовке',
                    const ZincCalculationScreen(),
                    buttonHeight: screenHeight * 0.075,
                    fontSize: 15,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  _buildMenuButton(
                    context,
                    'Справка и формулы',
                    const ReferenceScreen(),
                    buttonHeight: screenHeight * 0.075,
                    fontSize: 15,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: screenHeight * 0.025,
              left: screenWidth * 0.06,
              right: screenWidth * 0.04,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'by DK and IB',
                  style: TextStyle(
                    color:
                        darkMode
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black.withOpacity(0.9),
                    fontSize: screenHeight * 0.018,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: darkMode ? Colors.amber : Colors.black,
                      width: 1.0,
                    ),
                  ),
                  child: IconButton(
                    onPressed: toggleDarkMode,
                    iconSize: screenHeight * 0.029,
                    icon: Icon(
                      darkMode ? Icons.wb_sunny : Icons.nightlight_round,
                      color: darkMode ? Colors.amber : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    Widget screen, {
    required double buttonHeight,
    double fontSize = 16,
    double frameWidth = 1.4,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return SizedBox(
      height: buttonHeight,
      child: ElevatedButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          padding: EdgeInsets.symmetric(
            vertical: buttonHeight * 0.15,
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: darkMode ? Colors.grey[700]! : const Color(0xFFD4D6DD),
              width: frameWidth,
            ),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Справка и формулы'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Формулы и источники'),
              Tab(text: 'Таблица плотности цинка'),
            ],
          ),
        ),
        body: const Padding(
          padding: EdgeInsets.only(bottom: 60),
          child: TabBarView(
            children: [FormulasAndSourcesTab(), ZincDensityTableTab()],
          ),
        ),
      ),
    );
  }
}

class FormulasAndSourcesTab extends StatelessWidget {
  const FormulasAndSourcesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormulaCard(
            title: '1. Обжатие (уменьшение площади сечения)',
            formula: 'Обжатие (%) = [1 - (Dпосле/Dдо)^2] × 100',
            source: 'Грудев А.П. "Теория волочения проволоки", 1989',
          ),
          const SizedBox(height: 16),
          _buildFormulaCard(
            title: '2. Расчет диаметра после обжатия',
            formula: 'Dпосле = √(Dцель^2/(1 - Обжатие(%)/100))',
            source: 'Третьяков А.В. "Механические свойства металлов", 1960',
          ),
          const SizedBox(height: 16),
          _buildFormulaCard(
            title: '3. Суммарное обжатие',
            formula:
                'Суммарное обжатие (%) = (Dзаготовка^2 - Dчистовой^2)/Dзаготовка^2 × 100',
            source: 'Смирнов-Аляев Г.А. "Сопротивление материалов", 1968',
          ),
          const SizedBox(height: 16),
          _buildFormulaCard(
            title: '4. Единичное обжатие',
            formula:
                'Единичное обжатие (%) = [1 - ((100 - Сум.Обжат.)/100)^(1/N)] × 100\nгде N - число проходов',
            source: 'Зиновьев В.А. "Технология волочения металлов", 1974',
          ),
          const SizedBox(height: 16),
          _buildFormulaCard(
            title: '5. ВСР заготовки',
            formula: 'ВСРзагот = 100 × Углерод (С) + 53 - Dзаготовка ± 5',
            source: 'Рудман Л.И. "Технология производства проволоки", 1982',
          ),
          const SizedBox(height: 16),
          _buildFormulaCard(
            title: '6. ВСР готовой проволоки',
            formula:
                'ВСРготов = ВСРзагот + [0.6 × (Углерод + Dзаг/40 + 0.01 × Сум.Обжат.) × Сум.Обжат.] / [log10(√(100 - Сум.Обжат.)) + 0.0005 × Сум.Обжат.]',
            source: 'Рудман Л.И. "Технология производства проволоки", 1982',
          ),
          const SizedBox(height: 16),
          _buildFormulaCard(
            title: '7. Формула расчёта цинка на заготовке',
            formula:
                'Цинк на заготовке (г/м²) = (D_заг / D_кон) × P_кон × K\n\nГде:\n- D_заг — диаметр заготовки (мм),\n- D_кон — диаметр готовой проволоки (мм),\n- P_кон — норма цинка для конечного диаметра (г/м², по ГОСТ 7372-79, табл. 7),\n- K — поправочный коэффициент:\n  • 1.1 для групп С и Ж,\n  • 1.2–1.3 для группы ОЖ.',
            source:
                'Гуляев А.П. Технология волочения металлов. — М.: Металлургия, 1986',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFormulaCard({
    required String title,
    required String formula,
    required String source,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              formula,
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            Text(
              'Источник: $source',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class ZincDensityTableTab extends StatelessWidget {
  const ZincDensityTableTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'ГОСТ 7372-79, таб. №7',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(),
            columnWidths: const {
              0: FixedColumnWidth(100),
              1: FixedColumnWidth(80),
              2: FixedColumnWidth(80),
              3: FixedColumnWidth(80),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.blueGrey[800] : Colors.blueGrey,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Номинальный диаметр, мм',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'С',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Ж',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'ОЖ',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              _buildTableRow('0,18', '10', '20', '30'),
              _buildTableRow('От 0,20 до 0,24 включ.', '15', '20', '30'),
              _buildTableRow('Св. 0,24 до 0,32', '20', '25', '45'),
              _buildTableRow('Св. 0,32 до 0,38', '20', '25', '60'),
              _buildTableRow('Св. 0,38 до 0,45', '30', '40', '75'),
              _buildTableRow('Св. 0,45 до 0,55', '35', '40', '90'),
              _buildTableRow('Св. 0,55 до 0,65', '40', '50', '110'),
              _buildTableRow('Св. 0,65 до 0,75', '40', '50', '120'),
              _buildTableRow('Св. 0,75 до 0,95', '50', '70', '130'),
              _buildTableRow('Св. 0,95 до 1,15', '60', '80', '150'),
              _buildTableRow('Св. 1,15 до 1,40', '60', '90', '165'),
              _buildTableRow('Св. 1,40 до 1,80', '70', '100', '180'),
              _buildTableRow('Св. 1,80 до 2,40', '80', '110', '205'),
              _buildTableRow('Св. 2,40 до 3,00', '90', '125', '230'),
              _buildTableRow('Св. 3,00 до 3,80', '100', '135', '230'),
              _buildTableRow('Св. 3,80 до 4,40', '110', '150', '245'),
              _buildTableRow('Св. 4,40 до 5,10', '110', '165', '245'),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String diameter, String c, String zh, String ozh) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(diameter, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(c, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(zh, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(ozh, textAlign: TextAlign.center),
        ),
      ],
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

  // Настройки размеров (адаптивные)
  double get blockWidth => MediaQuery.of(context).size.width * 0.9;
  double get blockPadding => 12.0;
  double get blockSpacing => 12.0;

  // Шрифты
  static const double workpieceFontSize = 18.0;
  static const FontWeight workpieceFontWeight = FontWeight.normal;
  static const double blockTitleFontSize = 16.0;
  static const double inputFontSize = 16.0; // Общий размер для всех полей ввода
  static const double reductionFontSize = 17.0;

  // Размеры полей (адаптивные)
  double get workpieceInputWidth => blockWidth * 0.35;
  double get blockInputWidth => blockWidth * 0.45;
  double get underlineWidth =>
      blockWidth * 0.45; // Подчеркивание пропорционально

  // Границы
  static const Color blockBorderColor = Color.fromARGB(255, 212, 214, 221);
  static const double blockBorderWidth = 1.5;
  static const double blockBorderRadius = 15.0;

  // Подчеркивание
  static const Color underlineColor = Color.fromARGB(255, 212, 214, 221);
  static const double underlineHeight = 1.5;

  // Цвета
  static const Color lightWorkpieceTitleColor = Colors.black;
  static const Color lightInputTextColor = Color(
    0xFF6000AB,
  ); // Общий цвет для ввода
  static const Color lightBlockTitleColor = Colors.black;
  static const Color lightReductionColor = Color(0xFF6000AB);

  static const Color darkWorkpieceTitleColor = Colors.white;
  static const Color darkInputTextColor = Colors.white;
  static const Color darkBlockTitleColor = Colors.white;
  static const Color darkReductionColor = Color.fromARGB(255, 166, 49, 255);

  // AppBar
  static const double appBarTitleSpacing = 10.0;
  static const Color appBarColorLight = Colors.white;
  static const Color appBarColorDark = Color(0xFF121212);
  static const Color appBarTextColorLight = Colors.black;
  static const Color appBarTextColorDark = Colors.white;
  static const Color appBarIconColorLight = Colors.black;
  static const Color appBarIconColorDark = Colors.white;

  // Стиль ввода (общий для всех полей)
  TextStyle getInputTextStyle(bool isDarkMode) => TextStyle(
    fontSize: inputFontSize,
    color: isDarkMode ? darkInputTextColor : lightInputTextColor,
    fontWeight: FontWeight.bold,
  );

  // Стиль подсказки
  TextStyle getHintTextStyle(bool isDarkMode) => TextStyle(
    fontWeight: FontWeight.normal,
    color: (isDarkMode ? darkInputTextColor : lightInputTextColor).withOpacity(
      0.5,
    ),
  );

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

        _reductions[i - 1] = (1 - math.pow(next / prev, 2)) * 100;
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Цвета для AppBar
    final Color appBarColor = isDarkMode ? appBarColorDark : appBarColorLight;
    final Color appBarTextColor =
        isDarkMode ? appBarTextColorDark : appBarTextColorLight;
    final Color appBarIconColor =
        isDarkMode ? appBarIconColorDark : appBarIconColorLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Расчёт маршрута'),
        titleSpacing: appBarTitleSpacing,
        backgroundColor: appBarColor,
        foregroundColor: appBarIconColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: appBarTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth > 600 ? 24.0 : 16.0,
              vertical: 16.0,
            ),
            child: Center(
              child: SizedBox(
                width: blockWidth,
                child: Column(
                  children: [
                    // Заготовка
                    Padding(
                      padding: EdgeInsets.all(blockPadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Заготовка',
                            style: TextStyle(
                              fontSize: workpieceFontSize,
                              color:
                                  isDarkMode
                                      ? darkWorkpieceTitleColor
                                      : lightWorkpieceTitleColor,
                              fontWeight: workpieceFontWeight,
                            ),
                          ),
                          SizedBox(
                            width: workpieceInputWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                TextField(
                                  controller: _diameterControllers[0],
                                  textAlign: TextAlign.right,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: getInputTextStyle(isDarkMode),
                                  decoration: InputDecoration(
                                    hintText: 'Диаметр',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    hintStyle: getHintTextStyle(isDarkMode),
                                  ),
                                  onChanged: (value) => _calculateReductions(),
                                ),
                                Container(
                                  height: underlineHeight,
                                  width: underlineWidth,
                                  color: underlineColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: blockSpacing),

                    // Блоки 1-15
                    for (int i = 1; i < 16; i++) ...[
                      Container(
                        padding: EdgeInsets.all(blockPadding),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: blockBorderColor,
                            width: blockBorderWidth,
                          ),
                          borderRadius: BorderRadius.circular(
                            blockBorderRadius,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Блок $i',
                                  style: TextStyle(
                                    fontSize: blockTitleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDarkMode
                                            ? darkBlockTitleColor
                                            : lightBlockTitleColor,
                                  ),
                                ),
                                SizedBox(
                                  width: blockInputWidth,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      TextField(
                                        controller: _diameterControllers[i],
                                        textAlign: TextAlign.right,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        style: getInputTextStyle(isDarkMode),
                                        decoration: InputDecoration(
                                          hintText: 'Введите значение',
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          hintStyle: getHintTextStyle(
                                            isDarkMode,
                                          ),
                                        ),
                                        onChanged:
                                            (value) => _calculateReductions(),
                                      ),
                                      Container(
                                        height: underlineHeight,
                                        width: underlineWidth,
                                        color: underlineColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Обжатие: ${_reductions[i - 1].toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: reductionFontSize,
                                    color:
                                        isDarkMode
                                            ? darkReductionColor
                                            : lightReductionColor,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < 15) SizedBox(height: blockSpacing),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
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
    final theme = Theme.of(context);

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
                                _selectedGroup == 'C'
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                            foregroundColor:
                                _selectedGroup == 'C'
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : null,
                          ),
                          child: const Text('С'),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() => _selectedGroup = 'Ж'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _selectedGroup == 'Ж'
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                            foregroundColor:
                                _selectedGroup == 'Ж'
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : null,
                          ),
                          child: const Text('Ж'),
                        ),
                        ElevatedButton(
                          onPressed:
                              () => setState(() => _selectedGroup = 'ОЖ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _selectedGroup == 'ОЖ'
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                            foregroundColor:
                                _selectedGroup == 'ОЖ'
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : null,
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
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
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
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Количество цинка на заготовке должно быть не менее ${_result.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Text(
                        'Поверхностная плотность цинка соответствовует нормам, указанным в табл. 7 ГОСТ 7372-79.\n'
                        'К - поправочный коэффициент, который принимает значения 1,1 для групп "С" и "Ж", а для группы "ОЖ" - 1,2-1,3',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
