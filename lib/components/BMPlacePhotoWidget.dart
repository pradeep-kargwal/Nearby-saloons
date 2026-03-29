import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/BMPlacesService.dart';

class BMPlacePhotoWidget extends StatelessWidget {
  final String? photoReference;
  final String fallbackAsset;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const BMPlacePhotoWidget({
    Key? key,
    required this.photoReference,
    required this.fallbackAsset,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : super(key: key);

  Future<Uint8List?> _fetchPhoto() async {
    if (photoReference == null || photoReference!.isEmpty) return null;
    try {
      final url = BMPlacesService.getPhotoUrl(photoReference!);
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error fetching photo: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _fetchPhoto(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: Image.memory(
              snapshot.data!,
              width: width,
              height: height,
              fit: fit,
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: borderRadius,
            ),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Image.asset(fallbackAsset,
              width: width, height: height, fit: fit),
        );
      },
    );
  }
}
