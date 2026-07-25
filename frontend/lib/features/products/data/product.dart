class Product {
  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.taxPercentage,
    this.imageUrl,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? description;
  final double price;
  final double? taxPercentage;
  final String? imageUrl;
  final bool isActive;

  factory Product.fromJson(Map j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        price: double.parse(j['price'].toString()),
        taxPercentage: j['taxPercentage'] == null ? null : double.parse(j['taxPercentage'].toString()),
        imageUrl: j['imageUrl'] as String?,
        isActive: j['isActive'] as bool? ?? true,
      );
}
