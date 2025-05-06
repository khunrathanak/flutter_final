import 'package:flutter/material.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final Map<Product, int> _items = {};

  Map<Product, int> get items => _items;

  void addToCart(Product product) {
    if (_items.containsKey(product)) {
      _items[product] = _items[product]! + 1;
    } else {
      _items[product] = 1;
    }
    notifyListeners();
  }

  void increase(Product product) {
    _items[product] = _items[product]! + 1;
    notifyListeners();
  }

  void decrease(Product product) {
    if (_items[product]! > 1) {
      _items[product] = _items[product]! - 1;
    } else {
      _items.remove(product);
    }
    notifyListeners();
  }
  void clear() {
  _items.clear();
  notifyListeners();
  }


  int getQuantity(Product product) => _items[product] ?? 0;
}
