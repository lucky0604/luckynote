import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:luckynote/domains/chat/data/models/chat_message.dart';
import 'package:luckynote/domains/settings/data/models/llm_config.dart';
import 'llm_client_interface.dart';

/// OpenAI 兼容的 LLM 客户端实现
class OpenAICompatibleClient implements LLMClient {
  OpenAICompatibleClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Future<bool> testConnection(LLMConfig config) async {
    try {
      final response = await _dio.post(
        '${config.baseUrl}/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<String> streamChat(
    List<ChatMessage> messages, {
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) {
    throw StateError('Use streamChatWithConfig static method');
  }

  @override
  Future<String> getChatCompletion(
    List<ChatMessage> messages, {
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    throw StateError('Use getChatCompletionWithConfig static method');
  }

  /// 流式聊天（静态方法，供 Provider 使用）
  static Stream<String> streamChatWithConfig({
    required Dio dio,
    required LLMConfig config,
    required List<Map<String, dynamic>> messages,
    double? temperature,
    int? maxTokens,
  }) {
    final controller = StreamController<String>();

    () async {
      try {
        final response = await dio.post(
          '${config.baseUrl}/chat/completions',
          data: {
            'model': config.modelName,
            'messages': messages,
            'stream': true,
            if (temperature != null) 'temperature': temperature,
            if (maxTokens != null) 'max_tokens': maxTokens,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer ${config.apiKey}',
              'Content-Type': 'application/json',
            },
            responseType: ResponseType.stream,
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
          ),
        );

        final stream = response.data.stream;
        final buffer = StringBuffer();
        bool streamComplete = false;

        try {
          await for (final chunk in stream) {
            final text = utf8.decode(chunk);
            buffer.write(text);

            while (buffer.toString().contains('\n')) {
              final content = buffer.toString();
              final newlineIndex = content.indexOf('\n');

              if (newlineIndex == -1) break;

              final line = content.substring(0, newlineIndex);
              buffer.clear();
              buffer.write(content.substring(newlineIndex + 1));

              if (line.startsWith('data: ')) {
                final data = line.substring(6);
                if (data == '[DONE]') {
                  streamComplete = true;
                  break;
                }

                try {
                  final json = jsonDecode(data);
                  final choices = json['choices'] as List?;
                  if (choices != null && choices.isNotEmpty) {
                    final choice = choices[0] as Map;
                    final delta = choice['delta'] as Map?;
                    final finishReason = choice['finish_reason'];

                    if (delta != null && delta['content'] != null) {
                      final contentText = delta['content'] as String;
                      if (contentText.isNotEmpty) {
                        controller.add(contentText);
                      }
                    }

                    if (finishReason != null) {
                      streamComplete = true;
                      break;
                    }
                  }
                } catch (_) {}
              }
            }
          }
        } catch (e) {
          controller.addError('流式读取错误: $e');
        }

        if (!streamComplete) {
          final remaining = buffer.toString().trim();
          if (remaining.isNotEmpty && remaining.startsWith('data: ')) {
            final data = remaining.substring(6);
            if (data != '[DONE]') {
              try {
                final json = jsonDecode(data);
                final choices = json['choices'] as List?;
                if (choices != null && choices.isNotEmpty) {
                  final delta = choices[0]['delta'] as Map?;
                  if (delta != null && delta['content'] != null) {
                    controller.add(delta['content']);
                  }
                }
              } catch (_) {}
            }
          }
        }

        await controller.close();
      } catch (e, st) {
        controller.addError(Exception('API 请求失败: $e\n$st'));
        await controller.close();
      }
    }();

    return controller.stream;
  }

  /// 非流式聊天（静态方法，供 Provider 使用）
  static Future<String> getChatCompletionWithConfig({
    required Dio dio,
    required LLMConfig config,
    required List<Map<String, dynamic>> messages,
    double? temperature,
    int? maxTokens,
  }) async {
    final response = await dio.post(
      '${config.baseUrl}/chat/completions',
      data: {
        'model': config.modelName,
        'messages': messages,
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'max_tokens': maxTokens,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
    );

    final choices = response.data['choices'] as List;
    return choices[0]['message']['content'] as String;
  }

  /// 测试连接（静态方法）
  static Future<bool> testConnectionWithConfig({
    required Dio dio,
    required LLMConfig config,
  }) async {
    try {
      final response = await dio.post(
        '${config.baseUrl}/chat/completions',
        data: {
          'model': config.modelName,
          'messages': [
            {'role': 'user', 'content': 'test'},
          ],
          'max_tokens': 5,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // 200 = 成功, 401 = 认证失败(但连接正常), 429 = 限流
      return response.statusCode == 200 ||
          response.statusCode == 401 ||
          response.statusCode == 429;
    } catch (e) {
      return false;
    }
  }
}
