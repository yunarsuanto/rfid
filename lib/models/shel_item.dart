class ShelfItem {
  final int id;
  final String itemCode;
  final String callNumber;
  final String availability;
  final String rfidCode;

  ShelfItem({
    required this.id,
    required this.itemCode,
    required this.callNumber,
    required this.availability,
    required this.rfidCode,
  });

  factory ShelfItem.fromJson(Map<String, dynamic> json) {
    return ShelfItem(
      id: json['id'],
      itemCode: json['item_code'],
      callNumber: json['call_number'],
      availability: json['availability'],
      rfidCode: json['rfid_code'],
    );
  }
}
