import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:shimmer/shimmer.dart';

import '../main.dart';
import '../models/BMCommonCardModel.dart';
import '../screens/BMSingleComponentScreen.dart';
import '../services/BMPlacesService.dart';
import '../utils/BMColors.dart';

class BMCommonCardComponent extends StatefulWidget {
  BMCommonCardModel element;
  bool fullScreenComponent;
  bool isFavList;

  BMCommonCardComponent(
      {Key? key,
      required this.element,
      required this.fullScreenComponent,
      required this.isFavList})
      : super(key: key);

  @override
  State<BMCommonCardComponent> createState() => _BMCommonCardComponentState();
}

class _BMCommonCardComponentState extends State<BMCommonCardComponent> {
  Uint8List? _photoBytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  @override
  void didUpdateWidget(covariant BMCommonCardComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload photo when card data changes (e.g. after sorting)
    if (oldWidget.element.placeId != widget.element.placeId ||
        oldWidget.element.title != widget.element.title) {
      _photoBytes = null;
      _loading = false;
      _loadPhoto();
    }
  }

  Future<void> _loadPhoto() async {
    if (widget.element.photoReference != null &&
        widget.element.photoReference!.isNotEmpty) {
      _loading = true;
      try {
        final url = BMPlacesService.getPhotoUrl(widget.element.photoReference!);
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200 && mounted) {
          setState(() {
            _photoBytes = response.bodyBytes;
            _loading = false;
          });
        } else {
          if (mounted) setState(() => _loading = false);
        }
      } catch (e) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Widget _buildImage() {
    final double w = widget.fullScreenComponent ? context.width() - 32 : 250;
    final double h = 160;
    final borderRadius = BorderRadius.only(
        topLeft: Radius.circular(32), topRight: Radius.circular(32));

    if (_photoBytes != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child:
            Image.memory(_photoBytes!, width: w, height: h, fit: BoxFit.cover),
      );
    }
    if (_loading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(widget.element.image,
          width: w, height: h, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.fullScreenComponent ? context.width() - 32 : 250,
      decoration:
          BoxDecoration(color: context.cardColor, borderRadius: radius(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(),
          10.height,
          Text(
            widget.element.title,
            style: boldTextStyle(
                size: 16,
                color:
                    appStore.isDarkModeOn ? Colors.white : bmSpecialColorDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ).paddingSymmetric(horizontal: 10),
          4.height,
          Text(
            widget.element.subtitle ?? '',
            style: secondaryTextStyle(
                color: appStore.isDarkModeOn
                    ? bmTextColorDarkMode
                    : bmPrimaryColor,
                size: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ).paddingSymmetric(horizontal: 10),
          6.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  4.width,
                  Text(widget.element.rating ?? '0',
                      style: boldTextStyle(size: 14)),
                  2.width,
                  Text('(${widget.element.comments ?? '0'})',
                      style: secondaryTextStyle(
                          color: appStore.isDarkModeOn
                              ? bmTextColorDarkMode
                              : bmPrimaryColor,
                          size: 11)),
                ],
              ),
              if (widget.element.distance != null &&
                  widget.element.distance!.isNotEmpty)
                Text(widget.element.distance!,
                    style: secondaryTextStyle(
                        color: appStore.isDarkModeOn
                            ? bmTextColorDarkMode
                            : bmPrimaryColor,
                        size: 11)),
            ],
          ).paddingSymmetric(horizontal: 10),
          12.height,
        ],
      ),
    ).onTap(() {
      BMSingleComponentScreen(element: widget.element).launch(context);
    });
  }
}
