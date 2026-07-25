import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/billing/presentation/billing_screen.dart';
import '../../features/orders/presentation/order_history_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loggingIn = state.matchedLocation == '/login';
      if (!auth.isLoggedIn) return loggingIn ? null : '/login';
      // Logged in but on login page → send to role home.
      if (loggingIn) return auth.isAdmin ? '/admin' : '/billing';
      // Cashiers cannot access admin routes.
      if (state.matchedLocation.startsWith('/admin') && !auth.isAdmin) return '/billing';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminShell()),
      GoRoute(path: '/billing', builder: (_, __) => const _CashierShell()),
    ],
  );
});

/// Simple cashier shell: billing + order history tabs.
class _CashierShell extends ConsumerStatefulWidget {
  const _CashierShell();
  @override
  ConsumerState<_CashierShell> createState() => _CashierShellState();
}

class _CashierShellState extends ConsumerState<_CashierShell> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [const BillingScreen(), const OrderHistoryScreen()][_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Billing'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
        ],
      ),
    );
  }
}
