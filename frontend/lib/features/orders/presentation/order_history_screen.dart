import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/orders_repository.dart';

final _historyProvider = FutureProvider.family<List<Map>, String>((ref, search) {
  return ref.watch(ordersRepositoryProvider).history(search: search);
});

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});
  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(_historyProvider(_search));
    final repo = ref.read(ordersRepositoryProvider);
    final df = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search invoice number', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: orders.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('No orders'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final o = items[i];
                        return ListTile(
                          title: Text(o['invoiceNumber'] as String),
                          subtitle: Text('${df.format(DateTime.parse(o['createdAt']))} · ${o['status']}'),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('₹${o['grandTotal']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.print),
                              tooltip: 'Reprint (thermal)',
                              onPressed: () => launchUrl(Uri.parse(repo.thermalUrl(o['id'] as String))),
                            ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf),
                              tooltip: 'PDF',
                              onPressed: () => launchUrl(Uri.parse(repo.pdfUrl(o['id'] as String))),
                            ),
                          ]),
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
