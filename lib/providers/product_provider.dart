import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/product.dart'; // Import Product model

class ProductProvider extends ChangeNotifier {
  List<Product> _allProducts = [];
  List<Product> _trendingProducts = [];

  // ... (your existing incompatibleIngredients map) ...
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
    'hyaluronic acid': [],
    'ceramides': [],
    'squalane': [],
    'zinc': ['ascorbic acid', 'vitamin c'],
    'resorcinol': ['retinol', 'tretinoin'],
    'peroxide': ['retinol', 'tretinoin', 'aha', 'bha', 'salicylic acid'],
    'alcohol': ['retinol', 'tretinoin', 'aha', 'bha'],
    'clay': ['retinol', 'aha', 'bha'],
  };


  List<Product> get trendingProducts => _trendingProducts;
  List<Product> get products => _allProducts;

  ProductProvider() {
    loadProductsFromJson();
  }

  Future<void> loadProductsFromJson() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/products.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      _allProducts = jsonData.map((item) {
        return Product.fromJson(item); // Use your Product.fromJson factory
      }).toList();
      _selectTrendingProducts();
      notifyListeners();
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  void _selectTrendingProducts() {
    if (_allProducts.isEmpty) return;
    final random = Random();
    List<Product> selectedProducts = [];
    Set<int> usedIndices = {};
    const numberOfTrendingProducts = 5;
    while (selectedProducts.length < numberOfTrendingProducts && selectedProducts.length < _allProducts.length) {
      int randomIndex = random.nextInt(_allProducts.length);
      if (!usedIndices.contains(randomIndex)) {
        selectedProducts.add(_allProducts[randomIndex]);
        usedIndices.add(randomIndex);
      }
    }
    _trendingProducts = selectedProducts;
  }

  bool areProductsCompatible(Product product1, Product product2) {
    // ... (your existing compatibility logic) ...
    final ingredients1 = product1.ingredients.toLowerCase().split(';');
    final ingredients2 = product2.ingredients.toLowerCase().split(';');
    for (final ingredient1 in ingredients1) {
      if (_incompatibleIngredients.containsKey(ingredient1.trim())) {
        final incompatibleWith = _incompatibleIngredients[ingredient1.trim()]!;
        for (final incompatibleIngredient in incompatibleWith) {
          if (ingredients2.contains(incompatibleIngredient.trim())) {
            return false;
          }
        }
      }
    }
    for (final ingredient2 in ingredients2) {
      if (_incompatibleIngredients.containsKey(ingredient2.trim())) {
        final incompatibleWith = _incompatibleIngredients[ingredient2.trim()]!;
        for (final incompatibleIngredient in incompatibleWith) {
          if (ingredients1.contains(incompatibleIngredient.trim())) {
            return false;
          }
        }
      }
    }
    return true;
  }

  // --- NEW RECOMMENDATION LOGIC ---
  List<Product> getRecommendedProducts(Map<String, dynamic> skinAnalysisApiResult) {
    if (_allProducts.isEmpty) {
      print("Product list is empty. Load products first.");
      return [];
    }

    // Define a minimum confidence threshold for API results
    const double minConfidence = 0.5; // You can adjust this value

    // Helper function to get value from API result if confidence is met
    int _getConfidentValue(Map<String, dynamic>? data, String key) {
      if (data == null || data[key] == null || data[key] is! Map) {
        // print("Warning: Data for key '$key' is null or not a map: ${data?[key]}");
        return 0; // Default to 0 (no issue / not present)
      }
      final item = data[key] as Map<String, dynamic>;
      final confidence = (item['confidence'] ?? 0.0) as num;
      final value = (item['value'] ?? 0) as num;

      if (confidence.toDouble() >= minConfidence) {
        return value.toInt();
      }
      return 0; // Confidence not met, treat as no issue
    }

    // Determine skin needs based on API response
    bool hasAcne = _getConfidentValue(skinAnalysisApiResult, 'acne') == 1;

    bool hasAgingSigns =
        _getConfidentValue(skinAnalysisApiResult, 'forehead_wrinkle') == 1 ||
        _getConfidentValue(skinAnalysisApiResult, 'eye_finelines') == 1 ||
        _getConfidentValue(skinAnalysisApiResult, 'crows_feet') == 1 ||
        _getConfidentValue(skinAnalysisApiResult, 'glabella_wrinkle') == 1 ||
        _getConfidentValue(skinAnalysisApiResult, 'nasolabial_fold') == 1;

    bool hasSkinSpots = _getConfidentValue(skinAnalysisApiResult, 'skin_spot') == 1;
    // (You could also consider 'dark_circle' for brightening if desired)
    // bool hasDarkCircles = _getConfidentValue(skinAnalysisApiResult, 'dark_circle') == 1;

    // Determine if UV protection is generally recommended
    // UV protection is good for everyone, but especially if there are concerns
    // like aging or spots, or if using active ingredients like retinol, AHAs/BHAs.
    // For this logic, let's say UV protection is recommended if any of the specific issues are present.
    bool needsUvProtection = hasAcne || hasAgingSigns || hasSkinSpots;


    print("--- Skin Analysis Needs ---");
    print("Has Acne: $hasAcne");
    print("Has Aging Signs: $hasAgingSigns");
    print("Has Skin Spots: $hasSkinSpots");
    print("Needs UV Protection (derived): $needsUvProtection");
    print("---------------------------");


    List<Product> recommendedProducts = [];

    for (var product in _allProducts) {
      bool isSuitable = false;

      // 1. Check for Acne Fighting
      if (hasAcne && product.acneFighting) {
        isSuitable = true;
      }

      // 2. Check for Anti-Aging
      if (hasAgingSigns && product.antiAging) {
        isSuitable = true;
      }

      // 3. Check for Brightening
      if (hasSkinSpots && product.brightening) {
        isSuitable = true;
      }

      // 4. Check for UV Protection
      // If UV protection is generally needed (due to other issues) AND the product provides it
      if (needsUvProtection && product.uvProtection) {
        // This makes a product suitable if it offers UV and UV is needed,
        // even if it doesn't match other specific criteria like acne/aging/brightening.
        // Or, it reinforces the suitability if it already matched.
        isSuitable = true;
      }

      if (isSuitable) {
        // Avoid adding duplicates if a product matches multiple criteria
        if (!recommendedProducts.any((p) => p.name == product.name && p.brand == product.brand)) {
          recommendedProducts.add(product);
        }
      }
    }
    print("Found ${recommendedProducts.length} recommended products.");
    return recommendedProducts;
  }
}