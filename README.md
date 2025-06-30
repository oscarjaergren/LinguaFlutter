# LinguaFlutter

A card-based language learning app with advanced icon search functionality, built with Flutter.

## Features

- 🔍 **Icon Search**: Search and browse thousands of icons from the Iconify API
- 🎨 **SVG Support**: High-quality vector icons that scale perfectly
- 📱 **Modern UI**: Clean, Material Design 3 interface
- 🎯 **Icon Selection**: Select icons for use in language learning cards
- 🃏 **Card Management**: Create, edit, and organize language learning cards
- 📚 **Swipeable Review**: Anki/Duocards-style flashcard review with swipe gestures
- 🧠 **Spaced Repetition**: Intelligent scheduling based on your performance
- 📊 **Progress Tracking**: Track your learning progress and statistics
- ❤️ **Favorites & Categories**: Organize cards with favorites and custom categories
- ⚡ **Fast Performance**: Optimized with caching and state management

## Project Structure

```
lib/
├── models/          # Data models (IconModel, CardModel, etc.)
├── services/        # API services (IconifyService, CardStorageService)
├── providers/       # State management (IconProvider, CardProvider)
├── widgets/         # Reusable UI components
├── screens/         # Main app screens
└── main.dart        # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (3.8.1 or later)
- Dart SDK
- Visual Studio Code with Flutter extension (recommended)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd LinguaFlutter
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate code (for JSON serialization):
   ```bash
   dart run build_runner build
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Usage

1. **Home Screen**: Welcome screen with navigation to main features
2. **Icon Search**: 
   - Search for icons using keywords
   - Browse popular icons
   - Select icons for use in cards
   - View icon details (name, set, category)

3. **Card Management**:
   - Create new language learning cards with text, icons, and metadata
   - Edit existing cards
   - Organize cards by categories and tags
   - Mark cards as favorites
   - Archive cards you no longer need

4. **Review System**:
   - Swipe-based flashcard review (like Anki/Duocards)
   - Flip cards to reveal answers
   - Rate your performance (correct/incorrect)
   - Automatic spaced repetition scheduling
   - Track learning progress and statistics

## Architecture

- **State Management**: Provider pattern for reactive UI updates
- **Data Persistence**: Local storage with SharedPreferences for cards
- **API Integration**: HTTP client for Iconify API requests
- **SVG Rendering**: High-quality vector graphics with `flutter_svg`
- **Spaced Repetition**: Custom algorithm for optimal learning intervals

## API Integration

The app integrates with the [Iconify API](https://api.iconify.design/) to provide:
- Icon search functionality
- Access to 100+ icon collections
- SVG icon data with metadata
- Collections browsing

## Development Tasks

Available VS Code tasks:
- `Flutter: Run App` - Start the app in debug mode
- `Flutter: Build` - Build the app for release
- `Flutter: Test` - Run all tests

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run tests: `flutter test`
6. Submit a pull request

## Roadmap

- [x] Icon search and selection
- [x] Card creation and management
- [x] Swipeable flashcard review system
- [x] Spaced repetition algorithm
- [x] Local data persistence
- [ ] Advanced statistics and analytics
- [ ] Import/export functionality
- [ ] Multiple language support
- [ ] Custom card templates
- [ ] Cloud synchronization
- [ ] Offline mode improvements

## License

This project is licensed under the MIT License - see the LICENSE file for details.
