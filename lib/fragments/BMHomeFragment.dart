import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:shimmer/shimmer.dart';

import '../components/BMCommonCardComponent.dart';
import '../components/BMHomeFragmentHeadComponent.dart';
import '../components/BMSkeleton.dart';
import '../components/BMTopServiceHomeComponent.dart';
import '../components/BMVoiceSearchWidget.dart';
import '../main.dart';
import '../screens/BMNearbyServicesScreen.dart';
import '../screens/BMServiceCategoriesScreen.dart';
import '../utils/BMColors.dart';
import '../utils/BMWidgets.dart';

class BMHomeFragment extends StatefulWidget {
  const BMHomeFragment({Key? key}) : super(key: key);

  @override
  State<BMHomeFragment> createState() => _BMHomeFragmentState();
}

class _BMHomeFragmentState extends State<BMHomeFragment> {
  @override
  void initState() {
    setStatusBarColor(bmSpecialColor);
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    if (bmPlacesStore.userLat == null) {
      await bmPlacesStore.requestLocationAndFetch();
    }
  }

  Future<void> _onRefresh() async {
    await bmPlacesStore.requestLocationAndFetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStore.isDarkModeOn
          ? appStore.scaffoldBackground!
          : bmLightScaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: bmPrimaryColor,
        backgroundColor: context.cardColor,
        strokeWidth: 3,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              HomeFragmentHeadComponent(),
              lowerContainer(
                screenContext: context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    20.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        titleText(title: 'Top Services'),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                BMServiceCategoriesScreen().launch(context);
                              },
                              child: Text('See All',
                                  style: boldTextStyle(
                                      color: appStore.isDarkModeOn
                                          ? bmPrimaryColor
                                          : bmTextColorDarkMode)),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                color: appStore.isDarkModeOn
                                    ? bmPrimaryColor
                                    : bmTextColorDarkMode,
                                size: 16),
                          ],
                        )
                      ],
                    ).paddingSymmetric(horizontal: 16),
                    20.height,
                    BMTopServiceHomeComponent(),
                    20.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        titleText(title: 'Nearby Places'),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                BMNearbyServicesScreen().launch(context);
                              },
                              child: Text('See All',
                                  style: boldTextStyle(
                                      color: appStore.isDarkModeOn
                                          ? bmPrimaryColor
                                          : bmTextColorDarkMode)),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                color: appStore.isDarkModeOn
                                    ? bmPrimaryColor
                                    : bmTextColorDarkMode,
                                size: 16),
                          ],
                        )
                      ],
                    ).paddingSymmetric(horizontal: 16),
                    20.height,
                    Observer(
                      builder: (_) {
                        if (bmPlacesStore.isLoading) {
                          return SizedBox(
                            height: 260,
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: HorizontalList(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                spacing: 16,
                                itemCount: 3,
                                itemBuilder: (context, index) {
                                  return BMCardSkeleton(isHorizontal: true);
                                },
                              ),
                            ),
                          );
                        }
                        if (bmPlacesStore.errorMessage != null) {
                          return SizedBox(
                            height: 220,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(bmPlacesStore.errorMessage!,
                                      style: secondaryTextStyle(
                                          color: bmTextColorDarkMode)),
                                  8.height,
                                  TextButton(
                                    onPressed: () => _loadPlaces(),
                                    child: Text('Retry',
                                        style: boldTextStyle(
                                            color: bmPrimaryColor)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final places = bmPlacesStore.placeCards;
                        if (places.isEmpty) {
                          return SizedBox(
                            height: 220,
                            child: Center(
                                child: Text('No nearby places found',
                                    style: secondaryTextStyle(
                                        color: bmTextColorDarkMode))),
                          );
                        }
                        return HorizontalList(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          spacing: 16,
                          itemCount: places.length > 5 ? 5 : places.length,
                          itemBuilder: (context, index) {
                            return BMCommonCardComponent(
                                element: places[index],
                                fullScreenComponent: false,
                                isFavList: false);
                          },
                        );
                      },
                    ),
                    20.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        titleText(title: 'Recommended for You').expand(),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                BMNearbyServicesScreen().launch(context);
                              },
                              child: Text('See All',
                                  style: boldTextStyle(
                                      color: appStore.isDarkModeOn
                                          ? bmPrimaryColor
                                          : bmTextColorDarkMode)),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                color: appStore.isDarkModeOn
                                    ? bmPrimaryColor
                                    : bmTextColorDarkMode,
                                size: 16),
                          ],
                        )
                      ],
                    ).paddingSymmetric(horizontal: 16),
                    20.height,
                    Observer(
                      builder: (_) {
                        final places = bmPlacesStore.recommendedCards;
                        if (places.isEmpty) {
                          return SizedBox(
                            height: 220,
                            child: Center(
                                child: Text('No recommendations yet',
                                    style: secondaryTextStyle(
                                        color: bmTextColorDarkMode))),
                          );
                        }
                        return HorizontalList(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          spacing: 16,
                          itemCount: places.length,
                          itemBuilder: (context, index) {
                            return BMCommonCardComponent(
                                element: places[index],
                                fullScreenComponent: false,
                                isFavList: false);
                          },
                        );
                      },
                    ),
                    40.height,
                  ],
                ).cornerRadiusWithClipRRectOnly(topRight: 40),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: BMVoiceSearchWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
