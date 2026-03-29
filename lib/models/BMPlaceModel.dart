import '../utils/BMConstants.dart';

class BMReview {
  final String authorName;
  final int rating;
  final String text;
  final int time;

  BMReview({
    required this.authorName,
    required this.rating,
    required this.text,
    required this.time,
  });

  factory BMReview.fromJson(Map<String, dynamic> json) {
    return BMReview(
      authorName: json['author_name'] ?? 'Anonymous',
      rating: json['rating'] ?? 0,
      text: json['text'] ?? '',
      time: json['time'] ?? 0,
    );
  }
}

class BMPlaceModel {
  String placeId;
  String name;
  String address;
  String? phone;
  double rating;
  int reviewCount;
  String? photoReference;
  List<String> allPhotoReferences;
  double lat;
  double lng;
  List<String> types;
  bool isOpen;
  String? website;
  int? priceLevel;
  List<BMReview> reviews;

  BMPlaceModel({
    required this.placeId,
    required this.name,
    required this.address,
    this.phone,
    required this.rating,
    required this.reviewCount,
    this.photoReference,
    this.allPhotoReferences = const [],
    required this.lat,
    required this.lng,
    required this.types,
    this.isOpen = false,
    this.website,
    this.priceLevel,
    this.reviews = const [],
  });

  factory BMPlaceModel.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']?['location'] ?? {};
    final photos = json['photos'] as List<dynamic>?;
    final openingHours = json['opening_hours'];
    final reviewsJson = json['reviews'] as List<dynamic>?;

    List<String> photoRefs = [];
    if (photos != null) {
      for (var p in photos) {
        if (p['photo_reference'] != null) {
          photoRefs.add(p['photo_reference']);
        }
      }
    }

    return BMPlaceModel(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      address: json['vicinity'] ?? json['formatted_address'] ?? '',
      phone: json['formatted_phone_number'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['user_ratings_total'] ?? 0,
      photoReference: photoRefs.isNotEmpty ? photoRefs[0] : null,
      allPhotoReferences: photoRefs,
      lat: (geometry['lat'] ?? 0.0).toDouble(),
      lng: (geometry['lng'] ?? 0.0).toDouble(),
      types: List<String>.from(json['types'] ?? []),
      isOpen: openingHours?['open_now'] ?? false,
      website: json['website'],
      priceLevel: json['price_level'],
      reviews: reviewsJson != null
          ? reviewsJson.map((r) => BMReview.fromJson(r)).toList()
          : [],
    );
  }

  String get photoUrl {
    if (photoReference == null) return '';
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$googlePlacesApiKey';
  }

  String get typesDisplay {
    if (types.isEmpty) return 'Beauty Salon';
    final beautyTypes = types
        .where((t) =>
            !['establishment', 'point_of_interest', 'health'].contains(t))
        .toList();
    if (beautyTypes.isEmpty) return 'Beauty Salon';
    return beautyTypes
        .map((t) => t
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' '))
        .join(', ');
  }
}
