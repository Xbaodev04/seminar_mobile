class Poi {
  final String id;
  final String? ownerId;
  final String? ownerName;
  final String name;
  final String? category;
  final double latitude;
  final double longitude;
  final String? coverImage;
  final String? priceRange;
  final String? openingHours;
  final String? contactPhone;
  final String? website;
  final double? averageRating;
  final int? totalReviews;
  final int? radius;
  final String? languageCode;

  const Poi({
    required this.id,
    this.ownerId,
    this.ownerName,
    required this.name,
    this.category,
    required this.latitude,
    required this.longitude,
    this.coverImage,
    this.priceRange,
    this.openingHours,
    this.contactPhone,
    this.website,
    this.averageRating,
    this.totalReviews,
    this.radius,
    this.languageCode,
  });

  static double _parseCoordinate(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.trim()) ?? 0.0;
    }
    return 0.0;
  }

  factory Poi.fromJson(Map<String, dynamic> json) => Poi(
    id: json['id']?.toString() ?? '',
    ownerId: json['owner_id']?.toString(),
    ownerName: json['owner_name']?.toString(),
    name: (json['name'] ?? json['title'] ?? 'Quán ăn').toString(),
    category: json['category']?.toString(),
    latitude: _parseCoordinate(
      json['latitude'] ?? json['lat'] ?? json['y'] ?? json['location_lat'],
    ),
    longitude: _parseCoordinate(
      json['longitude'] ?? json['lng'] ?? json['x'] ?? json['location_lng'],
    ),
    coverImage: _buildFullImageUrl(
      json['cover_image']?.toString() ?? json['image']?.toString(),
    ),
    priceRange: json['price_range']?.toString(),
    openingHours: json['opening_hours']?.toString(),
    contactPhone: json['contact_phone']?.toString(),
    website: json['website']?.toString(),
    averageRating: json['average_rating'] != null
        ? double.tryParse(json['average_rating'].toString())
        : null,
    totalReviews: json['total_reviews'] is int
        ? json['total_reviews'] as int
        : int.tryParse(json['total_reviews']?.toString() ?? ''),
    radius: json['radius'] is int
        ? json['radius'] as int
        : int.tryParse(json['radius']?.toString() ?? ''),
    languageCode: json['language_code']?.toString(),
  );

  static String? _buildFullImageUrl(String? coverImage) {
    if (coverImage == null || coverImage.isEmpty) return null;

    // If already absolute URL, return as is
    if (coverImage.startsWith('http')) {
      return coverImage;
    }

    // Otherwise prepend base URL
    const String baseUrl = 'http://10.0.2.2:8000';
    return '$baseUrl${coverImage.startsWith('/') ? coverImage : '/$coverImage'}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'owner_name': ownerName,
    'name': name,
    'category': category,
    'latitude': latitude,
    'longitude': longitude,
    'cover_image': coverImage,
    'price_range': priceRange,
    'opening_hours': openingHours,
    'contact_phone': contactPhone,
    'website': website,
    'average_rating': averageRating,
    'total_reviews': totalReviews,
    'radius': radius,
    'language_code': languageCode,
  };
}
