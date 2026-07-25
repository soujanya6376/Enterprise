import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

final _usersProvider = FutureProvider<List<Map>>((ref) async {
  final res = await ref.watch(dioProvider).get('/users', queryParameters: {'limit': 100});
  return (res.data['data'] as List).cast<Map>();
});

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  Future<void> _createUser(BuildContext context, WidgetRef ref) async {
    final created = await showDialog<bool>(context: context, builder: (_) => const _UserFormDialog());
    if (created == true) ref.invalidate(_usersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(_usersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createUser(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Create User'),
      ),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => ListView(
          children: [
            for (final u in items)
              ListTile(
                leading: CircleAvatar(child: Text((u['username'] as String).characters.first.toUpperCase())),
                title: Text(u['username'] as String),
                subtitle: Text('${u['email']} · ${u['role']['name']}'),
                trailing: Icon(u['isActive'] == true ? Icons.check_circle : Icons.block,
                    color: u['isActive'] == true ? Colors.green : Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserFormDialog extends ConsumerStatefulWidget {
  const _UserFormDialog();
  @override
  ConsumerState<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'USER';
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).post('/users', data: {
        'username': _username.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'roleName': _role,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create User'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: _username, decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => (v == null || v.length < 3) ? 'Min 3 chars' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Invalid email' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'USER', child: Text('Cashier (USER)')),
                DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Create')),
      ],
    );
  }
}
