import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/selectable_product_card.dart'; // Import the new card

class ProductSelectionScreen extends StatelessWidget {
  final String productType;
  final List<Product> products;
  final ValueChanged<Product> onProductSelected;
  final Product? currentlySelectedProduct;

  const ProductSelectionScreen({
    super.key,
    required this.productType,
    required this.products,
    required this.onProductSelected,
    this.currentlySelectedProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select ${productType.toUpperCase()}'),
      ),
      body: products.isEmpty
          ? const Center(child: Text('No products available for this type.'))
          : SingleChildScrollView( // Make the entire screen scrollable
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double cardWidth = (constraints.maxWidth - 16) / 2; // Two cards with spacing
                return Wrap(
                  spacing: 16.0, // Horizontal space between cards
                  runSpacing: 16.0, // Vertical space between rows of cards
                  children: products.map((product) {
                    return SizedBox(
                      width: cardWidth,
                      child: SelectableProductCard(
                        product: product,
                        currentlySelectedProduct: currentlySelectedProduct,
                        onProductSelected: onProductSelected,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
    );
  }
}