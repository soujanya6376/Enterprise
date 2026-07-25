import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

final _dashboardProvider = FutureProvider<Map>((ref) async {
  final dio = ref.watch(dioProvider);
  final results = await Future.wait([
    dio.get('/reports/dashboard'),
    dio.get('/reports/top-products', queryParameters: {'limit': 5}),
    dio.get('/reports/recent-orders', queryParameters: {'limit': 5}),
  ]);
  return {
    'summary': results[0].data,
    'top': (results[1].data as List).cast<Map>(),
    'recent': (results[2].data as List).cast<Map>(),
  };
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_dashboardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_dashboardProvider)),
      ]),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (d) {
          final s = d['summary'] as Map;
          final today = s['today'] as Map;
          final monthly = s['monthly'] as Map;
          final top = d['top'] as List;
          final recent = d['recent'] as List;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(spacing: 12, runSpacing: 12, children: [
                _card(context, 'Today Orders', '${today['ordersCount']}', Icons.receipt_long),
                _card(context, 'Today Revenue', '₹${today['revenue']}', Icons.payments),
                _card(context, 'Today Tax', '₹${today['taxCollected']}', Icons.account_balance),
                _card(context, 'Month Revenue', '₹${monthly['revenue']}', Icons.trending_up),
                _card(context, 'Month Tax', '₹${monthly['taxCollected']}', Icons.savings),
              ]),
              const SizedBox(height: 24),
              Text('Top Selling Products', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...top.map((p) => ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: Text(p['productName'] as String),
                    trailing: Text('${p['quantitySold']} sold · ₹${p['revenue']}'),
                  )),
              const SizedBox(height: 24),
              Text('Recent Orders', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...recent.map((o) => ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(o['invoiceNumber'] as String),
                    subtitle: Text(o['status'] as String),
                    trailing: Text('₹${o['grandTotal']}'),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, String label, String value, IconData icon) => SizedBox(
        width: 220,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  Text(value, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ),
        ),
      );
}
