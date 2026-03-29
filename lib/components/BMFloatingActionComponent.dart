import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../utils/BMBottomSheet.dart';
import '../utils/BMColors.dart';

class BMFloatingActionComponent extends StatelessWidget {
  const BMFloatingActionComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration:
          BoxDecoration(color: bmTextColorDarkMode, borderRadius: radius(32)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('images/adjust.png', height: 20, color: Colors.white),
          8.width,
          Text('Filter', style: boldTextStyle(color: Colors.white, size: 14))
              .onTap(() {
            showFilterBottomSheet(context);
          }),
        ],
      ),
    );
  }
}
