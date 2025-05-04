import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_button.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(product.image, height: 250),
            const SizedBox(height: 16),
            Text(product.brand, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(product.type, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Text("\$${product.price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 16),
            const Text("Ingredients:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(product.ingredients),
            const SizedBox(height: 20),
            CartButton(product: product),
          ],
        ),
      ),
    );
  }
}
