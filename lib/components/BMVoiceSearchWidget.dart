import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../main.dart';
import '../services/BMPlacesService.dart';
import '../screens/BMNearbyServicesScreen.dart';
import '../utils/BMColors.dart';

class BMVoiceSearchWidget extends StatefulWidget {
  @override
  State<BMVoiceSearchWidget> createState() => _BMVoiceSearchWidgetState();
}

class _BMVoiceSearchWidgetState extends State<BMVoiceSearchWidget>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isProcessing = false;
  bool _speechAvailable = false;
  String _transcript = '';
  String _statusText = '';
  bool _expanded = false;
  bool _hasResult = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkSpeech();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _checkSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if ((status == 'done' || status == 'notListening') &&
            mounted &&
            _isListening) {
          setState(() {
            _isListening = false;
          });
          _pulseController.stop();
          _pulseController.reset();
          if (_transcript.trim().isNotEmpty) {
            setState(() {
              _hasResult = true;
              _statusText = '"${_transcript.trim()}"';
            });
          } else {
            setState(() {
              _statusText = 'No speech detected. Try again.';
            });
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) setState(() => _expanded = false);
            });
          }
        }
      },
      onError: (error) {
        print('Speech error: ${error.errorMsg}');
        if (mounted) {
          setState(() {
            _isListening = false;
            _statusText = 'Could not hear you';
          });
          _pulseController.stop();
          _pulseController.reset();
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) setState(() => _expanded = false);
          });
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (_isProcessing) return;
    _hasResult = false;
    _transcript = '';

    if (!_speechAvailable) {
      await _checkSpeech();
      if (!_speechAvailable) {
        setState(() {
          _expanded = true;
          _statusText = 'Speech not available';
        });
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) setState(() => _expanded = false);
        });
        return;
      }
    }

    setState(() {
      _isListening = true;
      _expanded = true;
      _statusText = 'Listening...';
    });
    _pulseController.repeat(reverse: true);

    try {
      await _speech.listen(
        onResult: (result) {
          print(
              'Speech result: ${result.recognizedWords}, final: ${result.finalResult}');
          _transcript = result.recognizedWords;
          if (mounted) {
            setState(() {
              _statusText = _transcript;
            });
          }
        },
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 2),
        partialResults: true,
        localeId: 'en_IN',
      );
    } catch (e) {
      print('Speech listen error: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusText = 'Failed to start listening';
        });
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  void _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
    _pulseController.stop();
    _pulseController.reset();
  }

  Future<void> _searchWithQuery(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _hasResult = false;
      _statusText = 'Searching "$query"...';
    });

    try {
      final lat = bmPlacesStore.userLat ?? 28.6139;
      final lng = bmPlacesStore.userLng ?? 77.2090;

      final places = await BMPlacesService.searchPlaces(
        lat: lat,
        lng: lng,
        query: query,
      ).timeout(Duration(seconds: 20));

      if (!mounted) return;

      if (places.isEmpty) {
        setState(() {
          _isProcessing = false;
          _statusText = 'No places found';
        });
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) setState(() => _expanded = false);
        });
        return;
      }

      bmPlacesStore.updateFromVoiceSearch(places);

      setState(() => _isProcessing = false);
      BMNearbyServicesScreen(
        screenTitle: 'Results for "$query"',
      ).launch(context);
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Search failed. Try again.';
        });
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) setState(() => _expanded = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: _expanded ? 52 : 0,
          child: _expanded
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        appStore.isDarkModeOn ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isListening)
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.red)),
                      if (_isProcessing)
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: bmPrimaryColor)),
                      8.width,
                      Flexible(
                        child: Text(_statusText,
                            style: TextStyle(
                                fontSize: 13,
                                color: appStore.isDarkModeOn
                                    ? Colors.white70
                                    : Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      // Search button - appears after speech is captured
                      if (_hasResult && !_isListening && !_isProcessing)
                        GestureDetector(
                          onTap: () => _searchWithQuery(_transcript.trim()),
                          child: Container(
                            margin: EdgeInsets.only(left: 8),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: bmPrimaryColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search,
                                    color: Colors.white, size: 16),
                                4.width,
                                Text('Search',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      // Stop button during listening
                      if (_isListening)
                        GestureDetector(
                          onTap: _stopListening,
                          child: Container(
                            margin: EdgeInsets.only(left: 8),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('Stop',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                )
              : SizedBox.shrink(),
        ),
        if (_expanded) 8.height,
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _pulseAnimation.value : 1.0,
              child: GestureDetector(
                onTap: _isProcessing
                    ? null
                    : (_isListening ? _stopListening : _startListening),
                child: Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? Colors.red
                        : _isProcessing
                            ? bmPrimaryColor.withOpacity(0.7)
                            : bmPrimaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.red : bmPrimaryColor)
                            .withOpacity(0.4),
                        blurRadius: _isListening ? 16 : 8,
                        spreadRadius: _isListening ? 4 : 0,
                      ),
                    ],
                  ),
                  child: _isProcessing
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Icon(_isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white, size: 24),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
