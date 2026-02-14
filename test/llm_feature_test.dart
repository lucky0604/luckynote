import 'package:flutter_test/flutter_test.dart';
import 'package:luckynote/domains/settings/data/models/llm_config.dart';
import 'package:luckynote/domains/chat/data/models/chat_message.dart';

void main() {
  group('LLM Feature Tests', () {
    test('LLMConfig should create valid config', () {
      final config = LLMConfig(
        provider: LLMProvider.deepseek,
        baseUrl: 'https://api.deepseek.com/v1',
        apiKey: 'test-key',
        modelName: 'deepseek-chat',
      );

      expect(config.isValid, true);
      expect(config.provider, LLMProvider.deepseek);
    });

    test('ChatMessage should create user message', () {
      final message = ChatMessage.user('Hello');
      
      expect(message.role, MessageRole.user);
      expect(message.content, 'Hello');
      expect(message.timestamp, isNotNull);
    });

    test('ChatMessage should create AI message', () {
      final message = ChatMessage.ai('Hi there');
      
      expect(message.role, MessageRole.assistant);
      expect(message.content, 'Hi there');
    });

    test('ChatConfig should have correct defaults', () {
      final config = ChatConfig.defaultConfig();
      
      expect(config.systemPrompt, contains('助手'));
      expect(config.temperature, 0.7);
      expect(config.useCurrentNoteContext, false);
    });

    test('ChatConfig summarize factory', () {
      final config = ChatConfig.summarize();
      
      expect(config.useCurrentNoteContext, true);
      expect(config.temperature, 0.3);
    });

    test('LLMProvider default values', () {
      expect(LLMProvider.deepseek.defaultBaseUrl, 'https://api.deepseek.com/v1');
      expect(LLMProvider.deepseek.defaultModel, 'deepseek-chat');
      expect(LLMProvider.openai.defaultBaseUrl, 'https://api.openai.com/v1');
    });
  });
}
