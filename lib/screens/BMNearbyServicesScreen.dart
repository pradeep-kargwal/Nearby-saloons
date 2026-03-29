import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:shimmer/shimmer.dart';

import '../components/BMCommonCardComponent.dart';
import '../components/BMFloatingActionComponent.dart';
import '../components/BMSkeleton.dart';
import '../main.dart';
import '../utils/BMColors.dart';
import '../utils/BMWidgets.dart';

class BMNearbyServicesScreen extends StatefulWidget {
  final String? category;
  final String? screenTitle;

  BMNearbyServicesScreen({this.category, this.screenTitle});

  @override
  State<BMNearbyServicesScreen> createState() => _BMNearbyServicesScreenState();
}

class _BMNearbyServicesScreenState extends State<BMNearbyServicesScreen> {
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (widget.category != null && widget.category != 'ALL') {
      _fetching = true;
      bmPlacesStore.fetchPlacesByType(widget.category!).then((_) {
        if (mounted) setState(() => _fetching = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.screenTitle ?? 'Nearby Services';
    final isCategorySearch =
        widget.category != null && widget.category != 'ALL';

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
        title: titleText(title: title),
      ),
      body: Observer(
        builder: (_) {
          final loading = isCategorySearch
              ? bmPlacesStore.isSearchLoading
              : bmPlacesStore.isLoading;

          if (loading || _fetching) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => BMListItemSkeleton(),
              ),
            );
          }

          final places = isCategorySearch
              ? bmPlacesStore.searchResults
              : bmPlacesStore.placeCards;

          if (places.isEmpty) {
            return Center(
              child: Text('No places found for $title',
                  style: secondaryTextStyle()),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (isCategorySearch) {
                await bmPlacesStore.fetchPlacesByType(widget.category!);
              } else {
                await bmPlacesStore.fetchNearbyPlaces();
              }
            },
            color: bmPrimaryColor,
            backgroundColor: context.cardColor,
            child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              itemCount: places.length,
              itemBuilder: (context, index) {
                return BMCommonCardComponent(
                  key: ValueKey(
                      '${places[index].placeId ?? places[index].title}_$index'),
                  element: places[index],
                  fullScreenComponent: true,
                  isFavList: false,
                ).paddingSymmetric(vertical: 8);
              },
            ),
          );
        },
      ),
      floatingActionButton: BMFloatingActionComponent(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
