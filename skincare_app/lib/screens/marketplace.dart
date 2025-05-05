import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/product_card.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import 'dart:math';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToSeeAll(BuildContext context, String category) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final allProducts = productProvider.products;
    final categoryProducts = allProducts.where((p) => p.type == category).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeeAllProductsScreen(
          category: category,
          products: categoryProducts,
        ),
      ),
    );
  }

  Widget _buildProductList(
      BuildContext context, String category, List<Product> products) {
    List<Product> displayedProducts = products.where((p) {
      final matchesCategory = p.type == category;
      final matchesQuery = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    if (displayedProducts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              category,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Text("No products found.",
                style: TextStyle(color: Colors.grey)),
          ),
        ],
      );
    }

    final random = Random();
    List<Product> shuffledProducts = List.from(displayedProducts);
    shuffledProducts.shuffle();
    int numberOfProductsToShow = min(5, shuffledProducts.length);
    displayedProducts = shuffledProducts.sublist(0, numberOfProductsToShow);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _navigateToSeeAll(context, category),
                child: const Text('See All', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayedProducts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ProductCard(product: displayedProducts[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final allProducts = productProvider.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _searchQuery.isNotEmpty ? Colors.blue : Colors.blue,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductList(context, 'serum', allProducts),
                  _buildProductList(context, 'sunscreen', allProducts),
                  _buildProductList(context, 'toner', allProducts),
                  _buildProductList(context, 'moisturizer', allProducts),
                  _buildProductList(context, 'cleanser', allProducts),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SeeAllProductsScreen extends StatelessWidget {
  final String category;
  final List<Product> products;

  const SeeAllProductsScreen(
      {super.key, required this.category, required this.products});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All $category Products',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        ),
      ),
    );
  }
}
