import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/product_card.dart'; // Import your ProductCard

class RecommendationScreen extends StatelessWidget {
  final List<Product> products; // Now directly using the 'products' list

  const RecommendationScreen({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    // Group products by type
    final Map<String, List<Product>> productsByType = {};
    for (final product in products) {
      if (productsByType.containsKey(product.type)) {
        productsByType[product.type]!.add(product);
      } else {
        productsByType[product.type] = [product];
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Recommended Products")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: productsByType.entries.map((entry) {
            final productType = entry.key;
            final productList = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                  child: Text(
                    productType.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(
                  height: 250, // Adjust the height as needed for your cards
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: productList.length,
                    itemBuilder: (context, index) {
                      final product = productList[index];
                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: ProductCard(product: product),
                      );
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}