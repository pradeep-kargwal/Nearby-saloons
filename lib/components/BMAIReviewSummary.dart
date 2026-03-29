import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../services/BMAIService.dart';
import '../utils/BMColors.dart';

class BMAIReviewSummary extends StatefulWidget {
  final List<Map<String, dynamic>> reviews;

  const BMAIReviewSummary({Key? key, required this.reviews}) : super(key: key);

  @override
  State<BMAIReviewSummary> createState() => _BMAIReviewSummaryState();
}

class _BMAIReviewSummaryState extends State<BMAIReviewSummary> {
  String? _summary;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  Future<void> _generateSummary() async {
    if (widget.reviews.isEmpty) return;
    setState(() => _loading = true);
    final result = await BMAIService.summarizeReviews(widget.reviews);
    if (mounted) {
      setState(() {
        _summary = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reviews.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bmPrimaryColor.withOpacity(0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bmPrimaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: bmPrimaryColor, size: 18),
              6.width,
              Text('AI Review Summary',
                  style: boldTextStyle(size: 13, color: bmPrimaryColor)),
            ],
          ),
          8.height,
          if (_loading)
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: bmPrimaryColor,
                  ),
                ),
                8.width,
                Text('Analyzing reviews...',
                    style: secondaryTextStyle(size: 12)),
              ],
            )
          else if (_summary != null)
            Text(_summary!,
                style: primaryTextStyle(size: 13), textAlign: TextAlign.left),
        ],
      ),
    );
  }
}
