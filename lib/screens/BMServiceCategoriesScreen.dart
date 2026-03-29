import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../screens/BMNearbyServicesScreen.dart';
import '../utils/BMColors.dart';
import '../utils/BMWidgets.dart';

class BMServiceCategoriesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Hair Salon',
      'icon': Icons.content_cut,
      'filterType': 'BARBERSHOP'
    },
    {'name': 'Nail Salon', 'icon': Icons.brush, 'filterType': 'NAIL SALON'},
    {
      'name': 'Beauty Salon',
      'icon': Icons.face_retouching_natural,
      'filterType': 'HAIR SALON'
    },
    {
      'name': 'Barbershop',
      'icon': Icons.content_cut,
      'filterType': 'BARBERSHOP'
    },
    {
      'name': 'Spa & Massage',
      'icon': Icons.spa,
      'filterType': 'MASSAGE PARLOUR'
    },
    {'name': 'Makeup Studio', 'icon': Icons.palette, 'filterType': 'MAKEUP'},
    {
      'name': 'Skin Clinic',
      'icon': Icons.local_hospital,
      'filterType': 'HAIR SALON'
    },
    {'name': 'All Services', 'icon': Icons.storefront, 'filterType': 'ALL'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStore.isDarkModeOn
          ? appStore.scaffoldBackground!
          : bmLightScaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appStore.isDarkModeOn
            ? appStore.scaffoldBackground!
            : bmLightScaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: bmPrimaryColor),
          onPressed: () => finish(context),
        ),
        title: titleText(title: 'Service Categories'),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: radius(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bmPrimaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(cat['icon'] as IconData,
                      color: bmPrimaryColor, size: 32),
                ),
                12.height,
                Text(
                  cat['name'] as String,
                  style: boldTextStyle(
                    size: 14,
                    color: appStore.isDarkModeOn
                        ? Colors.white
                        : bmSpecialColorDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).onTap(() {
            final filterType = cat['filterType'] as String;
            final name = cat['name'] as String;
            if (bmPlacesStore.userLat != null) {
              bmPlacesStore.fetchPlacesByType(filterType);
            }
            BMNearbyServicesScreen(
              category: filterType,
              screenTitle: name,
            ).launch(context);
          });
        },
      ),
    );
  }
}
