import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../screens/BMSingleComponentScreen.dart';
import '../utils/BMBottomSheet.dart';
import '../utils/BMColors.dart';

class BMMapFragment extends StatefulWidget {
  const BMMapFragment({Key? key}) : super(key: key);

  @override
  State<BMMapFragment> createState() => _BMMapFragmentState();
}

class _BMMapFragmentState extends State<BMMapFragment> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final LatLng _defaultCenter = const LatLng(28.6139, 77.2090);
  bool _initialized = false;

  @override
  void initState() {
    setStatusBarColor(bmSpecialColor);
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    if (bmPlacesStore.userLat == null) {
      await bmPlacesStore.requestLocationAndFetch();
    }
    if (mounted) {
      setState(() => _initialized = true);
      _refreshMarkers();
      _animateToUser();
    }
  }

  void _refreshMarkers() {
    _markers.clear();
    final lat = bmPlacesStore.userLat ?? _defaultCenter.latitude;
    final lng = bmPlacesStore.userLng ?? _defaultCenter.longitude;

    _markers.add(Marker(
      markerId: MarkerId('user'),
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: InfoWindow(title: 'You are here'),
    ));

    try {
      for (var card in bmPlacesStore.placeCards) {
        if (card.lat != null && card.lng != null) {
          _markers.add(Marker(
            markerId: MarkerId(card.placeId ?? card.title),
            position: LatLng(card.lat!, card.lng!),
            infoWindow:
                InfoWindow(title: card.title, snippet: card.rating ?? ''),
            onTap: () {
              BMSingleComponentScreen(element: card).launch(context);
            },
          ));
        }
      }
    } catch (e) {
      // ignore
    }
    if (mounted) setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_initialized) _animateToUser();
  }

  void _animateToUser() {
    final lat = bmPlacesStore.userLat;
    final lng = bmPlacesStore.userLng;
    if (lat != null && lng != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = bmPlacesStore.userLat ?? _defaultCenter.latitude;
    final lng = bmPlacesStore.userLng ?? _defaultCenter.longitude;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(lat, lng),
              zoom: 14.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: context.cardColor,
                      onPressed: _animateToUser,
                      child: Icon(Icons.my_location, color: bmPrimaryColor),
                    ),
                    8.height,
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: context.cardColor,
                      onPressed: () {
                        _refreshMarkers();
                        _animateToUser();
                      },
                      child: Icon(Icons.refresh, color: bmPrimaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: bmTextColorDarkMode,
                    borderRadius: radius(32),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('images/adjust.png',
                          height: 20, color: Colors.white),
                      4.width,
                      Text('Filter',
                              style: secondaryTextStyle(color: Colors.white))
                          .onTap(() {
                        showFilterBottomSheet(context);
                      }),
                      Text(' | ', style: primaryTextStyle(color: Colors.white)),
                      Icon(Icons.map_outlined, color: Colors.white),
                      4.width,
                      Text('Map',
                              style: secondaryTextStyle(color: Colors.white))
                          .onTap(() {
                        _animateToUser();
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
