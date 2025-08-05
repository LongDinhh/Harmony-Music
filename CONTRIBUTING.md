# Contributing to Harmony Music

Thank you for your interest in contributing to Harmony Music! 🎵

## Important: Mobile-Only Project

**Harmony Music is a mobile-only (Android & iOS) application.** All contributions should focus on mobile development and features. We do not support or plan to support desktop platforms (Windows, macOS, Linux) or web platforms.

## Getting Started

### Prerequisites

- **Flutter SDK:** ≥3.24.0 (stable channel)
- **Dart SDK:** ≥3.1.5 <4.0.0
- **Platform-specific tools:**
  - **Android:** Android SDK, Android Studio (recommended)
  - **iOS:** Xcode (for iOS builds, macOS required)

### Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Harmony-Music.git
   cd Harmony-Music
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   dart localization/generator.dart
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## How to Contribute

### 1. Create a Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes
- Follow Dart/Flutter best practices
- Ensure your code works on both Android and iOS
- Test on real devices when possible

### 3. Test Your Changes
```bash
flutter test
flutter analyze
flutter build ios    # Test iOS build
flutter build apk    # Test Android build
```

### 4. Commit Your Changes
Use conventional commit format:
```bash
git commit -m "feat: Add amazing mobile feature"
git commit -m "fix: Resolve Android-specific bug"
git commit -m "docs: Update mobile setup instructions"
```

### 5. Push and Create Pull Request
```bash
git push origin feature/your-feature-name
```

Then create a Pull Request with:
- Clear description of changes
- Screenshots/recordings for UI changes
- Test results on Android/iOS

## Types of Contributions

### 🐛 Bug Fixes
- Android/iOS specific issues
- Mobile UI/UX problems
- Performance issues on mobile devices

### ✨ New Features
- Mobile-focused features
- Android Auto integration improvements
- iOS-specific enhancements
- Mobile accessibility improvements

### 🌍 Translations
- Help translate the app for mobile users worldwide
- Update existing translations

### 📚 Documentation
- Improve mobile development setup guides
- Update README with mobile-specific information
- Create mobile testing guidelines

### 🎨 UI/UX Improvements
- Mobile-first design improvements
- Touch interaction enhancements
- Mobile accessibility improvements

## Development Guidelines

### Code Style
- Follow existing Dart/Flutter patterns in the codebase
- Use meaningful variable and function names
- Keep functions small and focused
- Add comments for complex mobile-specific logic

### Mobile-Specific Considerations
- Test on both Android and iOS
- Consider different screen sizes and orientations
- Handle platform-specific features appropriately
- Ensure proper memory management for mobile devices
- Optimize for battery life and performance

### Commit Messages
Use conventional commit format:
- `feat:` - New mobile features
- `fix:` - Bug fixes
- `docs:` - Documentation updates
- `style:` - Code formatting
- `refactor:` - Code restructuring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

### Testing
- Run `flutter test` before submitting
- Test on real Android and iOS devices when possible
- Verify performance on lower-end mobile devices
- Check accessibility features

## What We Don't Accept

❌ **Desktop platform support** (Windows, macOS, Linux)  
❌ **Web platform support**  
❌ **Features that don't work on mobile devices**  
❌ **Desktop-specific UI patterns**  
❌ **Dependencies that don't support mobile platforms**

## Code of Conduct

- Be respectful and inclusive
- Focus on mobile development best practices
- Help others learn mobile Flutter development
- Provide constructive feedback
- Be patient with new mobile developers

## Getting Help

- 📚 Check existing [Issues](https://github.com/longdinhh/Harmony-Music/issues)
- 💬 Use [GitHub Discussions](https://github.com/longdinhh/Harmony-Music/discussions) for questions
- 🐛 Report mobile-specific bugs with device information
- 💡 Suggest mobile-focused feature requests

## License

By contributing, you agree that your contributions will be licensed under the same GPL-3.0 license that covers the project.

---

**Remember: This is a mobile-only project. All contributions should enhance the Android and iOS user experience! 📱**
