import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/product.dart';

class ProductLoader {
  static Future<List<Product>> loadProducts() async {
    final String jsonString = await rootBundle.loadString('assets/data/products.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.map((item) => Product.fromJson(item)).toList();
  }
}
