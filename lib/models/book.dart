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

class Book {
  final int id;
  final String title;
  final String edition;
  final String isbnIssn;
  final String publisher;
  final String publishYear;
  final String sor;
  final String imageUrl;
  final String callNumber;
  final String collation;
  final String seriesTitle;
  final List<Item> items;

  Book({
    required this.id,
    required this.title,
    required this.edition,
    required this.isbnIssn,
    required this.publisher,
    required this.publishYear,
    required this.sor,
    required this.imageUrl,
    required this.callNumber,
    required this.collation,
    required this.seriesTitle,
    required this.items,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    var itemList = json['items'] as List;
    List<Item> itemObjs = itemList.map((item) => Item.fromJson(item)).toList();

    return Book(
      id: json['id'],
      title: json['title'],
      edition: json['edition'] ?? '',
      isbnIssn: json['isbn_issn'] ?? '',
      publisher: json['publisher'] ?? '',
      publishYear: json['publish_year'] ?? '',
      sor: json['sor'] ?? '',
      imageUrl: json['image_url'] ?? '',
      callNumber: json['call_number'] ?? '',
      collation: json['collation'] ?? '',
      seriesTitle: json['series_title'] ?? '',
      items: itemObjs,
    );
  }
}
