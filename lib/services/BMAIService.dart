import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/BMConstants.dart';

class BMAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openAIApiKey',
      };

  // Natural Language Search - convert user query into search parameters
  static Future<Map<String, dynamic>> parseSearchQuery(String userQuery) async {
    final messages = [
      {
        'role': 'system',
        'content':
            '''You are a beauty salon search assistant. Parse the user's natural language query into structured search parameters.
Return ONLY valid JSON with these fields:
- "search_text": string (the main search query for Google Places)
- "type": string (one of: beauty_salon, hair_care, spa, nail_salon, or empty for all)
- "keywords": list of strings (relevant keywords extracted from query)
- "min_rating": double (0.0 if not specified)
- "max_price": int (0 if not specified, 1-4 scale)
- "sort_by": string (one of: distance, rating, price, relevance)
- "open_now": boolean (true if user asks for open places)
Example: "best salon for bridal makeup near me" -> {"search_text":"bridal makeup salon","type":"beauty_salon","keywords":["bridal","makeup"],"min_rating":4.0,"max_price":0,"sort_by":"rating","open_now":false}'''
      },
      {'role': 'user', 'content': userQuery},
    ];

    final response = await _callOpenAI(messages, maxTokens: 200);
    if (response != null) {
      try {
        return json.decode(response);
      } catch (e) {
        return {
          'search_text': userQuery,
          'type': '',
          'keywords': [],
          'min_rating': 0.0,
          'max_price': 0,
          'sort_by': 'relevance',
          'open_now': false,
        };
      }
    }
    return {
      'search_text': userQuery,
      'type': '',
      'keywords': [],
      'min_rating': 0.0,
      'max_price': 0,
      'sort_by': 'relevance',
      'open_now': false,
    };
  }

  // Summarize reviews
  static Future<String> summarizeReviews(
      List<Map<String, dynamic>> reviews) async {
    if (reviews.isEmpty) return 'No reviews available to summarize.';

    final reviewsText = reviews
        .take(10)
        .map((r) => '- ${r['author_name']}: ${r['rating']}★ "${r['text']}"')
        .join('\n');

    final messages = [
      {
        'role': 'system',
        'content':
            'Summarize these salon reviews in 2-3 concise sentences. Highlight what customers love and any common complaints. Be specific about services mentioned (hair, nails, spa, etc). Keep it under 100 words.'
      },
      {
        'role': 'user',
        'content': 'Reviews:\n$reviewsText',
      },
    ];

    return await _callOpenAI(messages, maxTokens: 150) ??
        'Unable to summarize reviews at this time.';
  }

  // Chat-style discovery
  static Future<String> chatResponse(
      String userMessage, List<String> nearbyPlaces) async {
    final placesContext = nearbyPlaces.join(', ');

    final messages = [
      {
        'role': 'system',
        'content':
            '''You are a friendly beauty salon assistant helping users find the best beauty services nearby.
You have access to these nearby places: $placesContext

Help users by:
- Suggesting places based on their needs
- Answering questions about beauty services
- Giving tips about salon visits
- Ranking places by what they ask for (price, quality, distance)

Keep responses short (2-3 sentences max). Be helpful and conversational.'''
      },
      {'role': 'user', 'content': userMessage},
    ];

    return await _callOpenAI(messages, maxTokens: 150) ??
        'I apologize, I could not process your request. Please try again.';
  }

  // Smart ranking - re-rank places based on user preferences
  static Future<List<String>> smartRank(
      String userPreference, List<String> placeDescriptions) async {
    final placesJson = json.encode(placeDescriptions);

    final messages = [
      {
        'role': 'system',
        'content':
            '''Rank these places based on the user's preference. Return a JSON array of place names in order from best to worst match.
Input: list of place descriptions and a user preference.
Output: JSON array of place names only, ordered by relevance to the preference.

Example input places: ["Salon A: 4.5 star, 0.5mi, 50 dollars", "Salon B: 4.8 star, 1.2mi, 80 dollars"]
Example preference: "closest and cheapest"
Example output: ["Salon A", "Salon B"]'''
      },
      {
        'role': 'user',
        'content': 'Places: $placesJson\nPreference: $userPreference',
      },
    ];

    final response = await _callOpenAI(messages, maxTokens: 200);
    if (response != null) {
      try {
        return List<String>.from(json.decode(response));
      } catch (e) {
        return placeDescriptions;
      }
    }
    return placeDescriptions;
  }

  // Analyze photo description (simulated - would need vision API)
  static Future<String> analyzeSalonDescription(
      String placeName, String types) async {
    final messages = [
      {
        'role': 'system',
        'content':
            'Based on the salon name and type, generate a brief 1-sentence description of what services they likely offer and what the atmosphere might be like. Be creative but realistic.'
      },
      {
        'role': 'user',
        'content': 'Name: $placeName\nTypes: $types',
      },
    ];

    return await _callOpenAI(messages, maxTokens: 60) ??
        'A beauty establishment offering various services.';
  }

  // Core OpenAI API call
  static Future<String?> _callOpenAI(List<Map<String, String>> messages,
      {int maxTokens = 200}) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content']?.trim();
      } else {
        print('OpenAI API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('OpenAI API call failed: $e');
    }
    return null;
  }
}
