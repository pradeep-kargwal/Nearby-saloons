import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../components/BMCommonCardComponent.dart';
import '../main.dart';
import '../utils/BMColors.dart';
import '../utils/BMConstants.dart';
import '../utils/BMWidgets.dart';

class BMFavouritesFragment extends StatefulWidget {
  const BMFavouritesFragment({Key? key}) : super(key: key);

  @override
  State<BMFavouritesFragment> createState() => _BMFavouritesFragmentState();
}

class _BMFavouritesFragmentState extends State<BMFavouritesFragment> {
  @override
  void initState() {
    setStatusBarColor(bmSpecialColor);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStore.isDarkModeOn
          ? appStore.scaffoldBackground!
          : bmLightScaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: titleText(title: 'Favorites'),
            ),
          ),
          Expanded(
            child: favList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_border,
                            size: 64, color: bmPrimaryColor),
                        16.height,
                        Text('No favorites yet',
                            style: boldTextStyle(
                                color: appStore.isDarkModeOn
                                    ? Colors.white
                                    : bmSpecialColorDark,
                                size: 18)),
                        8.height,
                        Text('Tap the heart icon on any place to save it here',
                            style:
                                secondaryTextStyle(color: bmTextColorDarkMode),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: favList.length,
                    itemBuilder: (context, index) {
                      return BMCommonCardComponent(
                        fullScreenComponent: true,
                        element: favList[index],
                        isFavList: true,
                      ).paddingSymmetric(vertical: 8);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
