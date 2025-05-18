class BookDetail {
  final int id;
  final String title;
  final String edition;
  final String isbnIssn;
  final String publisher;
  final String publishYear;
  final String sor;
  final String imageUrl;
  final String collation;
  final String seriesTitle;
  final String itemCode;
  final String callNumber;
  final String availability;
  final String rfidCode;

  BookDetail({
    required this.id,
    required this.title,
    required this.edition,
    required this.isbnIssn,
    required this.publisher,
    required this.publishYear,
    required this.sor,
    required this.imageUrl,
    required this.collation,
    required this.seriesTitle,
    required this.itemCode,
    required this.callNumber,
    required this.availability,
    required this.rfidCode,
  });

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    return BookDetail(
      id: json['id'],
      title: json['title'] ?? '',
      edition: json['edition'] ?? '',
      isbnIssn: json['isbn_issn'] ?? '',
      publisher: json['publisher'] ?? '',
      publishYear: json['publish_year'] ?? '',
      sor: json['sor'] ?? '',
      imageUrl: json['image_url'] ?? '',
      collation: json['collation'] ?? '',
      seriesTitle: json['series_title'] ?? '',
      itemCode: json['item_code'] ?? '',
      callNumber: json['call_number'] ?? '',
      availability: json['availability'] ?? '',
      rfidCode: json['rfid_code'] ?? '',
    );
  }
}
