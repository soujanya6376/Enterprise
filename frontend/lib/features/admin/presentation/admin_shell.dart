import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reports/presentation/dashboard_screen.dart';
import '../../products/presentation/products_screen.dart';
import '../../tax/presentation/tax_settings_screen.dart';
import '../../users/presentation/users_screen.dart';
import '../../orders/presentation/order_history_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});
  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  static const _dests = [
    (icon: Icons.dashboard, label: 'Dashboard'),
    (icon: Icons.inventory_2, label: 'Products'),
    (icon: Icons.percent, label: 'Tax'),
    (icon: Icons.people, label: 'Users'),
    (icon: Icons.receipt_long, label: 'Orders'),
  ];

  Widget get _body => const [
        DashboardScreen(),
        ProductsScreen(),
        TaxSettingsScreen(),
        UsersScreen(),
        OrderHistoryScreen(),
      ][_index];

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 760;
    if (wide) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 1100,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            leading: Column(children: [
              const SizedBox(height: 12),
              const Icon(Icons.point_of_sale, size: 32),
              const SizedBox(height: 12),
              IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: 'Logout'),
            ]),
            destinations: _dests
                .map((d) => NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _body),
        ]),
      );
    }
    return Scaffold(
      body: _body,
      drawer: Drawer(
        child: ListView(children: [
          const DrawerHeader(child: Center(child: Text('Admin', style: TextStyle(fontSize: 22)))),
          for (var i = 0; i < _dests.length; i++)
            ListTile(
              leading: Icon(_dests[i].icon),
              title: Text(_dests[i].label),
              selected: i == _index,
              onTap: () {
                setState(() => _index = i);
                Navigator.pop(context);
              },
            ),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: _logout),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _dests
            .map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label))
            .toList(),
      ),
    );
  }
}
