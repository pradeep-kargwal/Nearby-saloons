import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../screens/BMNearbyServicesScreen.dart';
import '../utils/BMColors.dart';

class BMTopServiceHomeComponent extends StatelessWidget {
  final List<Map<String, dynamic>> services = [
    {
      'name': 'Hair Salon',
      'icon': Icons.content_cut,
      'filterType': 'HAIR SALON',
    },
    {
      'name': 'Nail Salon',
      'icon': Icons.brush,
      'filterType': 'NAIL SALON',
    },
    {
      'name': 'Beauty Salon',
      'icon': Icons.face_retouching_natural,
      'filterType': 'BEAUTY',
    },
    {
      'name': 'Spa',
      'icon': Icons.spa,
      'filterType': 'SPA',
    },
    {
      'name': 'Makeup',
      'icon': Icons.palette,
      'filterType': 'MAKEUP',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return HorizontalList(
      padding: EdgeInsets.symmetric(horizontal: 16),
      spacing: 16,
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: radius(32),
              ),
              child: Icon(
                service['icon'] as IconData,
                color: bmPrimaryColor,
                size: 32,
              ),
            ).onTap(() {
              final filterType = service['filterType'] as String;
              final name = service['name'] as String;
              if (bmPlacesStore.userLat != null) {
                bmPlacesStore.fetchPlacesByType(filterType);
              }
              BMNearbyServicesScreen(
                category: filterType,
                screenTitle: name,
              ).launch(context);
            }),
            8.height,
            Text(service['name'] as String, style: boldTextStyle(size: 12)),
          ],
        );
      },
    );
  }
}
