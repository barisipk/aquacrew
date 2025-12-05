enum ItemType { background, character, obstacle, platform }

class GameItem {
  final String id;
  final String name;
  final ItemType type;
  final double price;
  final bool isPurchased;
  final String assetPath;
  final String? description;
  final String? displayPrice;
  final String? storeTitle;
  final String? storeDescription;

  GameItem({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.isPurchased = false,
    required this.assetPath,
    this.description,
    this.displayPrice,
    this.storeTitle,
    this.storeDescription,
  });

  GameItem copyWith({
    String? id,
    String? name,
    ItemType? type,
    double? price,
    bool? isPurchased,
    String? assetPath,
    String? description,
    String? displayPrice,
    String? storeTitle,
    String? storeDescription,
  }) {
    return GameItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      price: price ?? this.price,
      isPurchased: isPurchased ?? this.isPurchased,
      assetPath: assetPath ?? this.assetPath,
      description: description ?? this.description,
      displayPrice: displayPrice ?? this.displayPrice,
      storeTitle: storeTitle ?? this.storeTitle,
      storeDescription: storeDescription ?? this.storeDescription,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'price': price,
      'isPurchased': isPurchased,
      'assetPath': assetPath,
      'description': description,
      'displayPrice': displayPrice,
      'storeTitle': storeTitle,
      'storeDescription': storeDescription,
    };
  }

  factory GameItem.fromJson(Map<String, dynamic> json) {
    return GameItem(
      id: json['id'],
      name: json['name'],
      type: ItemType.values.firstWhere((e) => e.toString() == json['type']),
      price: json['price'],
      isPurchased: json['isPurchased'] ?? false,
      assetPath: json['assetPath'],
      description: json['description'],
      displayPrice: json['displayPrice'],
      storeTitle: json['storeTitle'],
      storeDescription: json['storeDescription'],
    );
  }
}
