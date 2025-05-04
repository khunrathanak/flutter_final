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

    return Row(
      children: [
        if (quantity > 0) ...[
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => cartProvider.decrease(product),
          ),
          Text('$quantity'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => cartProvider.increase(product),
          ),
        ] else
          ElevatedButton(
            onPressed: () => cartProvider.addToCart(product),
            child: const Text("Add to Cart"),
          ),
      ],
    );
  }
}
