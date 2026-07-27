import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_toggle.dart';
import '../data/theme_repository.dart';
import '../domain/theme_admin_providers.dart';
import 'widgets/theme_preview_card.dart';

/// Admin → Appearance. One row per platform: pick which theme is live there.
///
/// Route: /admin/appearance (ADMIN only — guarded in the GoRouter config).
class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final themes = ref.watch(themeListProvider);
    final assignments = ref.watch(themeAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/admin/appearance/themes'),
            icon: const Icon(Icons.tune),
            label: const Text('Edit themes'),
          ),
          SizedBox(width: t.spacing.sm),
          const ThemeModeToggle(),
        ],
      ),
      body: assignments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(
          message: 'Could not load theme assignments.',
          onRetry: () => ref.invalidate(themeAssignmentsProvider),
        ),
        data: (current) => themes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorState(
            message: 'Could not load the theme list.',
            onRetry: () => ref.invalidate(themeListProvider),
          ),
          data: (available) => ListView(
            padding: EdgeInsets.all(t.spacing.lg),
            children: [
              Text(
                'Choose the theme each platform runs. Changes reach devices the '
                'next time they open the app.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: t.color.content.secondary,
                    ),
              ),
              SizedBox(height: t.spacing.lg),
              for (final platform in ClientPlatform.values) ...[
                _PlatformRow(
                  platform: platform,
                  selectedThemeId: current[platform]?.id,
                  available: available,
                  onChanged: (themeId) => _assign(context, ref, platform, themeId),
                ),
                SizedBox(height: t.spacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assign(
    BuildContext context,
    WidgetRef ref,
    ClientPlatform platform,
    String themeId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(themeAdminServiceProvider).assign(platform, themeId);
      ref.invalidate(themeAssignmentsProvider);
      // If we just changed this device's own platform, repaint immediately
      // rather than waiting for the next cold start.
      if (platform == ClientPlatform.current()) {
        await ref.read(themeControllerProviderForAdmin).refresh();
      }
      messenger.showSnackBar(
        SnackBar(content: Text('${_label(platform)} theme updated')),
      );
    } catch (err) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not update the ${_label(platform)} theme. $err')),
      );
    }
  }

  static String _label(ClientPlatform p) => switch (p) {
        ClientPlatform.web => 'Web',
        ClientPlatform.android => 'Android',
        ClientPlatform.ios => 'iOS',
      };
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({
    required this.platform,
    required this.selectedThemeId,
    required this.available,
    required this.onChanged,
  });

  final ClientPlatform platform;
  final String? selectedThemeId;
  final List<ThemeSummary> available;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final selected = available.where((x) => x.id == selectedThemeId).firstOrNull;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(t.spacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, color: t.color.content.secondary),
            SizedBox(width: t.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppearanceSettingsPage._label(platform),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: t.spacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: selectedThemeId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Live theme'),
                    items: [
                      for (final theme in available)
                        DropdownMenuItem(value: theme.id, child: Text(theme.name)),
                    ],
                    onChanged: (value) {
                      if (value != null && value != selectedThemeId) onChanged(value);
                    },
                  ),
                  if (selected == null) ...[
                    SizedBox(height: t.spacing.sm),
                    Text(
                      'No theme assigned yet. This platform is using its built-in fallback.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: t.color.content.danger,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected != null) ...[
              SizedBox(width: t.spacing.md),
              ThemePreviewCard(themeId: selected.id, compact: true),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (platform) {
        ClientPlatform.web => Icons.language,
        ClientPlatform.android => Icons.android,
        ClientPlatform.ios => Icons.phone_iphone,
      };
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: t.spacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
