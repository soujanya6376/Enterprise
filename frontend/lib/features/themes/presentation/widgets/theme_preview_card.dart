import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../domain/theme_admin_providers.dart';

/// Small colour-strip preview shown next to each platform on the assignment
/// page, so an admin can tell "Midnight" from "Daylight" without opening either.
class ThemePreviewCard extends ConsumerWidget {
  const ThemePreviewCard({super.key, required this.themeId, this.compact = false});

  final String themeId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final detail = ref.watch(themeDetailProvider(themeId));

    return SizedBox(
      width: compact ? 120 : 200,
      child: detail.when(
        loading: () => SizedBox(
          height: compact ? 48 : 80,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (theme) {
          final ThemeTokens light;
          try {
            light = ThemeTokens.fromJson(theme.tokens['modes']['light'], 'preview');
          } on TokenParseException {
            return const SizedBox.shrink();
          }

          final swatches = [
            light.color.background.canvas,
            light.color.background.surface,
            light.color.background.accent,
            light.color.content.primary,
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(t.radius.sm),
                child: Row(
                  children: [
                    for (final color in swatches)
                      Expanded(child: Container(height: compact ? 32 : 48, color: color)),
                  ],
                ),
              ),
              SizedBox(height: t.spacing.xs),
              Text(
                'rev ${theme.revision}',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: t.color.content.muted),
              ),
            ],
          );
        },
      ),
    );
  }
}
