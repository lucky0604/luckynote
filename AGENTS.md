# AGENTS.md - LuckyNote Development Guidelines

This file provides essential guidelines for agentic coding agents working on the LuckyNote codebase.

## Build & Development Commands

### Running the Application
```bash
flutter run                          # Run on connected device
flutter run -d macos                 # Run on macOS specifically
flutter run -d windows               # Run on Windows
flutter run -d linux                 # Run on Linux
```

### Building for Production
```bash
flutter build macos                  # Build for macOS
flutter build windows                # Build for Windows
flutter build linux                  # Build for Linux
flutter build apk                    # Build for Android APK
```

### Code Generation
```bash
dart run build_runner build          # Generate ObjectBox/Riverpod code
dart run build_runner build --delete-conflicting-outputs  # Force regeneration
```

### Dependencies
```bash
flutter pub get                      # Install dependencies
flutter pub upgrade                  # Upgrade dependencies
```

## Testing Commands

```bash
flutter test                         # Run all tests
flutter test test/widget_test.dart   # Run single test file
flutter test --name "test name"      # Run test by name
flutter test --coverage              # Generate coverage report
```

## Linting & Formatting

```bash
flutter analyze                      # Run static analysis
dart format .                        # Format all files
dart format lib/main.dart            # Format specific file
dart format --set-exit-if-changed .  # Exit with code 1 if changes made
```

## Code Style Guidelines

### Import Organization
Order imports with blank lines between groups:
1. Dart SDK imports
2. Package imports (Flutter, third-party)
3. Project imports (relative paths)

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';
import '../models/note_model.dart';
```

### Naming Conventions
- **Classes**: `PascalCase` (e.g., `NoteModel`, `FileSystemService`, `VaultNotifier`)
- **Variables/Methods**: `camelCase` (e.g., `vaultPath`, `getNotes()`, `modifiedAt`)
- **Constants**: `lowerCamelCase` or `UPPER_SNAKE_CASE` for global constants (e.g., `newNoteTitle`, `noteExtension`)
- **Private members**: `_prefix` (e.g., `_database`, `_loadVaultPath()`)
- **Providers**: `nameProvider` pattern (e.g., `databaseProvider`, `vaultProvider`, `noteRepositoryProvider`)
- **Notifiers**: `NameNotifier` (e.g., `VaultNotifier`)

### Type Annotations
- Strong typing required for all public APIs
- Use `String?` for nullable types
- Prefer `final` for immutable variables
- Explicit types for method returns: `Future<NoteModel>`, `List<NoteEntity>`
- Use `AsyncValue<T>` for async state in Riverpod providers
- Use `StateNotifier<AsyncValue<T>>` for complex state management

### Documentation
- Use `///` for doc comments
- English preferred, Chinese allowed (project is bilingual)
- Document all public methods, classes, and complex logic
- Format: `/// Brief description\n///\n/// Detailed explanation if needed`
- Example: `/// 获取指定目录下的所有 Markdown 文件`

### Riverpod Patterns
- Use `@riverpod` annotation with `riverpod_generator`
- Providers use descriptive names with `Provider` suffix
- Use `AsyncValue<T>` for async state
- Always dispose resources in `ref.onDispose()`
- StateNotifier pattern: `class VaultNotifier extends StateNotifier<AsyncValue<T>>`
- Handle errors with `try/catch` and `AsyncValue.error(e, st)`
- Use `.maybeWhen()` or `.when()` for handling AsyncValue states

```dart
final vaultProvider = StateNotifierProvider<VaultNotifier, AsyncValue<String?>>((ref) {
  return VaultNotifier(ref);
});

class VaultNotifier extends StateNotifier<AsyncValue<String?>> {
  VaultNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadVaultPath();
  }

  final Ref _ref;

  Future<void> _loadVaultPath() async {
    try {
      final path = await _loadFromStorage();
      state = AsyncValue.data(path);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
```

### ObjectBox Patterns
- Entities use `@Entity()` annotation
- Auto-generate ID with `@Id()` (default `id = 0`)
- Use `@Unique()` for unique fields
- Use `@Index()` for frequently queried fields
- Use `@Property(type: PropertyType.date)` for DateTime fields
- Use `ToMany<T>` for relationships: `final tags = ToMany<TagEntity>()`
- Run `dart run build_runner build` after entity changes
- Generated file: `objectbox.g.dart` (do not modify manually)

```dart
@Entity()
class NoteEntity {
  NoteEntity({
    this.id = 0,
    required this.filePath,
    required this.title,
  });

  @Id()
  int id;

  @Unique()
  @Index()
  String filePath;

  @Index()
  String title;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  final tags = ToMany<TagEntity>();
}
```

### Error Handling
- Use specific exception types: `FileSystemException`, `StateError`, `Exception`
- Wrap async operations in `try/catch` blocks
- Use `AsyncValue.error(e, st)` in Riverpod for state errors
- Always include stack trace when logging: `catch (e, st)`
- Throw descriptive error messages (Chinese allowed)
- Gracefully handle file read errors (skip unreadable files with `continue`)

```dart
try {
  await saveNote(filePath, content);
} catch (e, st) {
  state = AsyncValue.error(e, st);
}
```

### File System Operations
- Use `File` and `Directory` from `dart:io`
- Always check existence: `await directory.exists()`
- Use `path` package for path operations: `p.join(vaultPath, fileName)`
- Sanitize filenames: remove invalid characters with regex: `[<>:"/\\|?*]`
- Use `await for` for directory iteration: `await for (final entity in directory.list())`
- Handle file read errors gracefully in loops

### Testing Patterns
- Use `testWidgets()` for widget tests
- Use `expect()` from `flutter_test` matcher library
- Test async operations with `await tester.pump()`
- Mock repositories/services in tests
- Organize tests by feature in `test/` directory
- Run single test: `flutter test test/widget_test.dart`

```dart
testWidgets('Widget name test', (WidgetTester tester) async {
  await tester.pumpWidget(MyWidget());
  expect(find.text('Hello'), findsOneWidget);
});
```

### Security & Best Practices
- Never commit API keys or secrets
- Use `flutter_secure_storage` for sensitive data (API keys)
- Use `shared_preferences` for simple key-value storage via provider
- Always dispose streams and subscriptions in `ref.onDispose()`
- No sensitive data in logs or error messages
- Validate user input before file operations

### Architecture Guidelines
- Follow Clean Architecture with clear layer separation
- **Data layer** (`lib/data/`): entities, models, repositories, services, database
- **Presentation layer** (`lib/presentation/`): providers, screens, widgets
- **Core layer** (`lib/core/`): constants, utilities
- **App layer** (`lib/app/`): theme, router, app.dart
- No business logic in UI widgets
- Use Riverpod for dependency injection
- Repository pattern for data access

### UI/UX Conventions
- **Bear-inspired design**: warm, fresh, refined aesthetic
- **Three-column layout**: sidebar (tags), note list, editor
- Material Design 3 components with custom theming
- Theme configuration: `lib/app/theme/app_theme.dart`
- Colors from `AppColors` constants in `lib/app/theme/app_colors.dart`
- Icons: `LucideIcons` (modern, consistent icon set)
- Round corners: 12px for cards, 8px for buttons
- Use `CardTheme`, `InputDecorationTheme`, `ButtonTheme` for consistent styling

### Code Generation Workflow
Run `dart run build_runner build` after:
- Adding/modifying ObjectBox entities
- Adding/modifying Riverpod providers with `@riverpod` annotation
- Changing any code generation annotations
Use `--delete-conflicting-outputs` if conflicts occur

Generated files:
- `objectbox.g.dart` - ObjectBox entity code
- `*.g.dart` - Riverpod provider code

## File Structure Reference

```
lib/
├── app/              # App-level configuration
│   ├── theme/       # AppTheme, AppColors
│   ├── router.dart  # GoRouter configuration
│   └── app.dart     # Root app widget
├── core/            # Core utilities
│   ├── constants/   # App constants
│   └── utils/       # FileUtils, Debouncer
├── data/            # Data layer
│   ├── database/    # ObjectBox database
│   ├── entities/    # NoteEntity, TagEntity
│   ├── models/      # NoteModel, TagModel
│   ├── repositories/ # NoteRepository, TagRepository
│   └── services/    # FileSystemService, FileWatcherService, IndexerService
├── presentation/     # UI layer
│   ├── providers/   # Riverpod providers
│   ├── screens/     # Page widgets
│   └── widgets/     # Reusable components
└── main.dart       # App entry point
```

## Tech Stack Summary

- **Framework**: Flutter 3.27+
- **Language**: Dart 3.9.2+
- **State Management**: Riverpod with code generation
- **Database**: ObjectBox (embedded NoSQL)
- **Editor**: Super Editor
- **Routing**: GoRouter
- **Icons**: Lucide Icons
- **File System**: watcher, file_selector, path
- **Storage**: shared_preferences, flutter_secure_storage

## Key Principles

1. **Local-First**: Data stored in Markdown files, local database for indexing
2. **Privacy First**: No cloud dependencies, API keys in secure storage
3. **Clean Architecture**: Clear separation of concerns, testable code
4. **Bear Design**: Minimalist, content-focused, refined UI
5. **Type Safety**: Strong typing, compile-time checks with Riverpod
