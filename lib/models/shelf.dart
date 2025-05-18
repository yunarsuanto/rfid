import 'package:rfid/models/shel_item.dart';

class Shelf {
  final String shelfCode;
  final String shelfName;
  final int totalItems;
  final List<ShelfItem> items;

  Shelf({
    required this.shelfCode,
    required this.shelfName,
    required this.totalItems,
    required this.items,
  });

  factory Shelf.fromJson(Map<String, dynamic> json) {
    return Shelf(
      shelfCode: json['shelf_code'],
      shelfName: json['shelf_name'],
      totalItems: json['total_items'],
      items:
          (json['items'] as List)
              .map((itemJson) => ShelfItem.fromJson(itemJson))
              .toList(),
    );
  }
}
