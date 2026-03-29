import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../screens/BMAIChatScreen.dart';
import '../utils/BMColors.dart';
import '../utils/BMWidgets.dart';

class HomeFragmentHeadComponent extends StatefulWidget {
  const HomeFragmentHeadComponent({Key? key}) : super(key: key);

  @override
  State<HomeFragmentHeadComponent> createState() =>
      _HomeFragmentHeadComponentState();
}

class _HomeFragmentHeadComponentState extends State<HomeFragmentHeadComponent> {
  String _locationName = 'Detecting location...';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    if (bmPlacesStore.userLat != null && bmPlacesStore.userLng != null) {
      try {
        final placemarks = await placemarkFromCoordinates(
          bmPlacesStore.userLat!,
          bmPlacesStore.userLng!,
        );
        if (placemarks.isNotEmpty && mounted) {
          final p = placemarks.first;
          setState(() {
            _locationName = p.locality?.isNotEmpty == true
                ? p.locality!
                : p.subAdministrativeArea?.isNotEmpty == true
                    ? p.subAdministrativeArea!
                    : 'Your Location';
          });
        }
      } catch (e) {
        if (mounted) setState(() => _locationName = 'Your Location');
      }
    } else {
      Future.delayed(Duration(seconds: 3), _resolveLocation);
    }
  }

  void _onSearch() {
    BMAIChatScreen(initialQuery: _searchController.text).launch(context);
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return upperContainer(
      screenContext: context,
      child: Column(
        children: [
          40.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 40),
                  8.width,
                  Observer(
                    builder: (_) {
                      if (bmPlacesStore.isLoading) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Finding you...',
                                style: boldTextStyle(
                                    color: Colors.white, size: 14)),
                            SizedBox(
                              width: 120,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white70),
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_locationName,
                              style:
                                  boldTextStyle(color: Colors.white, size: 14)),
                          Text(
                            '${bmPlacesStore.placeCards.length} places nearby',
                            style: secondaryTextStyle(
                                color: Colors.white70, size: 12),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ).expand(),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: radius(100)),
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.notifications_none,
                  color: bmSpecialColorDark,
                  size: 30,
                ),
              )
            ],
          ),
          16.height,
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: radius(32),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(Icons.mic, color: bmPrimaryColor),
                hintText: 'Tap mic below to search by voice',
                hintStyle: boldTextStyle(color: bmPrimaryColor, size: 14),
              ),
              cursorColor: bmPrimaryColor,
              onSubmitted: (_) => _onSearch(),
              onTap: () {
                BMAIChatScreen().launch(context);
              },
              readOnly: true,
            ),
          ),
          16.height,
        ],
      ),
    );
  }
}
