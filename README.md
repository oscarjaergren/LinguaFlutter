# LinguaFlutter

A card-based language learning app with advanced icon search functionality, built with Flutter.

## Features

- 🔍 **Icon Search**: Search and browse thousands of icons from the Iconify API
- 🎨 **SVG Support**: High-quality vector icons that scale perfectly
- 📱 **Modern UI**: Clean, Material Design 3 interface
- 🎯 **Icon Selection**: Select icons for use in language learning cards
- ⚡ **Fast Performance**: Optimized with caching and state management

## Project Structure

```
lib/
├── models/          # Data models (IconModel, etc.)
├── services/        # API services (IconifyService)
├── providers/       # State management (IconProvider)
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

1. **Home Screen**: Welcome screen with navigation to icon search
2. **Icon Search**: 
   - Search for icons using keywords
   - Browse popular icons
   - Select icons for use in cards
   - View icon details (name, set, category)

## Architecture

- **State Management**: Provider pattern for reactive UI updates
- **API Integration**: HTTP client for Iconify API requests
- **Caching**: Efficient caching with `cached_network_image`
- **SVG Rendering**: High-quality vector graphics with `flutter_svg`

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

- [ ] Card creation and management
- [ ] Language learning features
- [ ] Favorites system for icons
- [ ] Offline icon caching
- [ ] Advanced search filters
- [ ] Custom icon collections
- [ ] Export functionality

## License

This project is licensed under the MIT License - see the LICENSE file for details.
