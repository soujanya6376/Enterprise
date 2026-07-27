import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../domain/theme_draft.dart';

/// Renders real POS surfaces using the in-progress draft tokens.
///
/// Deliberately shows a billing line, a total, and a form — the screens a
/// cashier actually stares at all day — rather than abstract swatches. A palette
/// can look fine as squares and still be unreadable on a receipt line.
class ThemePreviewPane extends StatelessWidget {
  const ThemePreviewPane({super.key, required this.draft, required this.mode});

  final ThemeDraft draft;
  final Brightness mode;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens;
    try {
      tokens = ThemeTokens.fromJson(
        draft.toJson()['modes'][mode == Brightness.dark ? 'dark' : 'light'],
        'preview',
      );
    } on TokenParseException catch (err) {
      // Mid-edit the draft can be briefly invalid. Say which token is wrong
      // instead of showing a blank pane or crashing the editor.
      return _PreviewError(message: err.toString());
    }

    final themeData = AppTheme.from(tokens, mode);

    return Container(
      color: context.tokens.color.background.surface,
      child: Theme(
        data: themeData,
        child: TokenTheme(
          tokens: tokens,
          child: Builder(
            builder: (inner) => Container(
              color: tokens.color.background.canvas,
              child: ListView(
                padding: EdgeInsets.all(tokens.spacing.lg),
                children: [
                  Text('Preview', style: themeData.textTheme.labelMedium),
                  SizedBox(height: tokens.spacing.sm),
                  const _BillPreview(),
                  SizedBox(height: tokens.spacing.lg),
                  const _FormPreview(),
                  SizedBox(height: tokens.spacing.lg),
                  const _StatusPreview(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BillPreview extends StatelessWidget {
  const _BillPreview();

  static const _lines = [
    ('Filter coffee', 2, '90.00'),
    ('Masala dosa', 1, '120.00'),
    ('Bottled water', 3, '60.00'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(t.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Invoice INV-000241', style: text.titleMedium),
                Chip(label: const Text('Pending'), visualDensity: VisualDensity.compact),
              ],
            ),
            Divider(height: t.spacing.lg),
            for (final (name, qty, amount) in _lines)
              Padding(
                padding: EdgeInsets.only(bottom: t.spacing.sm),
                child: Row(
                  children: [
                    Expanded(child: Text(name, style: text.bodyMedium)),
                    Text('×$qty', style: text.bodySmall),
                    SizedBox(width: t.spacing.md),
                    Text('₹$amount', style: text.bodyMedium),
                  ],
                ),
              ),
            Divider(height: t.spacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: text.bodySmall),
                Text('₹270.00', style: text.bodySmall),
              ],
            ),
            SizedBox(height: t.spacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tax (5%)', style: text.bodySmall),
                Text('₹13.50', style: text.bodySmall),
              ],
            ),
            SizedBox(height: t.spacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: text.titleLarge),
                Text('₹283.50', style: text.titleLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormPreview extends StatelessWidget {
  const _FormPreview();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TextField(
          decoration: InputDecoration(labelText: 'Amount received', hintText: '0.00'),
        ),
        SizedBox(height: t.spacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
            ),
            SizedBox(width: t.spacing.sm),
            Expanded(
              child: ElevatedButton(onPressed: () {}, child: const Text('Take payment')),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusPreview extends StatelessWidget {
  const _StatusPreview();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    Widget swatch(String label, Color background, Color foreground) => Container(
          padding: EdgeInsets.symmetric(
            horizontal: t.spacing.sm,
            vertical: t.spacing.xs,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(t.radius.sm),
          ),
          child: Text(label, style: text.labelMedium?.copyWith(color: foreground)),
        );

    return Wrap(
      spacing: t.spacing.sm,
      runSpacing: t.spacing.sm,
      children: [
        swatch('Paid', t.color.background.success, t.color.content.onAccent),
        swatch('Refunded', t.color.background.danger, t.color.content.onAccent),
        swatch('Partial', t.color.background.warning, t.color.content.onAccent),
        swatch('Accent', t.color.background.accent, t.color.content.onAccent),
      ],
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      color: t.color.background.surface,
      padding: EdgeInsets.all(t.spacing.lg),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: t.color.background.warning),
          SizedBox(height: t.spacing.sm),
          Text(
            'Preview paused',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: t.spacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: t.color.content.secondary),
          ),
        ],
      ),
    );
  }
}
