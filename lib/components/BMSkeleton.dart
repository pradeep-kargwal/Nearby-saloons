import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:shimmer/shimmer.dart';

class BMSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const BMSkeleton({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class BMCardSkeleton extends StatelessWidget {
  final bool isHorizontal;
  const BMCardSkeleton({Key? key, this.isHorizontal = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isHorizontal ? 250 : double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BMSkeleton(
            width: isHorizontal ? 250 : double.infinity,
            height: 160,
            borderRadius: 32,
          ),
          14.height,
          BMSkeleton(width: 150, height: 14),
          8.height,
          BMSkeleton(width: 200, height: 10),
          8.height,
          Row(
            children: [
              BMSkeleton(width: 60, height: 12),
              16.width,
              BMSkeleton(width: 80, height: 12),
            ],
          ),
          12.height,
        ],
      ).paddingSymmetric(horizontal: 12),
    );
  }
}

class BMListItemSkeleton extends StatelessWidget {
  const BMListItemSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          BMSkeleton(width: 80, height: 100, borderRadius: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BMSkeleton(width: 140, height: 14),
                  8.height,
                  BMSkeleton(width: double.infinity, height: 10),
                  6.height,
                  BMSkeleton(width: 100, height: 10),
                  6.height,
                  BMSkeleton(width: 80, height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BMSearchResultSkeleton extends StatelessWidget {
  const BMSearchResultSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(5, (index) => BMListItemSkeleton()),
      ),
    );
  }
}

class BMHomeSkeleton extends StatelessWidget {
  const BMHomeSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
          ),
          20.height,
          // Top Services skeleton
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: BMSkeleton(width: 100, height: 16),
          ),
          16.height,
          // Horizontal list skeleton
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    BMSkeleton(width: 60, height: 60, borderRadius: 32),
                    8.height,
                    BMSkeleton(width: 50, height: 10),
                  ],
                ),
              ),
            ),
          ),
          20.height,
          // Section title skeleton
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: BMSkeleton(width: 120, height: 16),
          ),
          16.height,
          // Horizontal cards skeleton
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: 2,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(right: 16),
                child: BMCardSkeleton(isHorizontal: true),
              ),
            ),
          ),
          20.height,
          // Section title skeleton
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: BMSkeleton(width: 140, height: 16),
          ),
          16.height,
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: 2,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(right: 16),
                child: BMCardSkeleton(isHorizontal: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
