import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_toggle.dart';
import '../domain/theme_admin_providers.dart';
import '../domain/theme_draft.dart';
import 'widgets/token_field_group.dart';
import 'widgets/theme_preview_pane.dart';

/// Admin → Appearance → Themes → (theme). The token editor.
///
/// Route: /admin/appearance/themes/:id (ADMIN only).
///
/// Layout is deliberately split: fields on the left, a live preview on the
/// right, so an admin sees the result of a colour change before committing it
/// to every till in the shop. On narrow screens the preview collapses into a
/// tab, since a phone can't usefully show both.
class ThemeEditorPage extends ConsumerStatefulWidget {
  const ThemeEditorPage({super.key, required this.themeId});
  final String themeId;

  @override
  ConsumerState<ThemeEditorPage> createState() => _ThemeEditorPageState();
}

class _ThemeEditorPageState extends ConsumerState<ThemeEditorPage> {
  ThemeDraft? _draft;
  Brightness _editingMode = Brightness.light;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final source = ref.watch(themeDetailProvider(widget.themeId));

    return source.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Theme'), actions: const [ThemeModeToggle()]),
        body: Center(child: Text('Could not load this theme. $err')),
      ),
      data: (theme) {
        final draft = _draft ??= ThemeDraft.from(theme);
        final isWide = MediaQuery.sizeOf(context).width >= 900;

        return Scaffold(
          appBar: AppBar(
            title: Text(theme.name),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _ModeTabs(
                mode: _editingMode,
                onChanged: (m) => setState(() => _editingMode = m),
              ),
            ),
            actions: [
              if (theme.livePlatforms.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(right: t.spacing.sm),
                  child: TextButton.icon(
                    onPressed: _duplicate,
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Duplicate'),
                  ),
                ),
              FilledButton(
                onPressed: draft.isDirty && !_saving ? _save : null,
                child: Text(_saving ? 'Saving…' : 'Save changes'),
              ),
              SizedBox(width: t.spacing.md),
              const ThemeModeToggle(),
            ],
          ),
          body: Column(
            children: [
              if (theme.livePlatforms.isNotEmpty)
                _LiveBanner(platforms: theme.livePlatforms),
              Expanded(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: _fields(draft)),
                          VerticalDivider(width: t.borderWidth.hairline),
                          Expanded(flex: 2, child: ThemePreviewPane(draft: draft, mode: _editingMode)),
                        ],
                      )
                    : DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            const TabBar(tabs: [Tab(text: 'Tokens'), Tab(text: 'Preview')]),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _fields(draft),
                                  ThemePreviewPane(draft: draft, mode: _editingMode),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fields(ThemeDraft draft) {
    final t = context.tokens;
    final mode = draft.mode(_editingMode);

    return ListView(
      padding: EdgeInsets.all(t.spacing.lg),
      children: [
        TokenFieldGroup.color(
          title: 'Background',
          caption: 'Surfaces the app paints behind content.',
          values: mode.backgroundColors,
          onChanged: (key, value) => setState(() => draft.setBackgroundColor(_editingMode, key, value)),
        ),
        TokenFieldGroup.color(
          title: 'Content',
          caption: 'Text and icon colours. Check contrast against Background.',
          values: mode.contentColors,
          onChanged: (key, value) => setState(() => draft.setContentColor(_editingMode, key, value)),
        ),
        TokenFieldGroup.color(
          title: 'Border',
          caption: 'Dividers, outlines and focus rings.',
          values: mode.borderColors,
          onChanged: (key, value) => setState(() => draft.setBorderColor(_editingMode, key, value)),
        ),
        TokenFieldGroup.number(
          title: 'Spacing',
          caption: 'The padding scale. Step 4 is the app-wide default gap.',
          values: mode.spacing,
          min: 0,
          max: 256,
          onChanged: (key, value) => setState(() => draft.setSpacing(_editingMode, key, value)),
        ),
        TokenFieldGroup.number(
          title: 'Corner radius',
          caption: 'Applied to cards, inputs, buttons and dialogs.',
          values: mode.radius,
          min: 0,
          max: 999,
          onChanged: (key, value) => setState(() => draft.setRadius(_editingMode, key, value)),
        ),
        TokenFieldGroup.number(
          title: 'Border width',
          caption: 'Hairline is the default outline; thick marks focus.',
          values: mode.borderWidth,
          min: 0,
          max: 16,
          onChanged: (key, value) => setState(() => draft.setBorderWidth(_editingMode, key, value)),
        ),
        TokenFieldGroup.typography(
          title: 'Typography',
          caption: 'Font families and the size/weight scale.',
          families: mode.fontFamilies,
          scale: mode.typeScale,
          onFamilyChanged: (role, value) =>
              setState(() => draft.setFontFamily(_editingMode, role, value)),
          onScaleChanged: (role, field, value) =>
              setState(() => draft.setTypeScale(_editingMode, role, field, value)),
        ),
        TokenFieldGroup.number(
          title: 'Elevation',
          caption: 'Shadow depth for raised surfaces.',
          values: mode.elevation,
          min: 0,
          max: 48,
          onChanged: (key, value) => setState(() => draft.setElevation(_editingMode, key, value)),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(themeAdminServiceProvider).updateTokens(widget.themeId, draft.toJson());
      ref.invalidate(themeDetailProvider(widget.themeId));
      setState(() => _draft = null); // reload clean from the server
      messenger.showSnackBar(const SnackBar(content: Text('Theme saved')));
    } on TokenValidationFailure catch (failure) {
      // The API returns every bad field at once; show them all rather than
      // making the admin fix one per attempt.
      messenger.showSnackBar(
        SnackBar(
          content: Text('${failure.issues.length} token(s) need fixing:\n'
              '${failure.issues.take(5).join('\n')}'),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (err) {
      messenger.showSnackBar(SnackBar(content: Text('Could not save this theme. $err')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _duplicate() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NameDialog(title: 'Duplicate theme'),
    );
    if (name == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final copy = await ref.read(themeAdminServiceProvider).duplicate(widget.themeId, name);
      ref.invalidate(themeListProvider);
      messenger.showSnackBar(SnackBar(content: Text('Created "${copy.name}"')));
    } catch (err) {
      messenger.showSnackBar(SnackBar(content: Text('Could not duplicate this theme. $err')));
    }
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.mode, required this.onChanged});
  final Brightness mode;
  final ValueChanged<Brightness> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.spacing.md, vertical: t.spacing.xs),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<Brightness>(
          segments: const [
            ButtonSegment(value: Brightness.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
            ButtonSegment(value: Brightness.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
          ],
          selected: {mode},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ),
    );
  }
}

/// Editing a theme that's already live changes those platforms on next fetch.
/// Say so plainly and point at the safe alternative.
class _LiveBanner extends StatelessWidget {
  const _LiveBanner({required this.platforms});
  final List<String> platforms;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: t.spacing.lg, vertical: t.spacing.sm),
      color: t.color.background.warning.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: t.color.background.warning),
          SizedBox(width: t.spacing.sm),
          Expanded(
            child: Text(
              'This theme is live on ${platforms.join(', ')}. Saving changes it there. '
              'Duplicate it first to experiment safely.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title});
  final String title;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim().isEmpty ? null : v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            Navigator.of(context).pop(value.isEmpty ? null : value);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
