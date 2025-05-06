import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import 'checkout.dart';

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
      appBar: AppBar(
        title: const Text("Your Cart", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                "Your cart is empty.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: items.entries.map((entry) {
                        final Product product = entry.key;
                        final int quantity = entry.value;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                                color: Colors.black.withOpacity(0.05),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // 35% for the image
                              Expanded(
                                flex: 35,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      product.image,
                                      height: 100, // Set a maximum height
                                      width: double.infinity, // Ensure it takes full width
                                      fit: BoxFit.cover, // Adjust the fit
                                      errorBuilder: (context, error, stackTrace) => const Center(child: Text('Failed to load image')),
                                    ),
                                  ),
                                ),
                              ),

                              // 65% for the product info and quantity adjustment
                              Expanded(
                                flex: 65, // 65% of screen width
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product Name (Row 1)
                                      Text(
                                        product.name,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                        maxLines: 1, // Ensure name doesn't overflow
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      // Product Price (Row 2)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Text(
                                          "Price: \$${product.price.toStringAsFixed(2)}",
                                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                        ),
                                      ),
                                      // Quantity adjustment and Total Price (Row 3)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start, 
                                        crossAxisAlignment: CrossAxisAlignment.center, 
                                        children: [
                                          // Quantity Adjustment (Left Column)
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, size: 24),
                                                onPressed: () => cart.decrease(product),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                child: Text(
                                                  '$quantity',
                                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline, size: 24),
                                                onPressed: () => cart.increase(product),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                          // Total Price (Right Column)
                                          const Spacer(), // To push the total price to the right
                                          Text(
                                            "\$${(quantity * product.price).toStringAsFixed(2)}",
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, -2),
                        blurRadius: 8,
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Total: \$${total.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
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

