class Item {
  final int id;
  final String itemCode;
  final String callNumber;
  final String availability;
  final String rfidCode;

  Item({
    required this.id,
    required this.itemCode,
    required this.callNumber,
    required this.availability,
    required this.rfidCode,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      itemCode: json['item_code'],
      callNumber: json['call_number'],
      availability: json['availability'],
      rfidCode: json['rfid_code'],
    );
  }
}
