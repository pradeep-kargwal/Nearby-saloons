class BMCommonCardModel {
  String image;
  String title;
  String? subtitle;
  String? rating;
  String? likes;
  String? comments;
  String? distance;
  bool saveTag;
  bool? liked;

  // Real place data fields
  String? placeId;
  String? phone;
  String? photoReference;
  double? lat;
  double? lng;
  List<String>? types;
  String? website;
  List<Map<String, dynamic>>? reviews;
  List<String>? allPhotoReferences;

  BMCommonCardModel({
    required this.image,
    required this.title,
    this.subtitle,
    this.comments,
    this.distance,
    this.likes,
    this.rating,
    required this.saveTag,
    this.liked,
    this.placeId,
    this.phone,
    this.photoReference,
    this.lat,
    this.lng,
    this.types,
    this.website,
    this.reviews,
    this.allPhotoReferences,
  });
}
