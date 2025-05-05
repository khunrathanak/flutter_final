class Product {
  final String name;
  final String brand;
  final String type;
  final String image;
  final String ingredients;
  final String safety;
  final bool oily;
  final bool dry;
  final bool sensitive;
  final bool comedogenic;
  final bool acneFighting;
  final bool antiAging;
  final bool brightening;
  final bool uvProtection;
  final double price; 

  Product({
    
    required this.name,
    required this.brand,
    required this.type,
    required this.image,
    required this.ingredients,
    required this.safety,
    required this.oily,
    required this.dry,
    required this.sensitive,
    required this.comedogenic,
    required this.acneFighting,
    required this.antiAging,
    required this.brightening,
    required this.uvProtection,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
  return Product(
    name: json['name'] as String,
    brand: json['brand'] as String,
    type: json['type'] as String,
    image: json['image'] as String,
    ingredients: json['ingredients'] as String,
    safety: json['safety'] as String,
    oily: (json['oily'] as int) == 1,
    dry: (json['dry'] as int) == 1,
    sensitive: (json['sensitive'] as int) == 1,
    comedogenic: (json['comedogenic'] as int) == 1,
    acneFighting: (json['acne_fighting'] as int) == 1,
    antiAging: (json['anti_aging'] as int) == 1,
    brightening: (json['brightening'] as int) == 1,
    uvProtection: (json['uv'] as int) == 1,
    price: (json['price'] as num).toDouble(),
  );
}

}
