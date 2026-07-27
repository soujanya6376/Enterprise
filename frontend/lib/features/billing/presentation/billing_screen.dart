import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_toggle.dart';
import '../../products/data/products_repository.dart';
import '../../orders/data/orders_repository.dart';
import 'cart_controller.dart';
import 'payment_dialog.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});
  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  String _search = '';

  Future<void> _checkout() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;
    try {
      final order = await ref.read(ordersRepositoryProvider).create(
            ref.read(cartProvider.notifier).toOrderItems(),
          );
      if (!mounted) return;
      final paid = await showDialog<bool>(
        context: context,
        builder: (_) => PaymentDialog(order: order),
      );
      if (paid == true) {
        ref.read(cartProvider.notifier).clear();
        final orderId = order['id'] as String;
        final url = ref.read(ordersRepositoryProvider).thermalUrl(orderId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Payment recorded'),
            action: SnackBarAction(label: 'Print', onPressed: () => launchUrl(Uri.parse(url))),
          ));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider(_search));
    final cart = ref.watch(cartProvider);
    final wide = MediaQuery.of(context).size.width > 800;
    final t = context.tokens;

    final grid = Column(
      children: [
        Padding(
          padding: EdgeInsets.all(t.spacing.step(3)),
          child: TextField(
            decoration: const InputDecoration(hintText: 'Search products', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: products.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) => GridView.builder(
              padding: EdgeInsets.all(t.spacing.step(3)),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 0.85,
                crossAxisSpacing: t.spacing.step(3),
                mainAxisSpacing: t.spacing.step(3),
              ),
              itemCount: items.where((p) => p.isActive).length,
              itemBuilder: (_, i) {
                final p = items.where((p) => p.isActive).toList()[i];
                return InkWell(
                  onTap: () => ref.read(cartProvider.notifier).add(p),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: p.imageUrl != null
                              ? Image.network(p.imageUrl!, fit: BoxFit.cover)
                              : Container(color: t.color.background.surface,
                                  child: Icon(Icons.fastfood, size: 36, color: t.color.content.muted)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(t.spacing.sm),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge),
                            Text('₹${p.price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
                          ]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );

    final cartPanel = _CartPanel(onCheckout: _checkout);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        actions: [
          const ThemeModeToggle(),
          if (!wide)
            Stack(children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => showModalBottomSheet(
                  context: context, isScrollControlled: true,
                  builder: (_) => SizedBox(height: MediaQuery.of(context).size.height * 0.8, child: cartPanel)),
              ),
              if (cart.isNotEmpty)
                Positioned(right: 8, top: 8, child: CircleAvatar(radius: 8, child: Text('${cart.length}', style: TextStyle(fontSize: t.typography.caption.size)))),
            ]),
        ],
      ),
      body: wide
          ? Row(children: [
              Expanded(flex: 2, child: grid),
              SizedBox(width: 340, child: Card(margin: EdgeInsets.all(t.spacing.sm), child: cartPanel)),
            ])
          : grid,
    );
  }
}

class _CartPanel extends ConsumerWidget {
  const _CartPanel({required this.onCheckout});
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final globalTax = ref.watch(globalTaxProvider);
    final subtotal = estimatedSubtotal(cart);
    final tax = estimatedTax(cart, globalTax);
    final t = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(t.spacing.step(3)),
          child: Text('Cart', style: textTheme.titleLarge),
        ),
        Expanded(
          child: cart.isEmpty
              ? const Center(child: Text('Tap products to add'))
              : ListView(
                  children: [
                    for (final l in cart)
                      ListTile(
                        title: Text(l.product.name),
                        subtitle: Text('₹${l.product.price.toStringAsFixed(2)}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => ref.read(cartProvider.notifier).setQuantity(l.product.id, l.quantity - 1)),
                          Text('${l.quantity}'),
                          IconButton(icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => ref.read(cartProvider.notifier).setQuantity(l.product.id, l.quantity + 1)),
                        ]),
                      ),
                  ],
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: EdgeInsets.all(t.spacing.step(3)),
          child: Column(children: [
            _row(context, 'Subtotal', subtotal),
            _row(context, 'Tax (est.)', tax),
            const Divider(),
            _row(context, 'Grand Total', subtotal + tax, bold: true),
            SizedBox(height: t.spacing.step(3)),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: cart.isEmpty ? null : onCheckout,
                icon: const Icon(Icons.payment),
                label: const Text('Checkout'),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, double value, {bool bold = false}) {
    final textTheme = Theme.of(context).textTheme;
    final style = bold ? textTheme.titleMedium : textTheme.bodyMedium;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.tokens.spacing.xs / 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: style),
        Text('₹${value.toStringAsFixed(2)}', style: style),
      ]),
    );
  }
}
