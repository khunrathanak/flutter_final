import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final items = cart.items;

    double total = items.entries
        .map((entry) => entry.key.price * entry.value)
        .fold(0.0, (sum, item) => sum + item);

    return Scaffold(
      appBar: AppBar(title: const Text("Your Cart")),
      body: items.isEmpty
          ? const Center(child: Text("Cart is empty"))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: items.entries.map((entry) {
                      final Product product = entry.key;
                      final int quantity = entry.value;
                      return ListTile(
                        leading: Image.network(product.image, width: 50),
                        title: Text(product.name),
                        subtitle: Text("${quantity}x \$${product.price.toStringAsFixed(2)}"),
                        trailing: Text("\$${(quantity * product.price).toStringAsFixed(2)}"),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text("Total: \$${total.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Thank you!"),
                              content: const Text("Your order has been placed."),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    cart.clear(); // Clear cart after checkout
                                    Navigator.of(ctx).pop();
                                    Navigator.of(context).pop(); // Back to Home
                                  },
                                  child: const Text("OK"),
                                )
                              ],
                            ),
                          );
                        },
                        child: const Text("Proceed to Checkout"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
