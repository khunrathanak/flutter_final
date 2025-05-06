import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

class CartButton extends StatelessWidget {
  final Product product;
  const CartButton({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final quantity = cartProvider.getQuantity(product);

    return quantity > 0
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                color: Colors.blue,
                onPressed: () => cartProvider.decrease(product),
              ),
              Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                color: Colors.blue,
                onPressed: () => cartProvider.increase(product),
              ),
            ],
          )
        : ElevatedButton(
            onPressed: () => cartProvider.addToCart(product),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Add to Cart",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
  }
}
