import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/BMAIReviewSummary.dart';
import '../main.dart';
import '../models/BMCommonCardModel.dart';
import '../services/BMPlacesService.dart';
import '../utils/BMColors.dart';
import '../utils/BMWidgets.dart';
import '../utils/flutter_rating_bar.dart';
import '../utils/BMConstants.dart';

class BMSingleComponentScreen extends StatefulWidget {
  BMCommonCardModel element;
  BMSingleComponentScreen({required this.element});

  @override
  _BMSingleComponentScreenState createState() =>
      _BMSingleComponentScreenState();
}

class _BMSingleComponentScreenState extends State<BMSingleComponentScreen> {
  List<String> tabList = ['ABOUT', 'REVIEWS', 'PHOTOS', 'SERVICES'];
  int selectedTab = 0;
  bool _fetchingDetails = false;
  Uint8List? _heroPhotoBytes;
  bool _loadingHero = false;
  List<Uint8List> _allPhotos = [];
  bool _loadingPhotos = false;

  @override
  void initState() {
    setStatusBarColor(Colors.transparent);
    super.initState();
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    if (widget.element.placeId == null || widget.element.placeId!.isEmpty) {
      // No placeId - try searching by name to find it
      final lat = bmPlacesStore.userLat ?? 28.7483;
      final lng = bmPlacesStore.userLng ?? 77.1958;
      final results = await BMPlacesService.searchPlaces(
        lat: lat,
        lng: lng,
        query: widget.element.title,
      );
      if (results.isNotEmpty && results.first.placeId.isNotEmpty) {
        widget.element.placeId = results.first.placeId;
      } else {
        return;
      }
    }
    _fetchingDetails = true;
    if (mounted) setState(() {});
    try {
      final details =
          await BMPlacesService.getPlaceDetails(widget.element.placeId!);
      if (details != null && mounted) {
        setState(() {
          widget.element.phone = details.phone;
          widget.element.reviews = details.reviews
              .map((r) => <String, dynamic>{
                    'author_name': r.authorName,
                    'rating': r.rating,
                    'text': r.text,
                    'time': r.time,
                  })
              .toList();
          widget.element.allPhotoReferences = details.allPhotoReferences;
          print(
              'Details fetched for ${widget.element.title}: ${details.allPhotoReferences.length} photo refs');
          if (details.photoReference != null) {
            widget.element.photoReference = details.photoReference;
          }
          widget.element.rating = details.rating.toStringAsFixed(1);
          widget.element.comments = '${details.reviewCount} reviews';
          widget.element.website = details.website;
          widget.element.types = details.types;
          _fetchingDetails = false;
        });
        // Reload photos with the new references from Place Details
        if (details.allPhotoReferences.isNotEmpty) {
          _loadAllPhotos();
        }
        if (details.photoReference != null) {
          _loadHeroPhoto();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _fetchingDetails = false);
    }
  }

  Widget _buildHeroImage() {
    if (widget.element.photoReference != null &&
        widget.element.photoReference!.isNotEmpty) {
      return Image.network(
        BMPlacesService.getPhotoUrl(widget.element.photoReference!,
            maxWidth: 800),
        height: 280,
        width: context.width(),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(widget.element.image,
            height: 280, width: context.width(), fit: BoxFit.cover),
      );
    }
    if (_fetchingDetails) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 280,
          width: context.width(),
          color: Colors.white,
        ),
      );
    }
    return Image.asset(widget.element.image,
        height: 280, width: context.width(), fit: BoxFit.cover);
  }

  Future<void> _loadHeroPhoto() async {
    if (widget.element.photoReference != null &&
        widget.element.photoReference!.isNotEmpty) {
      _loadingHero = true;
      try {
        final url = BMPlacesService.getPhotoUrl(widget.element.photoReference!,
            maxWidth: 800);
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200 && mounted) {
          setState(() {
            _heroPhotoBytes = response.bodyBytes;
            _loadingHero = false;
          });
        } else {
          if (mounted) setState(() => _loadingHero = false);
        }
      } catch (e) {
        if (mounted) setState(() => _loadingHero = false);
      }
    }
  }

  Future<void> _loadAllPhotos() async {
    final allRefs = widget.element.allPhotoReferences ?? [];
    print('Loading ${allRefs.length} photos for ${widget.element.title}');
    if (allRefs.isEmpty) return;
    if (mounted) {
      setState(() {
        _loadingPhotos = true;
        _allPhotos.clear();
      });
    }
    final futures = allRefs.map((ref) async {
      try {
        final url = BMPlacesService.getPhotoUrl(ref, maxWidth: 600);
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200 && response.bodyBytes.length > 100) {
          return response.bodyBytes;
        }
      } catch (e) {}
      return null;
    });
    final results = await Future.wait(futures);
    if (mounted) {
      setState(() {
        for (var bytes in results) {
          if (bytes != null) _allPhotos.add(bytes);
        }
        _loadingPhotos = false;
        print('Loaded ${_allPhotos.length} photos successfully');
      });
    }
  }

  Future<void> _callPhone() async {
    final phone = widget.element.phone;
    if (phone != null && phone.isNotEmpty) {
      final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      try {
        await launchUrl(Uri.parse('tel:$cleanPhone'));
      } catch (e) {
        toast('Could not open dialer');
      }
    } else {
      toast('Phone number not available');
    }
  }

  Future<void> _openWhatsApp() async {
    final phone = widget.element.phone;
    if (phone != null && phone.isNotEmpty) {
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.isEmpty) {
        toast('Phone number not available');
        return;
      }
      final url =
          'https://wa.me/$cleanPhone?text=${Uri.encodeComponent("Hi! Are you currently available for appointments?")}';
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (e) {
        toast('Could not open WhatsApp');
      }
    } else {
      toast('Phone number not available');
    }
  }

  Future<void> _openDirections() async {
    if (widget.element.lat != null && widget.element.lng != null) {
      final url =
          'https://www.google.com/maps/dir/?api=1&destination=${widget.element.lat},${widget.element.lng}';
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (e) {
        toast('Could not open maps');
      }
    }
  }

  Future<void> _addToCalendar() async {
    final title = Uri.encodeComponent('Appointment at ${widget.element.title}');
    final details = Uri.encodeComponent(
        'Beauty appointment at ${widget.element.title}${widget.element.phone != null ? '\nPhone: ${widget.element.phone}' : ''}${widget.element.subtitle != null ? '\nAddress: ${widget.element.subtitle}' : ''}');
    final location = Uri.encodeComponent(widget.element.subtitle ?? '');

    // Default to tomorrow at 10:00 AM
    final now = DateTime.now().add(Duration(days: 1));
    final start = DateTime(now.year, now.month, now.day, 10, 0);
    final end = start.add(Duration(hours: 1));

    final startStr = start
            .toUtc()
            .toIso8601String()
            .replaceAll('-', '')
            .replaceAll(':', '')
            .split('.')
            .first +
        'Z';
    final endStr = end
            .toUtc()
            .toIso8601String()
            .replaceAll('-', '')
            .replaceAll(':', '')
            .split('.')
            .first +
        'Z';

    // Google Calendar URL
    final googleCalUrl =
        'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&details=$details&location=$location&dates=$startStr/$endStr';

    // ICS file for Outlook/Apple Calendar
    final icsContent = '''BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
DTSTART:$startStr
DTEND:$endStr
SUMMARY:Appointment at ${widget.element.title}
DESCRIPTION:Beauty appointment at ${widget.element.title}${widget.element.phone != null ? '\nPhone: ${widget.element.phone}' : ''}
LOCATION:${widget.element.subtitle ?? ''}
END:VEVENT
END:VCALENDAR''';

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add to Calendar',
                  style: boldTextStyle(
                      size: 18,
                      color: appStore.isDarkModeOn
                          ? Colors.white
                          : bmSpecialColorDark)),
              8.height,
              Text('Pick a date and time', style: secondaryTextStyle(size: 13)),
              16.height,
              ListTile(
                leading: Icon(Icons.calendar_today, color: bmPrimaryColor),
                title: Text('Tomorrow at 10:00 AM',
                    style: primaryTextStyle(size: 14)),
                subtitle:
                    Text('Tap to change', style: secondaryTextStyle(size: 12)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 90)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: 10, minute: 0),
                    );
                    if (time != null) {
                      final newStart = DateTime(date.year, date.month, date.day,
                          time.hour, time.minute);
                      final newEnd = newStart.add(Duration(hours: 1));
                      final newStartStr = newStart
                              .toUtc()
                              .toIso8601String()
                              .replaceAll(RegExp(r'[-:.]'), '')
                              .split('Z')
                              .first +
                          'Z';
                      final newEndStr = newEnd
                              .toUtc()
                              .toIso8601String()
                              .replaceAll(RegExp(r'[-:.]'), '')
                              .split('Z')
                              .first +
                          'Z';
                      final newUrl =
                          'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&details=$details&location=$location&dates=$newStartStr/$newEndStr';
                      finish(context);
                      await launchUrl(Uri.parse(newUrl),
                          mode: LaunchMode.externalApplication);
                    }
                  }
                },
              ),
              12.height,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        finish(context);
                        await launchUrl(Uri.parse(googleCalUrl),
                            mode: LaunchMode.externalApplication);
                      },
                      icon: Icon(Icons.calendar_month, color: bmPrimaryColor),
                      label: Text('Google Calendar',
                          style:
                              boldTextStyle(color: bmPrimaryColor, size: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: bmPrimaryColor),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  12.width,
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        finish(context);
                        // Download ICS file approach - open Apple/Outlook calendar
                        final icsUrl =
                            'data:text/calendar;charset=utf-8,${Uri.encodeComponent(icsContent)}';
                        await launchUrl(Uri.parse(googleCalUrl),
                            mode: LaunchMode.externalApplication);
                      },
                      icon: Icon(Icons.event, color: Colors.deepPurple),
                      label: Text('Outlook / Apple',
                          style: boldTextStyle(
                              color: Colors.deepPurple, size: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.deepPurple),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFavorite() {
    setState(() {
      widget.element.liked = !(widget.element.liked ?? false);
    });
    if (widget.element.liked == true) {
      if (!favList.any((e) => e.title == widget.element.title)) {
        favList.add(widget.element);
      }
      toast('Added to favorites');
    } else {
      favList.removeWhere((e) => e.title == widget.element.title);
      toast('Removed from favorites');
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: bmPrimaryColor, size: 20),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: secondaryTextStyle(size: 12)),
                2.height,
                Text(value, style: primaryTextStyle(size: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    if (_fetchingDetails) {
      return Padding(
          padding: EdgeInsets.all(32),
          child:
              Center(child: CircularProgressIndicator(color: bmPrimaryColor)));
    }
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.element.phone != null && widget.element.phone!.isNotEmpty)
            _buildInfoRow(Icons.phone, 'Phone', widget.element.phone!),
          if (widget.element.subtitle != null &&
              widget.element.subtitle!.isNotEmpty)
            _buildInfoRow(
                Icons.location_on, 'Address', widget.element.subtitle!),
          if (widget.element.distance != null &&
              widget.element.distance!.isNotEmpty)
            _buildInfoRow(
                Icons.directions, 'Distance', widget.element.distance!),
          if (widget.element.types != null && widget.element.types!.isNotEmpty)
            _buildInfoRow(
                Icons.category,
                'Category',
                widget.element.types!
                    .where((t) =>
                        !['establishment', 'point_of_interest'].contains(t))
                    .map((t) => t
                        .replaceAll('_', ' ')
                        .split(' ')
                        .map((w) => w.isNotEmpty
                            ? w[0].toUpperCase() + w.substring(1)
                            : w)
                        .join(' '))
                    .join(', ')),
          if (widget.element.website != null &&
              widget.element.website!.isNotEmpty)
            _buildInfoRow(Icons.language, 'Website', widget.element.website!),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    final reviews = widget.element.reviews;
    if (reviews == null || reviews.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(32),
        child: Center(
            child: Text(
                _fetchingDetails
                    ? 'Loading reviews...'
                    : 'No reviews available',
                style: secondaryTextStyle(color: bmTextColorDarkMode))),
      );
    }
    return Column(
      children: [
        BMAIReviewSummary(reviews: reviews),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: context.cardColor, borderRadius: radius(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(review['author_name'] ?? 'Anonymous',
                          style: boldTextStyle(size: 14)),
                      Row(children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        4.width,
                        Text('${review['rating'] ?? 0}',
                            style: boldTextStyle(size: 13)),
                      ]),
                    ],
                  ),
                  8.height,
                  Text(review['text'] ?? '',
                      style: secondaryTextStyle(size: 13)),
                ],
              ),
            );
          },
        ),
        if (reviews.length >= 5)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Showing up to 5 most relevant reviews (API limit)',
                style: secondaryTextStyle(size: 11, color: Colors.grey)),
          ),
      ],
    );
  }

  Widget _buildPhotosTab() {
    if (_fetchingDetails) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: 4,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(color: Colors.white),
            );
          },
        ),
      );
    }

    final photoRefs = widget.element.allPhotoReferences ?? [];
    if (photoRefs.isEmpty) {
      if (widget.element.photoReference != null) {
        photoRefs.add(widget.element.photoReference!);
      }
    }

    if (photoRefs.isEmpty) {
      return Padding(
          padding: EdgeInsets.all(32),
          child: Center(
              child: Text('No photos available', style: secondaryTextStyle())));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: photoRefs.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: radius(12),
          child: Image.network(
            BMPlacesService.getPhotoUrl(photoRefs[index], maxWidth: 600),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: bmPrimaryColor,
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStore.isDarkModeOn
          ? appStore.scaffoldBackground!
          : bmLightScaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchFullDetails();
        },
        color: bmPrimaryColor,
        backgroundColor: context.cardColor,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Stack(
                children: [
                  _buildHeroImage(),
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            child:
                                Icon(Icons.arrow_back, color: bmPrimaryColor),
                            decoration: BoxDecoration(
                                borderRadius: radius(100),
                                color: context.cardColor),
                            padding: EdgeInsets.all(8),
                          ).onTap(() {
                            finish(context);
                          }, borderRadius: radius(100)),
                          GestureDetector(
                            onTap: _toggleFavorite,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  borderRadius: radius(100),
                                  color: context.cardColor),
                              child: Icon(
                                (widget.element.liked ?? false)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: (widget.element.liked ?? false)
                                    ? Colors.red
                                    : bmPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(16),
                color: appStore.isDarkModeOn
                    ? appStore.scaffoldBackground!
                    : bmLightScaffoldBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleText(title: widget.element.title),
                    8.height,
                    Text(widget.element.subtitle ?? '',
                        style: secondaryTextStyle(
                            color: appStore.isDarkModeOn
                                ? Colors.white
                                : bmPrimaryColor,
                            size: 12)),
                    8.height,
                    if (widget.element.phone != null &&
                        widget.element.phone!.isNotEmpty)
                      Row(children: [
                        Icon(Icons.phone, color: bmPrimaryColor, size: 16),
                        4.width,
                        Text(widget.element.phone!,
                            style: secondaryTextStyle(
                                color: appStore.isDarkModeOn
                                    ? Colors.white
                                    : bmPrimaryColor)),
                      ]),
                    if (_fetchingDetails &&
                        (widget.element.phone == null ||
                            widget.element.phone!.isNotEmpty))
                      Row(children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: bmPrimaryColor)),
                        8.width,
                        Text('Loading details...',
                            style: secondaryTextStyle(size: 12)),
                      ]),
                    8.height,
                    Row(
                      children: [
                        Text(widget.element.rating ?? '0',
                            style: boldTextStyle()),
                        2.width,
                        RatingBar(
                          initialRating:
                              double.tryParse(widget.element.rating ?? '0') ??
                                  0,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 18,
                          itemPadding: EdgeInsets.symmetric(horizontal: 0),
                          itemBuilder: (context, _) =>
                              Icon(Icons.star, color: Colors.amber),
                          onRatingUpdate: (rating) {},
                        ),
                        6.width,
                        Text(widget.element.comments ?? '0',
                            style:
                                secondaryTextStyle(color: bmTextColorDarkMode)),
                      ],
                    ),
                    12.height,
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _buildActionButton(
                            icon: Icons.call,
                            label: 'Book Now',
                            color: bmPrimaryColor,
                            onTap: _callPhone),
                        _buildActionButton(
                            icon: Icons.calendar_month,
                            label: 'Add to Calendar',
                            color: Colors.deepPurple,
                            onTap: _addToCalendar),
                        _buildActionButton(
                            icon: Icons.chat,
                            label: 'WhatsApp',
                            color: Color(0xFF25D366),
                            onTap: _openWhatsApp),
                        _buildActionButton(
                            icon: Icons.directions,
                            label: 'Directions',
                            color: Colors.blue,
                            onTap: _openDirections),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: appStore.isDarkModeOn
                      ? bmSecondBackgroundColorDark
                      : bmSecondBackgroundColorLight,
                  borderRadius: radiusOnly(topLeft: 32, topRight: 32),
                ),
                child: Column(
                  children: [
                    16.height,
                    HorizontalList(
                      itemCount: tabList.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: radius(32),
                            color: selectedTab == index
                                ? bmPrimaryColor
                                : Colors.transparent,
                          ),
                          padding: EdgeInsets.all(8),
                          child: Text(tabList[index],
                              style: boldTextStyle(
                                size: 12,
                                color: selectedTab == index
                                    ? white
                                    : appStore.isDarkModeOn
                                        ? bmPrimaryColor
                                        : bmSpecialColorDark,
                              )).onTap(() {
                            selectedTab = index;
                            setState(() {});
                          }),
                        );
                      },
                    ),
                    if (selectedTab == 0) _buildAboutTab(),
                    if (selectedTab == 1) _buildReviewsTab(),
                    if (selectedTab == 2) _buildPhotosTab(),
                    if (selectedTab == 3) _buildServicesTab(),
                    80.height,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const Map<String, Map<String, dynamic>> _serviceMap = {
    'hair_care': {'name': 'Hair Care', 'icon': Icons.content_cut},
    'beauty_salon': {
      'name': 'Beauty Salon',
      'icon': Icons.face_retouching_natural
    },
    'spa': {'name': 'Spa', 'icon': Icons.spa},
    'barber': {'name': 'Barbershop', 'icon': Icons.content_cut},
    'nail_salon': {'name': 'Nail Salon', 'icon': Icons.brush},
    'skin_care': {'name': 'Skin Care', 'icon': Icons.local_hospital},
    'waxing': {'name': 'Waxing', 'icon': Icons.waves},
    'hair_replacement': {'name': 'Hair Replacement', 'icon': Icons.content_cut},
    'makeup_artist': {'name': 'Makeup Artist', 'icon': Icons.palette},
    'permanent_makeup': {'name': 'Permanent Makeup', 'icon': Icons.palette},
    'tanning': {'name': 'Tanning', 'icon': Icons.wb_sunny},
    'tattoo': {'name': 'Tattoo', 'icon': Icons.brush},
    'eyebrow_threading': {
      'name': 'Eyebrow Threading',
      'icon': Icons.remove_red_eye
    },
  };

  Widget _buildServicesTab() {
    final types = widget.element.types ?? [];
    final services = types
        .where((t) => _serviceMap.containsKey(t))
        .map((t) => _serviceMap[t]!)
        .toList();

    if (services.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('No specific services listed',
              style: secondaryTextStyle(color: bmTextColorDarkMode)),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: services.map((s) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bmPrimaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: bmPrimaryColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(s['icon'] as IconData, color: bmPrimaryColor, size: 18),
                6.width,
                Text(s['name'] as String,
                    style: boldTextStyle(size: 13, color: bmPrimaryColor)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color),
            color: appStore.isDarkModeOn
                ? appStore.scaffoldBackground!
                : bmLightScaffoldBackgroundColor,
            borderRadius: radius(32),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 18),
            6.width,
            Text(label, style: boldTextStyle(color: color, size: 13)),
          ]),
        ),
      ),
    );
  }
}
