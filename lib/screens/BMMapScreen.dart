import 'package:beauty_master/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart';

import '../components/BMCardComponentTwo.dart';
import '../models/BMCommonCardModel.dart';
import '../utils/BMColors.dart';

class BMMapScreen extends StatefulWidget {
  static String tag = '/BMMapScreen';

  @override
  BMMapScreenState createState() => BMMapScreenState();
}

class BMMapScreenState extends State<BMMapScreen> {
  late GoogleMapController mapController;

  Set<Marker> _markers = {};

  final LatLng _defaultCenter = const LatLng(40.7128, -74.0060);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (bmPlacesStore.userLat != null) {
      _animateToUser();
    }
  }

  void _animateToUser() {
    if (bmPlacesStore.userLat != null && bmPlacesStore.userLng != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(bmPlacesStore.userLat!, bmPlacesStore.userLng!),
          14.0,
        ),
      );
    }
  }

  void _buildMarkers() {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: MarkerId('user_location'),
        position: LatLng(
          bmPlacesStore.userLat ?? _defaultCenter.latitude,
          bmPlacesStore.userLng ?? _defaultCenter.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: 'You are here'),
      ),
    );
    for (var place in bmPlacesStore.nearbyPlaces) {
      _markers.add(
        Marker(
          markerId: MarkerId(place.placeId),
          position: LatLng(place.lat, place.lng),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: '${place.rating} - ${place.address}',
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (bmPlacesStore.userLat == null) {
      bmPlacesStore.requestLocationAndFetch().then((_) {
        if (mounted) {
          setState(() {
            _buildMarkers();
            _animateToUser();
          });
        }
      });
    } else {
      _buildMarkers();
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    final center = bmPlacesStore.userLat != null
        ? LatLng(bmPlacesStore.userLat!, bmPlacesStore.userLng!)
        : _defaultCenter;

    return Scaffold(
      backgroundColor: appStore.isDarkModeOn
          ? appStore.scaffoldBackground!
          : bmLightScaffoldBackgroundColor,
      body: Stack(
        children: [
          Observer(
            builder: (_) {
              _buildMarkers();
              return GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: center,
                  zoom: 14.0,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              );
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: radius(100)),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: bmPrimaryColor),
                          onPressed: () {
                            finish(context);
                          },
                        ),
                      ),
                      8.width,
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: radius(100)),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                color: bmPrimaryColor),
                            8.width,
                            Observer(
                              builder: (_) => Text(
                                bmPlacesStore.userLat != null
                                    ? 'Nearby'
                                    : 'Loading...',
                                style: boldTextStyle(),
                              ),
                            ),
                            8.width,
                          ],
                        ),
                      )
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: context.cardColor, borderRadius: radius(100)),
                    child: Image.asset('images/adjust.png',
                        height: 26, color: bmPrimaryColor),
                  ),
                ],
              ).paddingOnly(left: 16, top: 30, right: 16),
              Observer(
                builder: (_) {
                  final cards = bmPlacesStore.placeCards;
                  if (cards.isEmpty) return SizedBox.shrink();
                  return SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      itemCount: cards.length > 10 ? 10 : cards.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: BMCardComponentTwo(element: cards[index]),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 110),
        child: FloatingActionButton(
          onPressed: () {
            _animateToUser();
          },
          mini: true,
          backgroundColor: context.cardColor,
          child: Icon(Icons.my_location, color: bmPrimaryColor),
        ),
      ),
      bottomNavigationBar: Observer(
        builder: (_) => Container(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: radiusOnly(topRight: 32, topLeft: 32)),
          child: Text(
            'Show ${bmPlacesStore.placeCards.length}+ Places',
            style: boldTextStyle(),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
