import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Tax Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Global Tax', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Applied to products without a tax override.'),
            const SizedBox(height: 16),
            tax.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (v) {
                if (_controller.text.isEmpty) _controller.text = v.toStringAsFixed(2);
                return TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Global tax %', suffixText: '%'),
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _saving ? null : _save, child: const Text('Save')),
            const SizedBox(height: 24),
            const Text('Per-product tax overrides are set on each product (blank = use global).'),
          ]),
        ),
      ),
    );
  }
}
