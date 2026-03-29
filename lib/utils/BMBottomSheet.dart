import 'package:beauty_master/components/BMCommentComponent.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../models/BMCommentModel.dart';
import '../models/BMMasterModel.dart';
import '../models/BMServiceListModel.dart';
import '../screens/BMCalenderScreen.dart';
import '../screens/BMCallScreen.dart';
import 'BMColors.dart';
import 'BMDataGenerator.dart';
import 'BMWidgets.dart';

void showFilterBottomSheet(BuildContext context) {
  int selectedSort = bmPlacesStore.currentSortIndex;

  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor:
          appStore.isDarkModeOn ? bmSecondBackgroundColorDark : Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: radiusOnly(topLeft: 30, topRight: 30)),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    titleText(title: 'Sort & Filter', size: 22),
                    IconButton(
                      onPressed: () => finish(context),
                      icon:
                          Icon(Icons.close_rounded, color: bmTextColorDarkMode),
                    ),
                  ],
                ),
                20.height,
                Text('Sort by',
                    style: boldTextStyle(
                        color:
                            appStore.isDarkModeOn ? white : bmSpecialColorDark,
                        size: 16)),
                16.height,
                _buildSortOption(
                  label: 'Nearest First',
                  subtitle: 'Places closest to you',
                  icon: Icons.near_me_outlined,
                  isSelected: selectedSort == 0,
                  onTap: () {
                    setState(() => selectedSort = 0);
                    bmPlacesStore.sortSearchResults(0);
                    Navigator.pop(context);
                  },
                ),
                _buildSortOption(
                  label: 'Top Rated',
                  subtitle: 'Highest rated places',
                  icon: Icons.star_outline,
                  isSelected: selectedSort == 1,
                  onTap: () {
                    setState(() => selectedSort = 1);
                    bmPlacesStore.sortSearchResults(1);
                    Navigator.pop(context);
                  },
                ),
                _buildSortOption(
                  label: 'Alphabetical (A-Z)',
                  subtitle: 'Sort by name',
                  icon: Icons.sort_by_alpha,
                  isSelected: selectedSort == 2,
                  onTap: () {
                    setState(() => selectedSort = 2);
                    bmPlacesStore.sortSearchResults(2);
                    Navigator.pop(context);
                  },
                ),
                _buildSortOption(
                  label: 'Most Reviewed',
                  subtitle: 'Places with most reviews',
                  icon: Icons.rate_review_outlined,
                  isSelected: selectedSort == 3,
                  onTap: () {
                    setState(() => selectedSort = 3);
                    bmPlacesStore.sortSearchResults(3);
                    Navigator.pop(context);
                  },
                ),
                24.height,
                AppButton(
                  shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32)),
                  child:
                      Text('Reset', style: boldTextStyle(color: Colors.white)),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  color: bmPrimaryColor,
                  onTap: () {
                    setState(() => selectedSort = 0);
                    bmPlacesStore.sortSearchResults(0);
                    Navigator.pop(context);
                  },
                ).center(),
                30.height,
              ],
            ).paddingAll(16),
          );
        });
      });
}

Widget _buildSortOption({
  required String label,
  required String subtitle,
  required IconData icon,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isSelected ? bmPrimaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? bmPrimaryColor : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isSelected ? bmPrimaryColor : bmPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: isSelected ? Colors.white : bmPrimaryColor, size: 22),
          ),
          14.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: boldTextStyle(
                        size: 14,
                        color: appStore.isDarkModeOn
                            ? white
                            : bmSpecialColorDark)),
                2.height,
                Text(subtitle, style: secondaryTextStyle(size: 11)),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle, color: bmPrimaryColor, size: 24),
        ],
      ),
    ),
  );
}

void showBookBottomSheet(BuildContext context, BMServiceListModel element) {}

void showCommentBottomSheet(BuildContext context) {}

void showSelectStaffBottomSheet(BuildContext context) {}
