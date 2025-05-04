import 'package:flutter/material.dart';
import '../utils/product_loader.dart';
import '../widgets/product_card.dart';
import '../models/product.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Skincare Market")),
      body: SingleChildScrollView(
        child: FutureBuilder<List<Product>>(
          future: ProductLoader.loadProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No products found."));
            } else {
              final products = snapshot.data!;
              return Column(
                children: products.map((product) {
                  return ProductCard(product: product);
                }).toList(),
              );
            }
          },
        ),
      ),
    );
  }
}
