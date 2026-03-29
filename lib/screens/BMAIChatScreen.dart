import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../models/BMCommonCardModel.dart';
import '../screens/BMSingleComponentScreen.dart';
import '../services/BMAIService.dart';
import '../services/BMPlacesService.dart';
import '../utils/BMColors.dart';

class BMAIChatScreen extends StatefulWidget {
  final String? initialQuery;

  BMAIChatScreen({this.initialQuery});

  @override
  _BMAIChatScreenState createState() => _BMAIChatScreenState();
}

class _BMAIChatScreenState extends State<BMAIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text: 'Hi! I\'m your beauty assistant. Ask me anything like:\n\n'
          '- "Best salon for bridal makeup near me"\n'
          '- "Affordable nail salons nearby"\n'
          '- "Top rated hair spas within 5 km"\n'
          '- "Salons open now with threading services"',
      isUser: false,
    ));

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = widget.initialQuery!;
        _sendMessage();
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final parsed = await BMAIService.parseSearchQuery(text);
      final searchText = parsed['search_text'] ?? text;
      final placeType = parsed['type'] ?? '';
      final minRating = (parsed['min_rating'] ?? 0.0).toDouble();

      final lat = bmPlacesStore.userLat ?? 28.6139;
      final lng = bmPlacesStore.userLng ?? 77.2090;

      String searchQuery = searchText;
      if (placeType.isNotEmpty) {
        searchQuery = '$searchText $placeType';
      }

      final places = await BMPlacesService.searchPlaces(
        lat: lat,
        lng: lng,
        query: searchQuery,
      );

      var filteredPlaces = places;
      if (minRating > 0) {
        filteredPlaces =
            filteredPlaces.where((p) => p.rating >= minRating).toList();
      }

      if (filteredPlaces.isEmpty) {
        setState(() {
          _messages.add(_ChatMessage(
            text:
                'I couldn\'t find any places matching "$searchText". Try a different search term.',
            isUser: false,
          ));
          _isLoading = false;
        });
        return;
      }

      final placeDescriptions = filteredPlaces
          .take(8)
          .map((p) =>
              '${p.name}: ${p.rating} rating, ${p.reviewCount} reviews, at ${p.address}')
          .toList();

      final aiResponse =
          await BMAIService.chatResponse(text, placeDescriptions);

      // Convert to BMCommonCardModel for tappable cards
      final placeCards = filteredPlaces
          .take(5)
          .map((p) => BMCommonCardModel(
                image: 'images/salon_one.jpg',
                title: p.name,
                subtitle: p.address,
                rating: p.rating.toStringAsFixed(1),
                comments: '${p.reviewCount} reviews',
                saveTag: false,
                liked: false,
                placeId: p.placeId,
                phone: p.phone,
                photoReference: p.photoReference,
                lat: p.lat,
                lng: p.lng,
                types: p.types,
              ))
          .toList();

      setState(() {
        _messages.add(_ChatMessage(
          text: aiResponse,
          isUser: false,
          placeCards: placeCards,
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          text: 'Sorry, something went wrong. Please try again.',
          isUser: false,
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bmPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, color: bmPrimaryColor, size: 20),
            ),
            8.width,
            Text('AI Beauty Assistant',
                style: boldTextStyle(
                    color: appStore.isDarkModeOn
                        ? Colors.white
                        : bmSpecialColorDark,
                    size: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildLoadingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: context.width() * 0.85),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? bmPrimaryColor
                    : (appStore.isDarkModeOn ? Colors.grey[800] : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft:
                      message.isUser ? Radius.circular(16) : Radius.circular(4),
                  bottomRight:
                      message.isUser ? Radius.circular(4) : Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? Colors.white
                      : (appStore.isDarkModeOn ? Colors.white : Colors.black87),
                  fontSize: 14,
                ),
              ),
            ),
            if (message.placeCards != null && message.placeCards!.isNotEmpty)
              ...message.placeCards!.map((card) => _buildPlaceCard(card)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(BMCommonCardModel card) {
    return GestureDetector(
      onTap: () {
        BMSingleComponentScreen(element: card).launch(context);
      },
      child: Container(
        margin: EdgeInsets.only(top: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appStore.isDarkModeOn ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  card.photoReference != null && card.photoReference!.isNotEmpty
                      ? Image.network(
                          BMPlacesService.getPhotoUrl(card.photoReference!),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Icon(Icons.store, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: Icon(Icons.store, color: Colors.grey),
                        ),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.title,
                      style: boldTextStyle(
                          size: 13,
                          color: appStore.isDarkModeOn
                              ? Colors.white
                              : bmSpecialColorDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  4.height,
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 14),
                      4.width,
                      Text(card.rating ?? '0', style: boldTextStyle(size: 12)),
                      4.width,
                      Text(card.comments ?? '',
                          style: secondaryTextStyle(size: 11)),
                    ],
                  ),
                  2.height,
                  Text(card.subtitle ?? '',
                      style: secondaryTextStyle(size: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: bmPrimaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appStore.isDarkModeOn ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: bmPrimaryColor,
              ),
            ),
            8.width,
            Text('Thinking...', style: secondaryTextStyle()),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appStore.isDarkModeOn ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: appStore.isDarkModeOn
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  style: TextStyle(
                      color: appStore.isDarkModeOn
                          ? Colors.white
                          : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Ask about salons, spas, beauty services...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            8.width,
            GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey : bmPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<BMCommonCardModel>? placeCards;

  _ChatMessage({required this.text, required this.isUser, this.placeCards});
}
