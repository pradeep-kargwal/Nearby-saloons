import 'package:beauty_master/models/BMCommonCardModel.dart';
import 'package:beauty_master/models/BMPlaceModel.dart';
import 'package:beauty_master/services/BMAIService.dart';
import 'package:beauty_master/services/BMPlacesService.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobx/mobx.dart';

part 'BMPlacesStore.g.dart';

class BMPlacesStore = BMPlacesStoreBase with _$BMPlacesStore;

abstract class BMPlacesStoreBase with Store {
  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @observable
  double? userLat;

  @observable
  double? userLng;

  @observable
  ObservableList<BMPlaceModel> nearbyPlaces = ObservableList<BMPlaceModel>();

  @observable
  ObservableList<BMCommonCardModel> placeCards =
      ObservableList<BMCommonCardModel>();

  @observable
  ObservableList<BMCommonCardModel> recommendedCards =
      ObservableList<BMCommonCardModel>();

  @observable
  ObservableList<BMCommonCardModel> searchResults =
      ObservableList<BMCommonCardModel>();

  @observable
  bool isSearchLoading = false;

  @observable
  int currentSortIndex = 0;

  @action
  Future<void> requestLocationAndFetch() async {
    isLoading = true;
    errorMessage = null;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage = 'Location services are disabled.';
        isLoading = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage = 'Location permission denied.';
          isLoading = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        errorMessage = 'Location permissions are permanently denied.';
        isLoading = false;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      userLat = position.latitude;
      userLng = position.longitude;
      print('Location: ${userLat}, ${userLng}');

      await fetchNearbyPlaces();
    } catch (e) {
      errorMessage = 'Failed to get location: $e';
      isLoading = false;
    }
  }

  @action
  Future<void> fetchNearbyPlaces() async {
    if (userLat == null || userLng == null) return;

    isLoading = true;
    errorMessage = null;

    try {
      final places = await BMPlacesService.getNearbyPlaces(
        lat: userLat!,
        lng: userLng!,
      );
      nearbyPlaces = ObservableList.of(places);

      // Fetch details for first 10 places (phone, reviews)
      for (int i = 0; i < nearbyPlaces.length && i < 10; i++) {
        if (nearbyPlaces[i].placeId.isNotEmpty) {
          final details =
              await BMPlacesService.getPlaceDetails(nearbyPlaces[i].placeId);
          if (details != null) {
            nearbyPlaces[i] = details;
          }
        }
      }

      _buildPlaceCards();

      // Fetch recommended from a different search
      _fetchRecommended();
    } catch (e) {
      errorMessage = 'Failed to fetch places: $e';
    }

    isLoading = false;
  }

  Future<void> _fetchRecommended() async {
    if (userLat == null || userLng == null) return;
    try {
      final recommended = await BMPlacesService.searchPlaces(
        lat: userLat!,
        lng: userLng!,
        query: 'top rated beauty services',
      );
      if (recommended.isNotEmpty) {
        final recCards = recommended.take(8).map((place) {
          return BMCommonCardModel(
            image: 'images/salon_one.jpg',
            title: place.name,
            subtitle: place.address,
            rating: place.rating.toStringAsFixed(1),
            comments: '${place.reviewCount} reviews',
            distance: _calculateDistance(place.lat, place.lng),
            saveTag: false,
            liked: false,
            placeId: place.placeId,
            phone: place.phone,
            photoReference: place.photoReference,
            lat: place.lat,
            lng: place.lng,
            types: place.types,
            website: place.website,
            allPhotoReferences: place.allPhotoReferences,
            reviews: place.reviews
                .map((r) => <String, dynamic>{
                      'author_name': r.authorName,
                      'rating': r.rating,
                      'text': r.text,
                      'time': r.time,
                    })
                .toList(),
          );
        }).toList();
        recommendedCards = ObservableList.of(recCards);
      }
    } catch (e) {
      print('Failed to fetch recommended: $e');
    }
  }

  @action
  Future<void> fetchPlacesByType(String type) async {
    if (userLat == null || userLng == null) return;

    isSearchLoading = true;
    errorMessage = null;

    try {
      String query;
      switch (type.toUpperCase()) {
        case 'BARBERSHOP':
          query = 'barbershop';
          break;
        case 'HAIR SALON':
          query = 'hair salon';
          break;
        case 'NAIL SALON':
          query = 'nail salon';
          break;
        case 'BEAUTY':
          query = 'beauty salon';
          break;
        case 'MAKEUP':
          query = 'makeup studio bridal makeup';
          break;
        case 'MASSAGE PARLOUR':
        case 'SPA':
          query = 'spa massage parlour';
          break;
        case 'SKIN':
          query = 'skin clinic dermatologist';
          break;
        case 'ALL':
        default:
          query = 'beauty salon hair care spa';
      }

      final places = await BMPlacesService.searchPlaces(
        lat: userLat!,
        lng: userLng!,
        query: query,
      );

      if (places.isEmpty) {
        errorMessage = 'No places found for this category';
        isSearchLoading = false;
        return;
      }

      // Fetch details only for places with valid placeId
      for (int i = 0; i < places.length && i < 15; i++) {
        if (places[i].placeId.isNotEmpty) {
          final details =
              await BMPlacesService.getPlaceDetails(places[i].placeId);
          if (details != null) {
            places[i] = details;
          }
        }
      }

      // Build search results WITHOUT overwriting placeCards, sorted by distance
      searchResults = ObservableList.of(
        places
            .map((place) => BMCommonCardModel(
                  image: 'images/salon_one.jpg',
                  title: place.name,
                  subtitle: place.address,
                  rating: place.rating.toStringAsFixed(1),
                  comments: '${place.reviewCount} reviews',
                  distance: _calculateDistance(place.lat, place.lng),
                  saveTag: false,
                  liked: false,
                  placeId: place.placeId,
                  phone: place.phone,
                  photoReference: place.photoReference,
                  lat: place.lat,
                  lng: place.lng,
                  types: place.types,
                  website: place.website,
                  allPhotoReferences: place.allPhotoReferences,
                  reviews: place.reviews
                      .map((r) => <String, dynamic>{
                            'author_name': r.authorName,
                            'rating': r.rating,
                            'text': r.text,
                            'time': r.time,
                          })
                      .toList(),
                ))
            .toList()
          ..sort((a, b) {
            return _parseDistanceMeters(a.distance)
                .compareTo(_parseDistanceMeters(b.distance));
          }),
      );
    } catch (e) {
      errorMessage = 'Failed to fetch places: $e';
    }

    isSearchLoading = false;
  }

  Future<void> _aiRankPlaces(String category) async {
    if (placeCards.isEmpty) return;

    try {
      final descriptions = placeCards
          .take(15)
          .map((c) =>
              '${c.title}: ${c.rating} stars, ${c.comments}, ${c.distance}, ${c.types?.join(",") ?? ""}')
          .toList();

      final query = 'best $category sorted by rating and distance';
      final ranked = await BMAIService.smartRank(query, descriptions);

      if (ranked.isNotEmpty && ranked.length == placeCards.length) {
        final reordered = <BMCommonCardModel>[];
        for (var name in ranked) {
          final match = placeCards
              .where((c) => c.title.toLowerCase() == name.toLowerCase())
              .toList();
          if (match.isNotEmpty) reordered.add(match.first);
        }
        // Add any that weren't in the ranked list
        for (var card in placeCards) {
          if (!reordered.any((c) => c.title == card.title)) {
            reordered.add(card);
          }
        }
        placeCards = ObservableList.of(reordered);
      }
    } catch (e) {
      // If AI ranking fails, keep original order
      print('AI ranking failed: $e');
    }
  }

  void _buildPlaceCards() {
    placeCards = ObservableList.of(
      nearbyPlaces.map((place) {
        return BMCommonCardModel(
            image: 'images/salon_one.jpg',
            title: place.name,
            subtitle: place.address,
            rating: place.rating.toStringAsFixed(1),
            comments: '${place.reviewCount} reviews',
            distance: _calculateDistance(place.lat, place.lng),
            saveTag: false,
            liked: false,
            placeId: place.placeId,
            phone: place.phone,
            photoReference: place.photoReference,
            lat: place.lat,
            lng: place.lng,
            types: place.types,
            website: place.website,
            allPhotoReferences: place.allPhotoReferences,
            reviews: place.reviews
                .map((r) => <String, dynamic>{
                      'author_name': r.authorName,
                      'rating': r.rating,
                      'text': r.text,
                      'time': r.time,
                    })
                .toList());
      }).toList()
        ..sort((a, b) {
          return _parseDistanceMeters(a.distance)
              .compareTo(_parseDistanceMeters(b.distance));
        }),
    );
  }

  String _calculateDistance(double destLat, double destLng) {
    if (userLat == null || userLng == null) return '';
    final distanceInMeters = Geolocator.distanceBetween(
      userLat!,
      userLng!,
      destLat,
      destLng,
    );
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    }
    final km = distanceInMeters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  double _parseDistanceMeters(String? dist) {
    if (dist == null || dist.isEmpty) return double.maxFinite;
    if (dist.contains('km')) {
      final val = double.tryParse(dist.replaceAll(RegExp(r'[^0-9.]'), ''));
      return (val ?? 999) * 1000;
    }
    return double.tryParse(dist.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        double.maxFinite;
  }

  List<BMCommonCardModel> filterByType(String type) {
    if (type.toUpperCase() == 'ALL') return placeCards.toList();
    return placeCards.where((card) {
      final types = card.types ?? [];
      switch (type.toUpperCase()) {
        case 'BARBERSHOP':
          return types.contains('hair_care') || types.contains('barber');
        case 'HAIR SALON':
          return types.contains('beauty_salon') || types.contains('hair_care');
        case 'NAIL SALON':
          return types.contains('beauty_salon');
        case 'MAKEUP':
          return types.contains('beauty_salon');
        case 'MASSAGE PARLOUR':
          return types.contains('spa');
        default:
          return true;
      }
    }).toList();
  }

  void updateFromVoiceSearch(List<BMPlaceModel> places) {
    searchResults = ObservableList.of(
      places
          .map((place) => BMCommonCardModel(
                image: 'images/salon_one.jpg',
                title: place.name,
                subtitle: place.address,
                rating: place.rating.toStringAsFixed(1),
                comments: '${place.reviewCount} reviews',
                distance: _calculateDistance(place.lat, place.lng),
                saveTag: false,
                liked: false,
                placeId: place.placeId,
                phone: place.phone,
                photoReference: place.photoReference,
                lat: place.lat,
                lng: place.lng,
                types: place.types,
                reviews: place.reviews
                    .map((r) => <String, dynamic>{
                          'author_name': r.authorName,
                          'rating': r.rating,
                          'text': r.text,
                          'time': r.time,
                        })
                    .toList(),
              ))
          .toList(),
    );
    isSearchLoading = false;
    errorMessage = null;
  }

  void sortSearchResults(int sortBy) {
    currentSortIndex = sortBy;
    final sorted = List<BMCommonCardModel>.from(searchResults);
    switch (sortBy) {
      case 0: // Distance
        sorted.sort((a, b) {
          return _parseDistanceMeters(a.distance)
              .compareTo(_parseDistanceMeters(b.distance));
        });
        break;
      case 1: // Rating
        sorted.sort((a, b) {
          final ratA = double.tryParse(a.rating ?? '0') ?? 0;
          final ratB = double.tryParse(b.rating ?? '0') ?? 0;
          return ratB.compareTo(ratA); // Descending
        });
        break;
      case 2: // Name
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 3: // Most Reviewed
        sorted.sort((a, b) {
          final revA = int.tryParse(
                  a.comments?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ??
              0;
          final revB = int.tryParse(
                  b.comments?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ??
              0;
          return revB.compareTo(revA); // Descending
        });
        break;
    }
    searchResults = ObservableList.of(sorted);
  }
}
