import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_toggle.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController(text: 'admin');
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authControllerProvider.notifier).login(_username.text.trim(), _password.text);
    if (ok && mounted) {
      final isAdmin = ref.read(authControllerProvider).isAdmin;
      context.go(isAdmin ? '/admin' : '/billing');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final t = context.tokens;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [ThemeModeToggle()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(t.spacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.point_of_sale, size: 56, color: t.color.background.accent),
                  SizedBox(height: t.spacing.sm),
                  Text('POS Billing', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: t.spacing.xl),
                  TextFormField(
                    controller: _username,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  SizedBox(height: t.spacing.md),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (state.error != null) ...[
                    SizedBox(height: t.spacing.md),
                    Text(state.error!, style: TextStyle(color: t.color.content.danger)),
                  ],
                  SizedBox(height: t.spacing.lg),
                  FilledButton(
                    onPressed: state.loading ? null : _submit,
                    child: state.loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
