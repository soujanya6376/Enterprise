import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../../core/theme/app_theme.dart';

/// A collapsible group of token fields in the editor.
///
/// Three shapes — colour swatches, numeric steppers, and the typography block —
/// because those are the three kinds of value in the token contract, and each
/// needs different affordances. A hex string in a plain text box is unusable;
/// a swatch you can see next to its neighbours is not.
class TokenFieldGroup extends StatelessWidget {
  const TokenFieldGroup._({
    required this.title,
    required this.caption,
    required this.child,
  });

  final String title;
  final String caption;
  final Widget child;

  factory TokenFieldGroup.color({
    required String title,
    required String caption,
    required Map<String, Color> values,
    required void Function(String key, Color value) onChanged,
  }) =>
      TokenFieldGroup._(
        title: title,
        caption: caption,
        child: _ColorGrid(values: values, onChanged: onChanged),
      );

  factory TokenFieldGroup.number({
    required String title,
    required String caption,
    required Map<String, num> values,
    required double min,
    required double max,
    required void Function(String key, num value) onChanged,
  }) =>
      TokenFieldGroup._(
        title: title,
        caption: caption,
        child: _NumberGrid(values: values, min: min, max: max, onChanged: onChanged),
      );

  factory TokenFieldGroup.typography({
    required String title,
    required String caption,
    required Map<String, String> families,
    required Map<String, Map<String, num>> scale,
    required void Function(String role, String value) onFamilyChanged,
    required void Function(String role, String field, num value) onScaleChanged,
  }) =>
      TokenFieldGroup._(
        title: title,
        caption: caption,
        child: _TypographyFields(
          families: families,
          scale: scale,
          onFamilyChanged: onFamilyChanged,
          onScaleChanged: onScaleChanged,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: t.spacing.lg),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(t.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: t.spacing.xs),
              Text(
                caption,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: t.color.content.secondary),
              ),
              SizedBox(height: t.spacing.md),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({required this.values, required this.onChanged});
  final Map<String, Color> values;
  final void Function(String key, Color value) onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Wrap(
      spacing: t.spacing.md,
      runSpacing: t.spacing.md,
      children: [
        for (final entry in values.entries)
          SizedBox(
            width: 200,
            child: _ColorField(
              label: entry.key,
              value: entry.value,
              onChanged: (c) => onChanged(entry.key, c),
            ),
          ),
      ],
    );
  }
}

class _ColorField extends StatefulWidget {
  const _ColorField({required this.label, required this.value, required this.onChanged});
  final String label;
  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  State<_ColorField> createState() => _ColorFieldState();
}

class _ColorFieldState extends State<_ColorField> {
  late final TextEditingController _controller =
      TextEditingController(text: _toHex(widget.value));

  @override
  void didUpdateWidget(_ColorField old) {
    super.didUpdateWidget(old);
    final incoming = _toHex(widget.value);
    // Don't fight the admin's cursor while they're mid-edit.
    if (incoming != _toHex(_parse(_controller.text) ?? widget.value)) {
      _controller.text = incoming;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openPicker() async {
    var picked = widget.value;
    final result = await showDialog<Color>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Pick a colour — ${widget.label}'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: widget.value,
            onColorChanged: (c) => picked = c,
            enableAlpha: true,
            displayThumbColor: true,
            labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, picked),
            child: const Text('Use colour'),
          ),
        ],
      ),
    );
    if (result != null) {
      widget.onChanged(result);
      setState(() => _controller.text = _toHex(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Tooltip(
          message: 'Pick a colour',
          child: InkWell(
            borderRadius: BorderRadius.circular(t.radius.sm),
            onTap: _openPicker,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.value,
                borderRadius: BorderRadius.circular(t.radius.sm),
                border: Border.all(color: t.color.border.standard, width: t.borderWidth.hairline),
              ),
            ),
          ),
        ),
        SizedBox(width: t.spacing.sm),
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: widget.label, isDense: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(9),
            ],
            onChanged: (raw) {
              // Only commit once it's a complete, valid colour — otherwise every
              // keystroke would repaint the preview with garbage.
              final parsed = _parse(raw);
              if (parsed != null) widget.onChanged(parsed);
            },
          ),
        ),
      ],
    );
  }

  static Color? _parse(String raw) {
    var hex = raw.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    return value == null ? null : Color(value);
  }

  static String _toHex(Color color) {
    final argb = color.toARGB32();
    final alpha = (argb >> 24) & 0xFF;
    final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
    return alpha == 0xFF ? '#$rgb' : '#${alpha.toRadixString(16).padLeft(2, '0').toUpperCase()}$rgb';
  }
}

class _NumberGrid extends StatelessWidget {
  const _NumberGrid({
    required this.values,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final Map<String, num> values;
  final double min;
  final double max;
  final void Function(String key, num value) onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Wrap(
      spacing: t.spacing.md,
      runSpacing: t.spacing.md,
      children: [
        for (final entry in values.entries)
          SizedBox(
            width: 160,
            child: TextFormField(
              initialValue: entry.value.toString(),
              decoration: InputDecoration(labelText: entry.key, isDense: true, suffixText: 'px'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              validator: (raw) {
                final parsed = num.tryParse(raw ?? '');
                if (parsed == null) return 'Enter a number';
                if (parsed < min || parsed > max) return 'Must be $min–$max';
                return null;
              },
              onChanged: (raw) {
                final parsed = num.tryParse(raw);
                if (parsed != null && parsed >= min && parsed <= max) {
                  onChanged(entry.key, parsed);
                }
              },
            ),
          ),
      ],
    );
  }
}

class _TypographyFields extends StatelessWidget {
  const _TypographyFields({
    required this.families,
    required this.scale,
    required this.onFamilyChanged,
    required this.onScaleChanged,
  });

  final Map<String, String> families;
  final Map<String, Map<String, num>> scale;
  final void Function(String role, String value) onFamilyChanged;
  final void Function(String role, String field, num value) onScaleChanged;

  static const _weights = [100, 200, 300, 400, 500, 600, 700, 800, 900];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: t.spacing.md,
          runSpacing: t.spacing.md,
          children: [
            for (final entry in families.entries)
              SizedBox(
                width: 200,
                child: TextFormField(
                  initialValue: entry.value,
                  decoration: InputDecoration(
                    labelText: '${entry.key} font',
                    isDense: true,
                    helperText: 'Must be bundled in pubspec.yaml',
                  ),
                  onChanged: (v) {
                    if (v.trim().isNotEmpty) onFamilyChanged(entry.key, v.trim());
                  },
                ),
              ),
          ],
        ),
        SizedBox(height: t.spacing.lg),
        for (final role in scale.entries) ...[
          Text(role.key, style: Theme.of(context).textTheme.labelLarge),
          SizedBox(height: t.spacing.sm),
          Wrap(
            spacing: t.spacing.sm,
            runSpacing: t.spacing.sm,
            children: [
              SizedBox(
                width: 110,
                child: TextFormField(
                  initialValue: role.value['size'].toString(),
                  decoration: const InputDecoration(labelText: 'size', isDense: true),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    final parsed = num.tryParse(v);
                    if (parsed != null && parsed > 0 && parsed <= 200) {
                      onScaleChanged(role.key, 'size', parsed);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<int>(
                  initialValue: role.value['weight']?.toInt(),
                  decoration: const InputDecoration(labelText: 'weight', isDense: true),
                  items: [
                    for (final w in _weights)
                      DropdownMenuItem(value: w, child: Text('$w')),
                  ],
                  onChanged: (v) {
                    if (v != null) onScaleChanged(role.key, 'weight', v);
                  },
                ),
              ),
              SizedBox(
                width: 110,
                child: TextFormField(
                  initialValue: role.value['height'].toString(),
                  decoration: const InputDecoration(labelText: 'height', isDense: true),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    final parsed = num.tryParse(v);
                    if (parsed != null && parsed >= 0.5 && parsed <= 4) {
                      onScaleChanged(role.key, 'height', parsed);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 130,
                child: TextFormField(
                  initialValue: role.value['letterSpacing'].toString(),
                  decoration: const InputDecoration(labelText: 'tracking', isDense: true),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (v) {
                    final parsed = num.tryParse(v);
                    if (parsed != null && parsed >= -10 && parsed <= 10) {
                      onScaleChanged(role.key, 'letterSpacing', parsed);
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: t.spacing.md),
        ],
      ],
    );
  }
}
