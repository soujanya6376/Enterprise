import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_toggle.dart';
import '../domain/theme_admin_providers.dart';

class ThemesListPage extends ConsumerWidget {
  const ThemesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final themes = ref.watch(themeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Themes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/appearance'),
        ),
        actions: [
          IconButton(
            tooltip: 'Create theme',
            onPressed: () => _createTheme(context, ref),
            icon: const Icon(Icons.add),
          ),
          const ThemeModeToggle(),
        ],
      ),
      body: themes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load themes. $err'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(themeListProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (items) => ListView.separated(
          padding: EdgeInsets.all(t.spacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, __) => SizedBox(height: t.spacing.sm),
          itemBuilder: (context, index) {
            final theme = items[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () =>
                      context.go('/admin/appearance/themes/${theme.id}'),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(theme.name),
                  ),
                ),
                subtitle: Text(theme.description ?? 'No description'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit theme',
                      onPressed: () =>
                          context.go('/admin/appearance/themes/${theme.id}'),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete theme',
                      onPressed: () =>
                          _deleteTheme(context, ref, theme.id, theme.name),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _createTheme(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final created = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Theme name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, {
              'name': nameController.text.trim(),
              'description': descController.text.trim(),
            }),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created == null) return;
    final name = created['name'];
    if (name == null || name.isEmpty) {
      if (!context.mounted) return;
      messenger.showSnackBar(
          const SnackBar(content: Text('Theme name is required')));
      return;
    }

    try {
      await ref
          .read(themeAdminServiceProvider)
          .create(name, _defaultTokens(), description: created['description']);
      if (!context.mounted) return;
      ref.invalidate(themeListProvider);
      messenger.showSnackBar(SnackBar(content: Text('Created "$name"')));
    } catch (err) {
      if (!context.mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text('Could not create theme. $err')));
    }
  }

  Future<void> _deleteTheme(
      BuildContext context, WidgetRef ref, String id, String name) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete theme'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(themeAdminServiceProvider).delete(id);
      if (!context.mounted) return;
      ref.invalidate(themeListProvider);
      messenger.showSnackBar(SnackBar(content: Text('Deleted "$name"')));
    } catch (err) {
      if (!context.mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text('Could not delete theme. $err')));
    }
  }

  Map<String, dynamic> _defaultTokens() {
    return {
      'schemaVersion': 1,
      'modes': {
        'light': {
          'color': {
            'background': {
              'canvas': '#FFFFFF',
              'surface': '#F7F7F8',
              'raised': '#FFFFFF',
              'inverse': '#15161A',
              'accent': '#3A7BFF',
              'danger': '#D64545',
              'success': '#2F9E44',
              'warning': '#F08C00',
            },
            'content': {
              'primary': '#111111',
              'secondary': '#4B5563',
              'muted': '#6B7280',
              'onAccent': '#FFFFFF',
              'onInverse': '#FFFFFF',
              'danger': '#D64545',
            },
            'border': {
              'subtle': '#E5E7EB',
              'default': '#D1D5DB',
              'strong': '#9CA3AF',
              'accent': '#3A7BFF',
              'focus': '#2563EB',
            },
          },
          'spacing': {
            '0': 0,
            '1': 4,
            '2': 8,
            '3': 12,
            '4': 16,
            '5': 24,
            '6': 32,
            '7': 48,
            '8': 64
          },
          'radius': {'none': 0, 'sm': 4, 'md': 8, 'lg': 16, 'pill': 999},
          'borderWidth': {'none': 0, 'hairline': 1, 'thick': 2},
          'elevation': {'none': 0, 'sm': 2, 'md': 4, 'lg': 8},
          'typography': {
            'fontFamily': {
              'display': 'Inter',
              'body': 'Inter',
              'mono': 'Roboto Mono'
            },
            'scale': {
              'display': {
                'size': 32,
                'weight': 700,
                'height': 1.1,
                'letterSpacing': -0.5
              },
              'title': {
                'size': 24,
                'weight': 600,
                'height': 1.2,
                'letterSpacing': -0.2
              },
              'body': {
                'size': 16,
                'weight': 400,
                'height': 1.5,
                'letterSpacing': 0
              },
              'label': {
                'size': 14,
                'weight': 500,
                'height': 1.4,
                'letterSpacing': 0.2
              },
              'caption': {
                'size': 12,
                'weight': 400,
                'height': 1.3,
                'letterSpacing': 0.1
              },
              'mono': {
                'size': 14,
                'weight': 400,
                'height': 1.4,
                'letterSpacing': 0
              },
            },
          },
        },
        'dark': {
          'color': {
            'background': {
              'canvas': '#0F1115',
              'surface': '#171A21',
              'raised': '#1F232B',
              'inverse': '#FFFFFF',
              'accent': '#5B8CFF',
              'danger': '#FF6B6B',
              'success': '#4AD991',
              'warning': '#F6C344',
            },
            'content': {
              'primary': '#F5F7FA',
              'secondary': '#BFC7D1',
              'muted': '#8C94A3',
              'onAccent': '#FFFFFF',
              'onInverse': '#111111',
              'danger': '#FF6B6B',
            },
            'border': {
              'subtle': '#2A2F3A',
              'default': '#3B4350',
              'strong': '#5B6472',
              'accent': '#5B8CFF',
              'focus': '#7AA2FF',
            },
          },
          'spacing': {
            '0': 0,
            '1': 4,
            '2': 8,
            '3': 12,
            '4': 16,
            '5': 24,
            '6': 32,
            '7': 48,
            '8': 64
          },
          'radius': {'none': 0, 'sm': 4, 'md': 8, 'lg': 16, 'pill': 999},
          'borderWidth': {'none': 0, 'hairline': 1, 'thick': 2},
          'elevation': {'none': 0, 'sm': 2, 'md': 4, 'lg': 8},
          'typography': {
            'fontFamily': {
              'display': 'Inter',
              'body': 'Inter',
              'mono': 'Roboto Mono'
            },
            'scale': {
              'display': {
                'size': 32,
                'weight': 700,
                'height': 1.1,
                'letterSpacing': -0.5
              },
              'title': {
                'size': 24,
                'weight': 600,
                'height': 1.2,
                'letterSpacing': -0.2
              },
              'body': {
                'size': 16,
                'weight': 400,
                'height': 1.5,
                'letterSpacing': 0
              },
              'label': {
                'size': 14,
                'weight': 500,
                'height': 1.4,
                'letterSpacing': 0.2
              },
              'caption': {
                'size': 12,
                'weight': 400,
                'height': 1.3,
                'letterSpacing': 0.1
              },
              'mono': {
                'size': 14,
                'weight': 400,
                'height': 1.4,
                'letterSpacing': 0
              },
            },
          },
        },
      },
    };
  }
}
