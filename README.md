# Nearby Saloons - Places Directory App

A Flutter app that discovers nearby beauty salons, spas, and barbershops using Google Places API.

## Features
- Google Places nearby search with real photos and reviews
- Voice search (speech-to-text)
- Category filtering (Hair Salon, Nail Salon, Spa, Beauty, Makeup)
- Sort by distance, rating, name, reviews
- WhatsApp integration for booking
- Call-to-book with phone dialer
- Google Maps with markers
- Favorites system
- Pull-to-refresh
- Dark mode

## Setup on New Machine

### 1. Clone the repo
```bash
git clone https://github.com/pradeep-kargwal/Nearby-saloons.git
cd Nearby-saloons
```

### 2. Install Flutter
Make sure Flutter SDK is installed: https://docs.flutter.dev/get-started/install

### 3. Get dependencies
```bash
flutter pub get
```

### 4. Add your API keys
Edit `lib/utils/BMConstants.dart` and replace:
```dart
const String googlePlacesApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
const String openAIApiKey = 'YOUR_OPENAI_API_KEY';
```

Also update the API key in `android/app/src/main/AndroidManifest.xml`:
```xml
android:value="YOUR_GOOGLE_MAPS_API_KEY"
```

### 5. Generate MobX files
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 6. Run the app
```bash
flutter run
```

## API Keys Needed
- **Google Maps Platform** (enable Places API, Maps SDK, Geocoding API)
- **OpenAI** (for AI review summaries and chat)

## Tech Stack
- Flutter 3.x
- MobX (state management)
- Google Places API
- Google Maps SDK
- Speech-to-text
- URL Launcher (WhatsApp, Phone, Maps)
