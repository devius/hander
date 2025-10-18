# Hander - Hacker News Reader

<img src="https://github.com/devius/hander/blob/main/hander.png" width="48">

A modern, feature-rich Hacker News reader built with Flutter for macOS, featuring a beautiful UI and seamless browsing experience.

## Features

### 🎯 Core Features

- **Multiple Story Feeds**: Browse Top, New, Best stories, Ask HN, and Show HN
- **Lazy Loading**: Infinite scroll with progressive loading for both articles and comments
- **Split-View Layout**: Read articles and comments side by side with an integrated WebView
- **Icon Sidebar**: Quick navigation between different story categories
- **Real-time Comments**: View and load comments progressively as you scroll

### 🎨 Design

- **Material 3 Design**: Modern UI with smooth animations
- **Dark Mode Support**: Automatic theme switching based on system preferences
- **Responsive Layout**: Optimized for desktop viewing with split-pane interface
- **Clean Typography**: Easy-to-read interface with proper spacing and hierarchy

### ⚡ Performance

- **Progressive Loading**: Articles load in batches of 30, comments in batches of 20
- **Efficient Caching**: Smart state management with Provider
- **Smooth Scrolling**: Optimized scroll performance with lazy rendering
- **WebView Integration**: Built-in article preview without leaving the app

### 🖱️ Navigation

- **Two-Finger Swipe**: Native macOS gesture support for back navigation
- **Keyboard Shortcuts**: Quick access to features (coming soon)
- **Direct Links**: Open articles in external browser when needed

## Screenshots

<!-- Add screenshots here -->

## Getting Started

### Prerequisites

- Flutter SDK (^3.9.2)
- macOS 11.0 or later
- Xcode (for macOS development)

### Installation

1. Clone the repository:

```bash
git clone https://github.com/devius/hander.git
cd hander
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run -d macos
```

## Dependencies

- **flutter**: SDK for building the application
- **http**: ^1.1.0 - HTTP client for API requests
- **provider**: ^6.1.1 - State management
- **url_launcher**: ^6.2.2 - Opening URLs in external browser
- **timeago**: ^3.6.0 - Human-readable timestamps
- **shimmer**: ^3.0.0 - Loading animations
- **flutter_html**: ^3.0.0-beta.2 - HTML rendering for comments
- **webview_flutter**: ^4.4.2 - Embedded web content viewer

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── story.dart
│   └── comment.dart
├── providers/                # State management
│   └── stories_provider.dart
├── screens/                  # App screens
│   ├── home_screen.dart
│   └── story_detail_screen.dart
├── services/                 # API services
│   └── hackernews_api.dart
└── widgets/                  # Reusable widgets
    ├── persistent_sidebar.dart
    ├── story_card.dart
    └── story_card_shimmer.dart
```

## API

This app uses the official [Hacker News API](https://github.com/HackerNews/API):

- Base URL: `https://hacker-news.firebaseio.com/v0/`
- No authentication required
- Free and open access

## Features in Detail

### Story Feeds

- **Top Stories**: Most popular stories on Hacker News
- **New Stories**: Latest submissions
- **Best Stories**: Highest rated stories
- **Ask HN**: Questions from the community
- **Show HN**: Projects and products from the community

### Article View

- **WebView Preview**: Read articles directly in the app (66% width)
- **Comments Section**: Browse discussions (33% width)
- **Metadata Display**: Points, author, timestamp, and comment count
- **External Browser**: Open articles in your default browser

### Performance Optimizations

- Initial load: 30 articles
- Load more: 30 articles per scroll
- Comments initial: 20 comments
- Comments load more: 20 comments per scroll
- Auto-load trigger: 500px before end of scroll

## Building for Release

### macOS

```bash
flutter build macos --release
```

The built app will be available at:

```
build/macos/Build/Products/Release/hander.app
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Hacker News](https://news.ycombinator.com/) for the API
- [Flutter](https://flutter.dev/) for the amazing framework
- The Flutter community for excellent packages and support

## Roadmap

- [ ] Search functionality
- [ ] Bookmarks and favorites
- [ ] Keyboard shortcuts
- [ ] User profiles
- [ ] Submission posting
- [ ] Reply to comments
- [ ] Custom themes
- [ ] Export/share functionality
- [ ] iOS support

## Contact

Davit Matchakhelidze - [@DMachakhelidze](https://x.com/DMachakhelidze)

Project Link: [https://github.com/devius/hander](https://github.com/devius/hander)

---

Made with ❤️ using Flutter
