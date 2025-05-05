import 'package:flutter/material.dart';
import '../models/product.dart';

class SelectableProductCard extends StatelessWidget {
  final Product product;
  final Product? currentlySelectedProduct;
  final ValueChanged<Product> onProductSelected;

  const SelectableProductCard({
    super.key,
    required this.product,
    this.currentlySelectedProduct,
    required this.onProductSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentlySelectedProduct?.name == product.name;

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with constrained height
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox( // Wrap with SizedBox
              height: 120, // Adjust this value as needed
              width: double.infinity, // Make it take the full width
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.broken_image));
                  },
                ),
              ),
            ),
          ),
          // Product Name and Price
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2, // Add maxLines to handle long names
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "\$${product.price.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      onProductSelected(product);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      textStyle: const TextStyle(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(isSelected ? 'Selected' : 'Select'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}