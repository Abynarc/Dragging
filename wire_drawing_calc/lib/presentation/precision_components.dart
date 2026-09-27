import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'precision_theme.dart';

/// Only this shell creates backdrop filters: one header and one navigation
/// region. Rows and numeric surfaces cannot independently opt into blur.
class PrecisionScaffold extends StatelessWidget {
  const PrecisionScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.onToggleTheme,
    this.navigation,
    this.onBack,
    this.onToggleTransparency,
    this.blur = false,
  });
  final String title;
  final Widget body;
  final Widget? navigation;
  final VoidCallback onToggleTheme;
  final VoidCallback? onBack;
  final VoidCallback? onToggleTransparency;
  // Remains opt-in until physical-device profiling has passed.
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final p = PrecisionPalette.of(context);
    final effects =
        blur &&
        !MediaQuery.of(context).disableAnimations &&
        !MediaQuery.of(context).highContrast;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: p.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: p.background,
        systemNavigationBarIconBrightness:
            p.dark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: DecoratedBox(
          decoration: BoxDecoration(
            color: p.background,
            gradient:
                effects
                    ? LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [p.aura, p.background],
                      stops: const [0, .45],
                    )
                    : null,
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                  child: _NavigationSurface(
                    blur: effects,
                    child: Row(
                      children: [
                        if (onBack != null)
                          Semantics(
                            label: 'Назад',
                            button: true,
                            onTap: onBack,
                            child: ExcludeSemantics(
                              child: BackButton(onPressed: onBack),
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ),
                        PrecisionControlSemantics(
                          label: 'Переключить тему',
                          child: IconButton(
                            onPressed: onToggleTheme,
                            tooltip: 'Переключить тему',
                            icon: Icon(
                              p.dark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                            ),
                          ),
                        ),
                        if (onToggleTransparency != null)
                          PrecisionControlSemantics(
                            label: 'Без прозрачности',
                            child: IconButton(
                              onPressed:
                                  MediaQuery.of(context).highContrast ||
                                          MediaQuery.of(
                                            context,
                                          ).disableAnimations
                                      ? null
                                      : onToggleTransparency,
                              isSelected: !effects,
                              tooltip: 'Без прозрачности',
                              icon: const Icon(Icons.blur_on),
                              selectedIcon: const Icon(Icons.blur_off),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: body),
                if (navigation != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                    child: _NavigationSurface(
                      blur: effects,
                      child: navigation!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationSurface extends StatelessWidget {
  const _NavigationSurface({required this.child, required this.blur});
  final Widget child;
  final bool blur;
  @override
  Widget build(BuildContext context) {
    final p = PrecisionPalette.of(context);
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: blur ? p.glass : p.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: p.line),
      ),
      child: child,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child:
          blur
              ? BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: PrecisionTokens.blurSigma,
                  sigmaY: PrecisionTokens.blurSigma,
                ),
                child: content,
              )
              : content,
    );
  }
}

class PrecisionPanel extends StatelessWidget {
  const PrecisionPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final p = PrecisionPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(PrecisionTokens.padding),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.line),
        borderRadius: BorderRadius.circular(PrecisionTokens.radius),
      ),
      child: child,
    );
  }
}

class PrecisionNumberField extends StatelessWidget {
  const PrecisionNumberField({
    super.key,
    required this.controller,
    required this.label,
    this.unit,
    this.error,
    this.onChanged,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.integer = false,
  });
  final TextEditingController controller;
  final String label;
  final String? unit, error;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool enabled, autofocus, integer;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ExcludeSemantics(
        child: Text(
          label,
          style: TextStyle(color: PrecisionPalette.of(context).muted),
        ),
      ),
      const SizedBox(height: 8),
      PrecisionControlSemantics(
        label: unit == null ? label : '$label, $unit',
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          enabled: enabled,
          autofocus: autofocus,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.numberWithOptions(
            decimal: !integer,
            signed: true,
          ),
          // No input filtering: the existing parser defines accepted input.
          style: const TextStyle(
            fontSize: 20,
            fontFeatures: PrecisionTokens.numbers,
          ),
          decoration: InputDecoration(
            errorText: error,
            // suffixText is hidden when an empty field has no focus.
            suffixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 48,
            ),
            suffixIcon:
                unit == null
                    ? null
                    : ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              unit!,
                              style: TextStyle(
                                color: PrecisionPalette.of(context).muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        ),
      ),
    ],
  );
}

class PrecisionActions extends StatelessWidget {
  const PrecisionActions({super.key, this.onCalculate, this.onReset});
  final VoidCallback? onCalculate, onReset;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      OutlinedButton(onPressed: onReset, child: const Text('Сброс')),
      ElevatedButton(onPressed: onCalculate, child: const Text('Рассчитать')),
    ],
  );
}

/// Shared accessible selector for zinc groups and reference tabs. Wrap keeps
/// full labels reachable on narrow screens and with larger system text.
class PrecisionChoices extends StatelessWidget {
  const PrecisionChoices({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int>? onSelected;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < labels.length; i++)
        ChoiceChip(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          label: Text(labels[i]),
          selected: selected == i,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          onSelected: onSelected == null ? null : (_) => onSelected!(i),
        ),
    ],
  );
}

class PrecisionResultRow extends StatelessWidget {
  const PrecisionResultRow({
    super.key,
    required this.label,
    required this.value,
  });
  final String label, value;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 8,
    alignment: WrapAlignment.spaceBetween,
    children: [
      Text(label),
      Text(
        value,
        style: TextStyle(
          color: PrecisionPalette.of(context).accent,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFeatures: PrecisionTokens.numbers,
        ),
      ),
    ],
  );
}

class PrecisionRouteRow extends StatelessWidget {
  const PrecisionRouteRow({
    super.key,
    required this.index,
    required this.controller,
    required this.reduction,
    required this.onChanged,
  });
  final int index;
  final TextEditingController controller;
  final String reduction;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => PrecisionPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrecisionNumberField(
          controller: controller,
          label: index == 0 ? 'Заготовка' : 'Проход $index',
          unit: 'мм',
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        PrecisionResultRow(label: 'Обжатие', value: reduction),
      ],
    ),
  );
}

class PrecisionError extends StatelessWidget {
  const PrecisionError({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final p = PrecisionPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.errorBackground,
          border: Border.all(color: p.error),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: p.error, semanticLabel: 'Ошибка'),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(color: p.error))),
          ],
        ),
      ),
    );
  }
}

/// Export the label and control actions as one Android accessibility node.
/// A plain parent Semantics leaves Material 3's button/edit node unlabeled.
class PrecisionControlSemantics extends StatelessWidget {
  const PrecisionControlSemantics({
    super.key,
    required this.label,
    required this.child,
    this.selected,
  });
  final String label;
  final Widget child;
  final bool? selected;
  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(label: label, selected: selected, child: child),
  );
}
