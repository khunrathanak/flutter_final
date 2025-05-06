import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../screens/product_check.dart';
import '../screens/marketplace.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final trendingProducts = productProvider.trendingProducts;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shortcut Buttons
          Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align tops if heights differ
              children: [
                // --- First Shortcut Card ---
                Expanded( // Expanded MUST be a direct child of Row
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductCompatibilityApp(),
                        ),
                      );
                    },
                    // The actual card widget is the child of GestureDetector
                    child: _ShortcutCard(
                      icon: Icons.verified_user,
                      title: 'Compatibility Check',
                      subtitle: 'Easily check products with just a few click', // Shortened subtitle for space
                      backgroundColor: Colors.blue.shade50,
                    ),
                  ),
                ),
                const SizedBox(width: 12), // Spacing between cards
                // --- Second Shortcut Card ---
                Expanded( // Expanded MUST be a direct child of Row
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MarketplaceScreen(),
                        ),
                      );
                    },
                    // The actual card widget is the child of GestureDetector
                    child: _ShortcutCard(
                      icon: Icons.store,
                      title: 'Marketplace',
                      subtitle: 'Find millions of products in one place', // Shortened subtitle
                      backgroundColor: Colors.blue.shade50, // Changed color for distinction
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 30),

          // Trending Products
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Trending Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'See All',
                style: TextStyle(color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Product List
          SizedBox(
            height: 220,
            child: trendingProducts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: trendingProducts.length,
                    itemBuilder: (context, index) {
                      final product = trendingProducts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ProductCard(product: product),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 24), // Add some spacing below the product list

          // Blue Bottom Button
          Container(
            width: double.infinity, // Make it take the full width
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.blue, // Use a darker shade of blue
              borderRadius: BorderRadius.circular(12), // Add rounded corners
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Get Your Skin Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Personalize your skincare routine with our AI-powered skin analysis tool for product recommendations tailored to your unique needs.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Start Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24), // Add some spacing below the blue button
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;

  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 140, // Re-introduce the fixed height
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // Adjust font size if needed
              maxLines: 1, // Consider limiting to one line
              overflow: TextOverflow.ellipsis, // Handle overflow gracefully
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54), // Adjust font size if needed
              maxLines: 2, // Consider limiting to two lines
              overflow: TextOverflow.ellipsis, // Handle overflow gracefully
            ),
          ],
        ),
      ),
    );
  }
}