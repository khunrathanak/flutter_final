import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/product.dart'; // Import Product model

class ProductProvider extends ChangeNotifier {
  List<Product> _allProducts = [];
  List<Product> _trendingProducts = [];
  // 3. Incompatible Ingredients Data
static const Map<String, List<String>> _incompatibleIngredients = {
  'retinol': ['aha', 'bha', 'vitamin c', 'benzoyl peroxide', 'salicylic acid', 'sulfur', 'niacinamide'],
  'tretinoin': ['benzoyl peroxide', 'aha', 'bha', 'vitamin c', 'salicylic acid', 'sulfur'],
  'aha': ['retinol', 'tretinoin', 'benzoyl peroxide', 'ascorbic acid', 'niacinamide'],
  'bha': ['retinol', 'tretinoin', 'benzoyl peroxide', 'ascorbic acid', 'niacinamide'],
  'salicylic acid': ['retinol', 'tretinoin', 'benzoyl peroxide', 'ascorbic acid', 'niacinamide'],
  'vitamin c': ['retinol', 'tretinoin', 'niacinamide', 'aha', 'bha', 'salicylic acid'],
  'ascorbic acid': ['retinol', 'tretinoin', 'niacinamide', 'aha', 'bha', 'salicylic acid'],
  'niacinamide': ['vitamin c', 'ascorbic acid', 'aha', 'bha', 'salicylic acid'],
  'benzoyl peroxide': ['retinol', 'tretinoin', 'aha', 'bha', 'salicylic acid', 'ascorbic acid', 'vitamin c'],
  'sulfur': ['retinol', 'tretinoin', 'benzoyl peroxide'],
  'peptides': ['aha', 'bha', 'ascorbic acid', 'vitamin c'],
  'hyaluronic acid': [], // generally compatible with all
  'ceramides': [], // generally compatible with all
  'squalane': [], // generally compatible with all
  'zinc': ['ascorbic acid', 'vitamin c'],
  'resorcinol': ['retinol', 'tretinoin'],
  'peroxide': ['retinol', 'tretinoin', 'aha', 'bha', 'salicylic acid'],
  'alcohol': ['retinol', 'tretinoin', 'aha', 'bha'],
  'clay': ['retinol', 'aha', 'bha'], // when overly drying
};

  List<Product> get trendingProducts => _trendingProducts;
  List<Product> get products => _allProducts; // Expose all products


  Future<void> loadProductsFromJson() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/products.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      _allProducts = jsonData.map((item) {
        return Product(
          name: item['name'] as String,
          brand: item['brand'] as String,
          type: item['type'] as String, // Use 'type' here
          image: item['image'] as String,
          ingredients: item['ingredients'] as String,
          safety: item['safety'] as String,
          oily: item['oily'] as int == 1,
          dry: item['dry'] as int == 1,
          sensitive: item['sensitive'] as int == 1,
          comedogenic: item['comedogenic'] as int == 1,
          acneFighting: item['acne_fighting'] as int == 1,
          antiAging: item['anti_aging'] as int == 1,
          brightening: item['brightening'] as int == 1,
          uvProtection: item['uv'] as int == 1,
          price: (item['price'] as num).toDouble(),
       
        );
      }).toList();
      _selectTrendingProducts();
      notifyListeners();
    } catch (e) {
      print('Error loading products: $e');
      // Consider more user-friendly error handling
    }
  }

  void _selectTrendingProducts() {
    final random = Random();
    List<Product> selectedProducts = [];
    Set<int> usedIndices = {};
    const numberOfTrendingProducts = 5; // You can adjust this number
    while (selectedProducts.length < numberOfTrendingProducts && selectedProducts.length < _allProducts.length) {
      int randomIndex = random.nextInt(_allProducts.length);
      if (!usedIndices.contains(randomIndex)) {
        selectedProducts.add(_allProducts[randomIndex]);
        usedIndices.add(randomIndex);
      }
    }
    _trendingProducts = selectedProducts;
  }

  // Function to check product compatibility
  bool areProductsCompatible(Product product1, Product product2) {
    // Get ingredients for both products, convert to lowercase and split by semicolon
    final ingredients1 = product1.ingredients.toLowerCase().split(';');
    final ingredients2 = product2.ingredients.toLowerCase().split(';');

    // Check for each ingredient in product1
    for (final ingredient1 in ingredients1) {
      //if ingredient1 is in the incompatibility list
      if (_incompatibleIngredients.containsKey(ingredient1.trim())) {
        //get the incompatible ingredients for ingredient1
        final incompatibleWith = _incompatibleIngredients[ingredient1.trim()]!;
        // Check if any of the incompatible ingredients are in product2
        for (final incompatibleIngredient in incompatibleWith) {
          if (ingredients2.contains(incompatibleIngredient.trim())) {
            return false; // Incompatible
          }
        }
      }
    }
    // Check the other way around as well.
    for (final ingredient2 in ingredients2) {
      //if ingredient2 is in the incompatibility list
      if (_incompatibleIngredients.containsKey(ingredient2.trim())) {
        //get the incompatible ingredients for ingredient2
        final incompatibleWith = _incompatibleIngredients[ingredient2.trim()]!;
        // Check if any of the incompatible ingredients are in product1
        for (final incompatibleIngredient in incompatibleWith) {
          if (ingredients1.contains(incompatibleIngredient.trim())) {
            return false; // Incompatible
          }
        }
      }
    }

    return true; // Compatible
  }

  ProductProvider() {
    loadProductsFromJson();
  }
}

