class ReportDto {
  final String title;
  final String description;
  final List<String> imageUrls;
  final double latitude;
  final double longitude;
  final bool isAnonymous;
  final String? address;
  final String? locationDescription;
  final String? categoryId;

  ReportDto({
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.latitude,
    required this.longitude,
    required this.isAnonymous,
    this.address,
    this.locationDescription,
    this.categoryId,
  });

  ReportDto copyWith({
    String? title,
    String? description,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
    bool? isAnonymous,
    String? address,
    String? locationDescription,
    String? categoryId,
  }) {
    return ReportDto(
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      address: address ?? this.address,
      locationDescription: locationDescription ?? this.locationDescription,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'image_urls': imageUrls,
      'latitude': latitude,
      'longitude': longitude,
      'is_anonymous': isAnonymous,
      'address': address,
      'location_description': locationDescription,
      if (categoryId != null && categoryId!.isNotEmpty) 'category_id': categoryId,
    };
  }
}
