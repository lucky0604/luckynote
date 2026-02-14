# LuckyNote

一个简洁、离线优先的笔记应用，用 Flutter 构建。

> English README | [中文 README](./README.md)

## 初衷

我就是想要一个简单、干净、离线的笔记应用。数据存在本地，不用云端，不用注册，没有复杂的功能。就是一个字：写。

## 功能

- 📝 创建、编辑、删除笔记
- 📁 文件夹管理
- 🏷️ 标签支持（`#标签名` 语法）
- 🔍 全文搜索
- 🌙 亮色/暗色主题
- ⌨️ 键盘快捷键
- 📥 导入/导出 Markdown
- 🔗 双向链接支持（`[[笔记名]]`）
- ✅ 任务列表识别
- 🤖 **AI 助手（可选）**
  - 支持 OpenAI、DeepSeek、Ollama 或任何 OpenAI 兼容 API
  - 以笔记为上下文进行聊天
  - RAG 驱动的知识库搜索
  - ⚠️ 需要联网才能使用

## 支持平台

- iOS ✅
- Android ✅
- macOS ✅
- Windows ✅
- Linux ✅

## 技术栈

- Flutter
- Dart
- Drift (SQLite + FTS5)
- Riverpod
- Super Editor

## 快速开始

```bash
# 克隆项目
git clone https://github.com/你的用户名/luckynote.git
cd luckynote

# 安装依赖
flutter pub get

# 运行
flutter run
```

## 构建

```bash
# iOS
flutter build ios

# Android
flutter build apk

# macOS
flutter build macos
```

## 贡献

发现 bug？有新功能想法？随时开 issue 或提交 PR。

## 联系方式

- 邮箱：[lucky_soft@163.com](mailto:lucky_soft@163.com)
- GitHub：[https://github.com/lucky0604](https://github.com/lucky0604)

## 许可证

MIT 许可证 - 随意使用和修改。

---

由一个solo开发者用 ☕️ 和 🍀 打造