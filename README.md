# LinguaFlutter

A card-based language learning app with icon search functionality.

## Features

- 🎯 **Card-based Learning**: Learn vocabulary through interactive flashcards
- 🌍 **Multiple Languages**: Support for German and other languages
- 🎨 **Beautiful UI**: Modern, clean interface with smooth animations
- 📊 **Progress Tracking**: Monitor your learning progress and streaks
- 🔍 **Icon Search**: Find and use icons to enhance learning
- 🎭 **Mascot Guide**: Friendly mascot to guide your learning journey
- 🌙 **Theme Support**: Light and dark themes
- 🔐 **Authentication**: Secure user authentication with Supabase
- 📱 **Responsive Design**: Works on web and mobile devices

## Tech Stack

- **Flutter**: Cross-platform UI framework
- **Provider**: State management
- **Supabase**: Backend services (auth, database)
- **Go Router**: Navigation
- **Sentry**: Error tracking and monitoring
- **Talker**: Logging
- **Freezed**: Immutable data classes

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.10.3)
- Dart SDK
- Node.js (for web deployment)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/oscarjaergren/LinguaFlutter.git
cd LinguaFlutter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up environment variables:
```bash
cp .env.json.example .env.json
# Edit .env.json with your Supabase credentials
```

4. Run the app:
```bash
# Desktop (automatically uses .env.json via launch config)
flutter run -d windows

# Web (automatically uses .env.json via launch config)  
flutter run -d chrome

# Or from VS Code: Select a launch configuration and press F5
```

### Environment Variables

Create a `.env.json` file in the root directory:

```json
{
  "SUPABASE_URL": "your_supabase_url_here",
  "SUPABASE_ANON_KEY": "your_supabase_anon_key_here"
}
```

The app uses `--dart-define-from-file=.env.json` to inject credentials at compile time for all platforms (web, desktop, mobile).

## Project Structure

```
lib/
├── features/                 # Feature modules
│   ├── auth/                # Authentication
│   ├── card_management/     # Card CRUD operations
│   ├── card_review/         # Learning/review functionality
│   ├── duplicate_detection/ # Duplicate card detection
│   ├── icon_search/         # Icon search functionality
│   ├── language/            # Language management
│   ├── mascot/              # Mascot component
│   ├── streak/              # Learning streaks
│   └── theme/               # Theme management
├── shared/                  # Shared utilities
│   ├── domain/             # Domain models
│   ├── navigation/         # App routing
│   └── services/           # Shared services
└── main.dart               # App entry point
```

## Development

### Code Generation

This project uses code generation for JSON serialization and immutable data classes:

```bash
# Run after making changes to models
dart run build_runner build --delete-conflicting-outputs
```

### Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Linting

```bash
# Analyze code
flutter analyze

# Format code
dart format .
```

## Deployment

### Web Deployment

The app is configured for automatic deployment to Vercel via GitHub Actions.

1. Set up GitHub secrets:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SENTRY_DSN` (optional)
   - `SENTRY_AUTH_TOKEN` (optional)
   - `VERCEL_TOKEN`

2. Push to `master` branch to trigger deployment

### Manual Deployment

```bash
# Build for production
flutter build web --release

# Deploy to Vercel
vercel --prod
```

## Error Tracking

This app uses Sentry for error tracking and monitoring. See [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md) for detailed setup instructions.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Run the test suite
6. Submit a pull request

## Architecture

This app follows Flutter architecture best practices:

- **MVVM Pattern**: Separation of UI and business logic
- **Repository Pattern**: Data access abstraction
- **Dependency Injection**: Using Provider package
- **Immutable Models**: Using Freezed for data classes
- **Clean Architecture**: Feature-based organization

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:

1. Check the [Issues](https://github.com/oscarjaergren/LinguaFlutter/issues) page
2. Create a new issue with detailed information
3. Join our discussions for community support

---

Built with ❤️ using Flutter
