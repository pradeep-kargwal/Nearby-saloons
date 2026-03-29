import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:shimmer/shimmer.dart';

import '../components/BMFloatingActionComponent.dart';
import '../components/BMSkeleton.dart';
import '../components/BMVoiceSearchWidget.dart';
import '../components/BMSeacrFragmentHeaderComponent.dart';
import '../main.dart';
import '../models/BMCommonCardModel.dart';
import '../screens/BMAIChatScreen.dart';
import '../screens/BMSingleComponentScreen.dart';
import '../services/BMPlacesService.dart';
import '../utils/BMColors.dart';
import '../utils/BMWidgets.dart';

class BMSearchFragment extends StatefulWidget {
  const BMSearchFragment({Key? key}) : super(key: key);

  @override
  State<BMSearchFragment> createState() => _BMSearchFragmentState();
}

class _BMSearchFragmentState extends State<BMSearchFragment> {
  final List<Map<String, dynamic>> categories = [
    {'label': 'ALL', 'icon': Icons.storefront},
    {'label': 'BARBERSHOP', 'icon': Icons.content_cut},
    {'label': 'HAIR SALON', 'icon': Icons.content_cut},
    {'label': 'NAIL SALON', 'icon': Icons.brush},
    {'label': 'BEAUTY', 'icon': Icons.face_retouching_natural},
    {'label': 'SPA', 'icon': Icons.spa},
    {'label': 'MAKEUP', 'icon': Icons.palette},
    {'label': 'SKIN', 'icon': Icons.local_hospital},
  ];

  int selectedTab = 0;

  @override
  void initState() {
    setStatusBarColor(appStore.isDarkModeOn
        ? appStore.scaffoldBackground!
        : bmLightScaffoldBackgroundColor);
    super.initState();
    // Load all places for search on init
    if (bmPlacesStore.searchResults.isEmpty) {
      bmPlacesStore.fetchPlacesByType('ALL');
    }
  }

  String _getSelectedCategory() {
    return categories[selectedTab]['label'] as String;
  }

  void _onCategoryTap(int index) {
    selectedTab = index;
    final category = _getSelectedCategory();
    bmPlacesStore.fetchPlacesByType(category);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStore.isDarkModeOn
          ? appStore.scaffoldBackground!
          : bmLightScaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraint) => RefreshIndicator(
          onRefresh: () async {
            final category = _getSelectedCategory();
            if (category == 'ALL') {
              await bmPlacesStore.fetchNearbyPlaces();
            } else {
              await bmPlacesStore.fetchPlacesByType(category);
            }
          },
          color: bmPrimaryColor,
          backgroundColor: context.cardColor,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BMSeacrFragmentHeaderComponent()
                    .paddingSymmetric(horizontal: 16, vertical: 16),
                Wrap(
                  spacing: 16,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: radius(32),
                        border: Border.all(color: bmPrimaryColor, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.rotate(
                              angle: 6,
                              child: Icon(Icons.navigation_rounded,
                                  color: bmPrimaryColor)),
                          4.width,
                          Observer(
                            builder: (_) => Text(
                              bmPlacesStore.userLat != null
                                  ? 'Location found'
                                  : 'Getting location...',
                              style: boldTextStyle(
                                  color: appStore.isDarkModeOn
                                      ? bmPrimaryColor
                                      : bmSpecialColorDark,
                                  size: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: radius(32),
                        border: Border.all(color: bmPrimaryColor, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, color: bmPrimaryColor),
                          4.width,
                          Text('Anytime',
                              style: boldTextStyle(
                                  color: appStore.isDarkModeOn
                                      ? bmPrimaryColor
                                      : bmSpecialColorDark,
                                  size: 12)),
                        ],
                      ),
                    ),
                  ],
                ).paddingSymmetric(horizontal: 16),
                20.height,
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraint.maxHeight),
                  child: Container(
                    width: context.width(),
                    decoration: BoxDecoration(
                      color: appStore.isDarkModeOn
                          ? bmSecondBackgroundColorDark
                          : bmSecondBackgroundColorLight,
                      borderRadius: radiusOnly(topLeft: 32, topRight: 32),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          16.height,
                          SizedBox(
                            height: 42,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final cat = categories[index];
                                final isSelected = selectedTab == index;
                                return GestureDetector(
                                  onTap: () => _onCategoryTap(index),
                                  child: Container(
                                    margin: EdgeInsets.only(right: 10),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: radius(32),
                                      color: isSelected
                                          ? bmPrimaryColor
                                          : Colors.transparent,
                                      border: Border.all(
                                          color: bmPrimaryColor, width: 1.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          cat['icon'] as IconData,
                                          size: 16,
                                          color: isSelected
                                              ? white
                                              : appStore.isDarkModeOn
                                                  ? bmPrimaryColor
                                                  : bmSpecialColorDark,
                                        ),
                                        4.width,
                                        Text(
                                          cat['label'] as String,
                                          style: boldTextStyle(
                                            size: 12,
                                            color: isSelected
                                                ? white
                                                : appStore.isDarkModeOn
                                                    ? bmPrimaryColor
                                                    : bmSpecialColorDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          12.height,
                          titleText(title: 'Show results', size: 16)
                              .paddingSymmetric(horizontal: 16),
                          Observer(
                            builder: (_) {
                              if (bmPlacesStore.isSearchLoading) {
                                return Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Column(
                                    children: List.generate(
                                        5, (index) => BMListItemSkeleton()),
                                  ),
                                );
                              }
                              if (bmPlacesStore.errorMessage != null) {
                                return Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                      child: Text(bmPlacesStore.errorMessage!,
                                          style: secondaryTextStyle())),
                                );
                              }
                              final filtered = bmPlacesStore.searchResults;
                              if (filtered.isEmpty) {
                                return Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                      child: Text('No results found',
                                          style: secondaryTextStyle())),
                                );
                              }
                              return Column(
                                children: filtered.map((e) {
                                  return GestureDetector(
                                    onTap: () {
                                      BMSingleComponentScreen(element: e)
                                          .launch(context);
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 16),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: context.cardColor,
                                          borderRadius: radius(16),
                                        ),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(16),
                                                  bottomLeft:
                                                      Radius.circular(16)),
                                              child: e.photoReference != null &&
                                                      e.photoReference!
                                                          .isNotEmpty
                                                  ? Image.network(
                                                      BMPlacesService
                                                          .getPhotoUrl(e
                                                              .photoReference!),
                                                      width: 80,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (_, __, ___) =>
                                                              Image.asset(
                                                        e.image,
                                                        width: 80,
                                                        height: 100,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                  : Image.asset(
                                                      e.image,
                                                      width: 80,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.all(12),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(e.title,
                                                        style: boldTextStyle(
                                                            size: 14,
                                                            color: appStore
                                                                    .isDarkModeOn
                                                                ? Colors.white
                                                                : bmSpecialColorDark)),
                                                    4.height,
                                                    Text(e.subtitle ?? '',
                                                        style:
                                                            secondaryTextStyle(
                                                                size: 11),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis),
                                                    4.height,
                                                    Row(
                                                      children: [
                                                        Icon(Icons.star,
                                                            color: Colors.amber,
                                                            size: 16),
                                                        4.width,
                                                        Text(e.rating ?? '0',
                                                            style:
                                                                boldTextStyle(
                                                                    size: 12)),
                                                        8.width,
                                                        Text(e.distance ?? '',
                                                            style:
                                                                secondaryTextStyle(
                                                                    size: 11)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          60.height,
                        ],
                      ).cornerRadiusWithClipRRectOnly(
                          topRight: 32, topLeft: 32),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BMVoiceSearchWidget(),
          12.height,
          BMFloatingActionComponent(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
