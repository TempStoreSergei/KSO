# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Flutter-based motel/hotel booking kiosk application** designed to run on tablets or kiosks. It provides a self-service interface for guests to book rooms, select services, and make payments. The app features an admin panel for managing settings, screensavers, desktop backgrounds, and services.

**Key characteristics:**
- Russian language UI (Cupertino design with iOS-style components)
- Full-screen kiosk mode with lock screen and screensaver
- WebSocket integration for real-time order updates
- Cookie-based authentication
- Clean architecture with separation: domain, data, and presentation layers

## Build and Development Commands

### Run the application
```bash
flutter run
```

### Build for production
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release
```

### Get dependencies
```bash
flutter pub get
```

### Run tests
```bash
flutter test

# Run a specific test file
flutter test test/path/to/test_file.dart
```

### Analyze code
```bash
flutter analyze
```

### Clean build artifacts
```bash
flutter clean
```

## Architecture

### Clean Architecture Layers

The codebase follows **Clean Architecture** principles with clear separation:

1. **Domain Layer** (`lib/domain/`)
   - `entities/`: Core business objects (screensaver_file, service_entity, transaction, desktop_background_entity)
   - `models/`: Data transfer objects (booking_models, save_transaction_request)
   - `repositories/`: Abstract repository interfaces
   - `usecases/`: Business logic use cases (get_services, room_booking_usecases, login_admin, get_transactions, etc.)

2. **Data Layer** (`lib/data/`)
   - `datasources/`: Remote data sources for API communication
   - `models/`: API response models
   - `repositories/`: Concrete repository implementations

3. **Presentation Layer** (`lib/presentation/`)
   - Organized by feature/screen
   - Uses Cupertino (iOS-style) widgets throughout
   - State management via Cubit/Bloc pattern (`flutter_bloc`) and Provider
   - Custom keyboard implementation for guest info entry

### Core Services

Located in `lib/core/`:

- **ApiClient** (`api/api_client.dart`): Singleton HTTP client with cookie-based session management
  - Base URL loaded from `.env` file
  - Automatic cookie handling via `CookieJar`
  - Methods: `get()`, `post()`, `put()`, `delete()`, `multipartPost()`
  - Custom exception handling (see `api_exceptions.dart`)

- **WebSocketService** (`services/websocket_service.dart`): Singleton WebSocket client
  - Connects to `ws://{host}:{port}/ws` derived from BASE_URL
  - Streams: `messageStream`, `connectionStateStream`, `orderDataStream`
  - Admin mode blocks WebSocket connection
  - Manages order data from POS/booking system

- **TokenService** (`services/token_service.dart`): Handles authentication tokens

### Key Application Flow

1. **Lock Screen** → Screensaver with swipe-to-unlock → Booking Dashboard or Admin Login (5 taps on clock)
2. **Booking Flow**: Building Selection → Room Selection → Guest Info → Category Selection → Period/Item Selection (conditional) → Payment → Confirmation → Success
3. **Admin Panel**: Login → Dashboard with settings for services, screensavers, backgrounds, bill acceptor/dispenser, password management

### Booking Process Architecture

The booking flow is managed by `RoomBookingScreen` with step-based navigation:

```
BookingStep enum values:
- buildingSelection (select building/корпус)
- roomSelection (select room number)
- guestInfo (guest information entry with custom on-screen keyboard)
- categorySelection (accommodation, services, penalties)
- period (for accommodation: date selection)
- itemSelection (for services/penalties: select specific items)
- payment
- confirmation
- success
```

**Flow logic:**
- Steps are dynamically determined based on `BookingCategory` selection
- Accommodation: includes `period` step (no item selection)
- Services/Penalties: includes `itemSelection` step (no period selection)
- State is stored in `BookingData` model and passed through step widgets
- Each step is a separate widget in `lib/presentation/booking/widgets/`

**Categories (BookingCategory enum):**
- `accommodation`: Room booking with date range
- `services`: Service selection
- `ruleViolationPenalty`: Fines for rule violations
- `propertyDamagePenalty`: Fines for property damage

### Custom Keyboard Implementation

The app includes a **custom on-screen Russian keyboard** (`lib/presentation/guest_info/custom_keyboard.dart`) coordinated by `KeyboardNotifier` for guest information entry. This is crucial for kiosk deployment.

## Environment Configuration

**`.env` file** (located at project root):
- `BASE_URL`: API endpoint (e.g., `http://192.168.0.99:8005/api/v1`)
- Loaded via `flutter_dotenv` package in `main.dart`
- **Important**: `.env` is gitignored; ensure it exists before running

## Important Patterns and Conventions

### API Communication
- All API calls go through `ApiClient.instance` (singleton)
- Cookies are automatically managed for session persistence
- Responses are UTF-8 decoded to handle Cyrillic characters
- Form-urlencoded and JSON content types supported

### State Management
- **flutter_bloc/Cubit** for complex features (services management)
- **Provider** for shared state (WebSocketService, KeyboardNotifier)
- **setState** for local widget state

### Localization
- App uses Russian locale: `Locale('ru', 'RU')`
- Date formatting via `intl` package with `ru_RU` locale
- All UI strings are hardcoded in Russian (no i18n framework currently)

### Screensaver System
- Files managed via `/screensaver/` API endpoints
- Each file has: order, URL, sound enable flag, display duration
- PageView with automatic timer-based transitions
- Individual file display times supported
- Falls back to local asset if screensaver disabled

### WebSocket Integration
- WebSocket auto-connects on app start unless in admin mode
- Receives `getOrderData` events with cart information
- Orders accumulated in `_allOrders` list (cleared manually)
- Connection state managed via streams

## Testing Considerations

- Test files should mirror the `lib/` structure in `test/` directory
- Mock `ApiClient` for unit tests (it's a singleton)
- Mock `WebSocketService` for widgets that depend on real-time data
- Use `flutter_test` package for widget and unit tests

## Platform-Specific Notes

- **Android**: Main activity in Kotlin at `android/app/src/main/kotlin/com/example/motel/MainActivity.kt`
- **iOS/macOS**: Assets configured in `Runner/Assets.xcassets/`
- Assets path: `assets/images/` (ensure images are added here)
- Supports Android, iOS, macOS, Web, Linux, Windows (multi-platform)

## Dependencies of Note

- `cupertino_icons`: iOS-style icons
- `flutter_bloc`: State management
- `provider`: Dependency injection and state
- `http`: API communication
- `cookie_jar`: Session management
- `web_socket_channel`: Real-time communication
- `flutter_dotenv`: Environment variables
- `image_picker`: File uploads (screensaver/background images)
- `shared_preferences`: Local storage
- `google_fonts`: Custom typography
- `qr_flutter`: QR code generation
- `intl`: Date/time formatting and localization
