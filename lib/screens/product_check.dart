import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skincare_marketplace/main.dart';
import '../widgets/selectable_product_card.dart'; 
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../screens/product_selection-screen.dart';


// 3. Incompatible Ingredients Data
const Map<String, List<String>> _incompatibleIngredients = {
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


// 4. Helper Functions
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

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentQuestionIndex = 0;
  final List<String> _allergies = [];
  String _skinType = '';
  RangeValues _budgetRange = const RangeValues(0, 100); // Initial budget range
  final Set<String> _selectedProductTypes = {};

  final List<String> _productTypeOptions = [
    'toner',
    'serum',
    'moisturizer',
    'sunscreen',
    'cleanser',
    'exfoliant',
    'eye cream',
    'mask',
  ];

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is your skin type?',
      'type': 'radio',
      'options': ['Oily', 'Dry', 'Combination (Oily & Dry)', 'Sensitive', 'Normal'],
      'answerKey': 'skinType',
    },
    {
      'question': 'Select any allergies you have:',
      'type': 'checkbox',
      'options': ['Fragrance', 'Parabens', 'Sulfates', 'Essential Oils', 'Nuts', 'Gluten', 'Alcohol'],
      'answerKey': 'allergies',
    },
    {
      'question': 'What is your preferred budget range for skincare products?',
      'type': 'rangeSlider',
      'answerKey': 'budget',
    },
    {
      'question': 'What types of products are you interested in?',
      'type': 'chip',
      'options': [
        'toner',
        'serum',
        'moisturizer',
        'sunscreen',
        'cleanser',
        'exfoliant',
        'eye cream',
        'mask'
      ],
      'answerKey': 'productTypes',
    },
    {
      'question': 'Do you have any specific skin concerns?',
      'type': 'checkbox',
      'options': ['Acne', 'Redness', 'Dark Spots', 'Fine Lines', 'Wrinkles', 'Dullness', 'Uneven Texture'],
      'answerKey': 'concerns', // You'll need to handle this in the ResultsScreen
    },
  ];

  void _handleRadioAnswer(String value) {
    setState(() {
      final currentQuestion = _questions[_currentQuestionIndex];
      if (currentQuestion['answerKey'] == 'skinType') {
        _skinType = value;
      }
    });
  }

  void _handleCheckboxAnswer(String value, bool? newValue) {
    setState(() {
      if (newValue == true) {
        _allergies.add(value);
      } else {
        _allergies.remove(value);
      }
    });
  }

  void _handleChipAnswer(String value, bool selected) {
    setState(() {
      if (selected) {
        _selectedProductTypes.add(value);
      } else {
        _selectedProductTypes.remove(value);
      }
    });
  }

  void _handleRangeSliderChanged(RangeValues values) {
    setState(() {
      _budgetRange = values;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitForm(context);
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _submitForm(BuildContext context) {
    if (_skinType.isEmpty && _questions.any((q) => q['answerKey'] == 'skinType')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer the skin type question.')),
      );
      return;
    }
    if (_selectedProductTypes.isEmpty && _questions.any((q) => q['answerKey'] == 'productTypes')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one product type.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          allergies: _allergies,
          skinType: _skinType,
          budget: '${_budgetRange.start.round()}-${_budgetRange.end.round()}', // Pass budget as a range string
          selectedProductTypes: _selectedProductTypes.toList(),
          // You might want to pass the 'concerns' as well if you plan to use them in filtering
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestionData = _questions[_currentQuestionIndex];
    final questionText = currentQuestionData['question'] as String;
    final questionType = currentQuestionData['type'] as String;
    final options = currentQuestionData['options'] as List<String>?;
    final totalQuestions = _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KESA Assessment'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / totalQuestions,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 20),
            Text(
              questionText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 15),
            if (questionType == 'radio' && options != null)
              ...options.map((option) {
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: currentQuestionData['answerKey'] == 'skinType' ? _skinType : null,
                  onChanged: (String? value) {
                    if (value != null) {
                      _handleRadioAnswer(value);
                    }
                  },
                  activeColor: Colors.blue,
                );
              }).toList(),
            if (questionType == 'checkbox' && options != null)
              ...options.map((option) {
                return CheckboxListTile(
                  title: Text(option),
                  value: _allergies.contains(option),
                  onChanged: (bool? value) {
                    _handleCheckboxAnswer(option, value);
                  },
                  activeColor: Colors.blue,
                  checkColor: Colors.white,
                );
              }).toList(),
            if (questionType == 'chip' && options != null)
              Wrap(
                spacing: 8.0,
                children: options.map((option) {
                  return ChoiceChip(
                    label: Text(option),
                    selected: _selectedProductTypes.contains(option),
                    onSelected: (selected) {
                      _handleChipAnswer(option, selected);
                    },
                    selectedColor: Colors.blue[200],
                    backgroundColor: Colors.grey[300],
                    labelStyle: TextStyle(color: _selectedProductTypes.contains(option) ? Colors.white : Colors.black),
                  );
                }).toList(),
              ),
            if (questionType == 'rangeSlider')
              RangeSlider(
                values: _budgetRange,
                min: 0,
                max: 200, // You can adjust the maximum budget
                divisions: 20,
                labels: RangeLabels(
                  '\$${_budgetRange.start.round()}',
                  '\$${_budgetRange.end.round()}',
                ),
                onChanged: (RangeValues values) {
                  _handleRangeSliderChanged(values);
                },
                activeColor: Colors.blue,
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back_ios_new, size: 16),
                      SizedBox(width: 4),
                      Text('Previous'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text(
                    _currentQuestionIndex < _questions.length - 1 ? 'Next' : 'Show Recommendations',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Question ${_currentQuestionIndex + 1}/$totalQuestions',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultsScreen extends StatefulWidget {
  final List<String> allergies;
  final String skinType;
  final String budget;
  final List<String> selectedProductTypes;

  const ResultsScreen({
    Key? key,
    required this.allergies,
    required this.skinType,
    required this.budget,
    required this.selectedProductTypes,
  }) : super(key: key);

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final Map<String, Product?> _selectedProducts = {};
  final Map<String, bool> _compatibilityStatus = {};
  final Map<String, List<Product>> _availableProductsByType = {};

  void _handleProductSelection(String productType, Product? product) {
    setState(() {
      _selectedProducts[productType] = product;
      _checkCompatibility();
    });
  }

  void _checkCompatibility() {
    _compatibilityStatus.clear();
    final selectedTypes = _selectedProducts.keys.toList();
    for (int i = 0; i < selectedTypes.length; i++) {
      for (int j = i + 1; j < selectedTypes.length; j++) {
        final type1 = selectedTypes[i];
        final type2 = selectedTypes[j];
        final product1 = _selectedProducts[type1];
        final product2 = _selectedProducts[type2];

        if (product1 != null && product2 != null) {
          final key1 = '$type1-$type2';
          final key2 = '$type2-$type1';
          if (!_compatibilityStatus.containsKey(key1) &&
              !_compatibilityStatus.containsKey(key2)) {
            final areCompatible = areProductsCompatible(product1, product2);
            _compatibilityStatus[key1] = areCompatible;
          }
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final productProvider =
    Provider.of<ProductProvider>(context, listen: false);
    List<Product> allProducts = productProvider.products;

    print('User Skin Type: ${widget.skinType}');
    print('User Allergies: ${widget.allergies}');
    print('User Budget: ${widget.budget}');
    print('Selected Product Types: ${widget.selectedProductTypes}');

    List<Product> filteredProducts = allProducts.where((product) {
      bool matchesSkinType =
          widget.skinType.toLowerCase() == 'all' ||
              (widget.skinType.toLowerCase() == 'oily' && product.oily) ||
              (widget.skinType.toLowerCase() == 'dry' && product.dry) ||
              (widget.skinType.toLowerCase() == 'combination (oily & dry)' && product.oily && product.dry) ||
              (widget.skinType.toLowerCase() == 'sensitive' && product.sensitive) ||
              (widget.skinType.toLowerCase() == 'normal' && !product.oily && !product.dry && !product.sensitive);
      print('${product.name} - Skin Type Match: $matchesSkinType (User: ${widget.skinType}, Product: Oily=${product.oily}, Dry=${product.dry}, Sensitive=${product.sensitive})');

      bool matchesAllergies = widget.allergies.every((allergy) {
        final containsAllergy = product.ingredients.toLowerCase().contains(allergy.toLowerCase());
        print('${product.name} - Allergy "$allergy" Found: $containsAllergy');
        return !containsAllergy;
      });
      print('${product.name} - Allergies Match: $matchesAllergies (User Allergies: ${widget.allergies}, Ingredients: ${product.ingredients})');

      bool matchesBudget = true;
      if (widget.budget != null && widget.budget.isNotEmpty) {
        try {
          final budgetRange = widget.budget.split('-').map(int.parse).toList();
          final minBudget = budgetRange[0];
          final maxBudget = budgetRange[1];
          matchesBudget = product.price >= minBudget && product.price <= maxBudget;
          print('${product.name} - Budget Match: $matchesBudget (User Budget: $minBudget-$maxBudget, Price: ${product.price})');
        } catch (e) {
          print('${product.name} - Error parsing budget: ${widget.budget}, Error: $e');
          matchesBudget = false;
        }
      } else {
        print('${product.name} - Budget Match: true (No budget specified)');
      }

      final overallMatch = matchesSkinType && matchesAllergies && matchesBudget;
      print('${product.name} - Overall Match: $overallMatch');
      return overallMatch;
    }).toList();

    print('Number of filtered products before grouping: ${filteredProducts.length}');
    filteredProducts.forEach((p) {
      print('Filtered product: ${p.name}, Type: ${p.type}');
    });

    // Group filtered products by their type
    final productsByType = <String, List<Product>>{};
    for (final product in filteredProducts) {
      if (widget.selectedProductTypes.contains(product.type)) {
        productsByType.putIfAbsent(product.type, () => []);
        productsByType[product.type]!.add(product);
      }
    }
    print('Products grouped by type: $productsByType');
    _availableProductsByType.addAll(productsByType);
    print('_availableProductsByType after adding: $_availableProductsByType');

    // Initialize selected products to null for each requested type
    for (final type in widget.selectedProductTypes) {
      _selectedProducts[type] = null;
    }
  }

  void _navigateToProductSelection(String productType) {
    final availableProducts = _availableProductsByType[productType] ?? [];
    print('Navigating to select $productType. Available products: ${availableProducts.map((p) => p.name).toList()}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductSelectionScreen(
          productType: productType,
          products: availableProducts,
          onProductSelected: (selectedProduct) {
            setState(() {
              _selectedProducts[productType] = selectedProduct;
              _checkCompatibility();
            });
          },
          currentlySelectedProduct: _selectedProducts[productType],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommended Products')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Based on your answers, we recommend the following products:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ...widget.selectedProductTypes.map((productType) {
              final selectedProduct = _selectedProducts[productType];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productType.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _navigateToProductSelection(productType),
                    child: selectedProduct != null
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: SizedBox(
                              width: 180, // Adjust width as needed
                              child: SelectableProductCard(
                                product: selectedProduct,
                                currentlySelectedProduct: selectedProduct,
                                onProductSelected: (p) {}, // Dummy callback
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Tap to select product'),
                          ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }).toList(),
            if (_selectedProducts.isNotEmpty)
              _buildCompatibilityDisplay(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectedProducts.values.every((p) => p != null)
                  ? () {
                      // Navigate to the CartScreen:
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  MyApp()), //  CartScreen
                      );
                    }
                  : null, // Disable button if not all products are selected
              child: const Text('Finsih'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityDisplay() {
    List<String> selectedTypes = _selectedProducts.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compatibility Status:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        ...selectedTypes.asMap().entries.expand((entry1) {
          final index1 = entry1.key;
          final type1 = entry1.value;
          return selectedTypes.sublist(index1 + 1).map((type2) {
            final key1 = '$type1-$type2';
            final key2 = '$type2-$type1';
            final isCompatible =
                _compatibilityStatus[key1] ??
                    _compatibilityStatus[key2] ??
                    true;
            final product1Name = _selectedProducts[type1]?.name ?? 'No product selected';
            final product2Name = _selectedProducts[type2]?.name ?? 'No product selected';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '$product1Name and $product2Name: ${isCompatible ? 'Compatible' : 'Not Compatible'}',
                style: TextStyle(
                  color: isCompatible ? Colors.green : Colors.red,
                ),
              ),
            );
          });
        }).toList(),
      ],
    );
  }
}
// 8. Main Widget
class ProductCompatibilityApp extends StatefulWidget {
  const ProductCompatibilityApp({super.key});

  @override
  _ProductCompatibilityAppState createState() => _ProductCompatibilityAppState();
}

class _ProductCompatibilityAppState extends State<ProductCompatibilityApp> {
  @override
  void initState() {
    super.initState();
    // Load product data
    _loadProductData();
  }

  Future<void> _loadProductData() async {
   
    // Get the ProductProvider
    final productProvider =
    Provider.of<ProductProvider>(context, listen: false);
    // Load the products
    productProvider.loadProductsFromJson();
  }

  @override
  Widget build(BuildContext context) {
    return const QuestionnaireScreen();
  }
}

