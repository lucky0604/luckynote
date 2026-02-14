# LuckyNote

A simple, offline-first note-taking app built with Flutter.

> English README | [中文 README](./README_CN.md)

## Why?

I wanted a clean, simple note-taking app that works offline and keeps my data local. No cloud, no accounts, no complicated features. Just notes.

## Features

- 📝 Create, edit, and delete notes
- 📁 Folder organization
- 🏷️ Tag support with `#tag` syntax
- 🔍 Full-text search
- 🌙 Light/Dark theme
- ⌨️ Keyboard shortcuts
- 📥 Import/Export Markdown
- 🔗 WikiLink support (`[[note name]]`)
- ✅ Task list recognition
- 🤖 **AI Assistant (optional)**
  - Works with OpenAI, DeepSeek, Ollama, or any OpenAI-compatible API
  - Chat with your notes as context
  - RAG-powered knowledge base search
  - ⚠️ Requires internet connection

## Platforms

- iOS ✅
- Android ✅
- macOS ✅
- Windows ✅
- Linux ✅

## Tech Stack

- Flutter
- Dart
- Drift (SQLite + FTS5)
- Riverpod
- Super Editor

## Getting Started

```bash
# Clone the repo
git clone https://github.com/yourusername/luckynote.git
cd luckynote

# Install dependencies
flutter pub get

# Run
flutter run
```

## Building

```bash
# iOS
flutter build ios

# Android
flutter build apk

# macOS
flutter build macos
```

## Contributing

Found a bug? Have a feature request? Feel free to open an issue or PR.

## Contact

- Email: [lucky_soft@163.com](mailto:lucky_soft@163.com)
- GitHub: [https://github.com/lucky0604](https://github.com/lucky0604)

## License

MIT License - feel free to use and modify.

---

Made with ☕️ and 🍀 by a solo developer