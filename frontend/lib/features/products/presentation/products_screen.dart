import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/product.dart';
import '../data/products_repository.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});
  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _search = '';

  Future<void> _openForm([Product? product]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ProductFormDialog(product: product),
    );
    if (saved == true) ref.invalidate(productsProvider(_search));
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider(_search));
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search products', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('No products'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = items[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: p.imageUrl != null ? NetworkImage(p.imageUrl!) : null,
                            child: p.imageUrl == null ? Text(p.name.characters.first) : null,
                          ),
                          title: Text(p.name),
                          subtitle: Text('₹${p.price.toStringAsFixed(2)} · tax ${p.taxPercentage?.toStringAsFixed(0) ?? "global"}%'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: p.isActive,
                                onChanged: (v) async {
                                  await ref.read(productsRepositoryProvider).setStatus(p.id, v);
                                  ref.invalidate(productsProvider(_search));
                                },
                              ),
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => _openForm(p)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductFormDialog extends ConsumerStatefulWidget {
  const _ProductFormDialog({this.product});
  final Product? product;
  @override
  ConsumerState<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _desc = TextEditingController(text: widget.product?.description);
  late final _price = TextEditingController(text: widget.product?.price.toString());
  late final _tax = TextEditingController(text: widget.product?.taxPercentage?.toString());
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = {
      'name': _name.text.trim(),
      'description': _desc.text.trim(),
      'price': double.parse(_price.text),
      if (_tax.text.trim().isNotEmpty) 'taxPercentage': double.parse(_tax.text),
    };
    final repo = ref.read(productsRepositoryProvider);
    try {
      widget.product == null ? await repo.create(body) : await repo.update(widget.product!.id, body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _desc, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              TextFormField(controller: _price, decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Enter a number' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _tax,
                  decoration: const InputDecoration(labelText: 'Tax % (blank = global)'),
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
