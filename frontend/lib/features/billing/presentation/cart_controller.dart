import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/data/product.dart';

class CartLine {
  CartLine(this.product, this.quantity);
  final Product product;
  int quantity;
}

/// Cart state. Note: authoritative totals come from the backend on checkout;
/// these client-side figures are an estimate for display only.
class CartController extends StateNotifier<List<CartLine>> {
  CartController() : super([]);

  void add(Product p) {
    final existing = state.indexWhere((l) => l.product.id == p.id);
    if (existing >= 0) {
      final copy = [...state];
      copy[existing].quantity++;
      state = copy;
    } else {
      state = [...state, CartLine(p, 1)];
    }
  }

  void setQuantity(String productId, int qty) {
    if (qty <= 0) return remove(productId);
    state = [
      for (final l in state)
        if (l.product.id == productId) CartLine(l.product, qty) else l,
    ];
  }

  void remove(String productId) =>
      state = state.where((l) => l.product.id != productId).toList();

  void clear() => state = [];

  List<Map> toOrderItems() =>
      state.map((l) => {'productId': l.product.id, 'quantity': l.quantity}).toList();
}

final cartProvider =
    StateNotifierProvider<CartController, List<CartLine>>((ref) => CartController());

/// Global tax used only for the client-side estimate.
final globalTaxProvider = StateProvider<double>((ref) => 0);

double estimatedSubtotal(List<CartLine> lines) =>
    lines.fold(0, (s, l) => s + l.product.price * l.quantity);

double estimatedTax(List<CartLine> lines, double globalTax) => lines.fold(
      0,
      (s, l) => s + l.product.price * l.quantity * ((l.product.taxPercentage ?? globalTax) / 100),
    );
