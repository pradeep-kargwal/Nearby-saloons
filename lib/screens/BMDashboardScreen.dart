import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../fragments/BMFavouritesFragment.dart';
import '../fragments/BMHomeFragment.dart';
import '../fragments/BMMapFragment.dart';
import '../fragments/BMMoreFragment.dart';
import '../fragments/BMSearchFragment.dart';
import '../main.dart';
import '../utils/BMColors.dart';

class BMDashboardScreen extends StatefulWidget {
  bool flag;
  BMDashboardScreen({required this.flag});

  @override
  _BMDashboardScreenState createState() => _BMDashboardScreenState();
}

class _BMDashboardScreenState extends State<BMDashboardScreen> {
  int selectedTab = 0;

  Widget getFragment() {
    switch (selectedTab) {
      case 0:
        return BMHomeFragment();
      case 1:
        return BMSearchFragment();
      case 2:
        return BMMapFragment();
      case 3:
        return BMFavouritesFragment();
      default:
        return BMMoreFragment();
    }
  }

  @override
  void initState() {
    setStatusBarColor(appStore.isDarkModeOn
        ? appStore.scaffoldBackground!
        : bmLightScaffoldBackgroundColor);
    super.initState();
  }

  @override
  void dispose() {
    if (widget.flag) {
      setStatusBarColor(appStore.isDarkModeOn
          ? appStore.scaffoldBackground!
          : bmLightScaffoldBackgroundColor);
    } else {
      setStatusBarColor(Colors.transparent);
    }
    super.dispose();
  }

  Color getDashboardColor() {
    if (!appStore.isDarkModeOn) {
      return (selectedTab == 1)
          ? bmSecondBackgroundColorLight
          : bmLightScaffoldBackgroundColor;
    } else {
      return (selectedTab == 1)
          ? bmSecondBackgroundColorDark
          : appStore.scaffoldBackground!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getDashboardColor(),
      body: getFragment(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (int index) {
          setState(() => selectedTab = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: context.cardColor,
        unselectedItemColor: bmPrimaryColor,
        selectedItemColor: bmPrimaryColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: selectedTab,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 24),
            activeIcon: Icon(Icons.home, size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 24),
            activeIcon: Icon(Icons.search, size: 24),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined, size: 24),
            activeIcon: Icon(Icons.map, size: 24),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border, size: 24),
            activeIcon: Icon(Icons.favorite, size: 24),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz, size: 24),
            activeIcon: Icon(Icons.more_horiz, size: 24),
            label: 'More',
          ),
        ],
      ).cornerRadiusWithClipRRectOnly(topLeft: 32, topRight: 32),
    );
  }
}
