import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../orders/data/orders_repository.dart';

const _methods = {
  'CASH': 'Cash',
  'UPI': 'UPI',
  'CREDIT_CARD': 'Credit Card',
  'DEBIT_CARD': 'Debit Card',
};

class PaymentDialog extends ConsumerStatefulWidget {
  const PaymentDialog({super.key, required this.order});
  final Map order;
  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  String _method = 'CASH';
  late final _amount = TextEditingController(text: widget.order['grandTotal'].toString());
  bool _saving = false;

  Future<void> _pay() async {
    setState(() => _saving = true);
    try {
      await ref.read(ordersRepositoryProvider).pay(
            orderId: widget.order['id'] as String,
            amount: double.parse(_amount.text),
            method: _method,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Payment — ${widget.order['invoiceNumber']}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Grand Total: ₹${widget.order['grandTotal']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Payment method'),
            items: _methods.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _method = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount received'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _pay, child: const Text('Confirm Payment')),
      ],
    );
  }
}
