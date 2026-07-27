import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_toggle.dart';

final _globalTaxProvider = FutureProvider<double>((ref) async {
  final res = await ref.watch(dioProvider).get('/tax/global');
  return double.parse(res.data['percentage'].toString());
});

class TaxSettingsScreen extends ConsumerStatefulWidget {
  const TaxSettingsScreen({super.key});
  @override
  ConsumerState<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends ConsumerState<TaxSettingsScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).put('/tax/global', data: {'percentage': double.parse(_controller.text)});
      ref.invalidate(_globalTaxProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Global tax updated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tax = ref.watch(_globalTaxProvider);
    final t = context.tokens;
    return Scaffold(
      appBar: AppBar(title: const Text('Tax Settings'), actions: const [ThemeModeToggle()]),
      body: Padding(
        padding: EdgeInsets.all(t.spacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Global Tax', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: t.spacing.sm),
            Text('Applied to products without a tax override.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.color.content.secondary)),
            SizedBox(height: t.spacing.md),
            tax.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e', style: TextStyle(color: t.color.content.danger)),
              data: (v) {
                if (_controller.text.isEmpty) _controller.text = v.toStringAsFixed(2);
                return TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Global tax %', suffixText: '%'),
                );
              },
            ),
            SizedBox(height: t.spacing.md),
            FilledButton(onPressed: _saving ? null : _save, child: const Text('Save')),
            SizedBox(height: t.spacing.lg),
            Text('Per-product tax overrides are set on each product (blank = use global).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.color.content.secondary)),
          ]),
        ),
      ),
    );
  }
}
