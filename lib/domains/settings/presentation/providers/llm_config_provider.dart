import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/llm_config.dart';
import '../../../chat/data/services/openai_compatible_client.dart';
import '../../data/services/secure_storage_service.dart';

/// LLM 配置状态管理器
class LlmConfigNotifier extends StateNotifier<AsyncValue<LLMConfig?>> {
  LlmConfigNotifier() : super(const AsyncValue.loading()) {
    _initAndLoad();
  }

  /// 初始化并加载配置
  Future<void> _initAndLoad() async {
    try {
      // 确保安全存储已初始化
      SecureStorageService.instance.init();

      // 等待一小段时间确保初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      await _loadConfig();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureStorage = SecureStorageService.instance;

      final providerName = prefs.getString('llm_provider');
      final baseUrl = prefs.getString('llm_base_url');
      final modelName = prefs.getString('llm_model_name');
      final apiKey = await secureStorage.getApiKey();

      if (providerName != null &&
          baseUrl != null &&
          modelName != null &&
          apiKey != null &&
          apiKey.isNotEmpty) {
        state = AsyncValue.data(
          LLMConfig(
            provider: LLMProvider.fromString(providerName),
            baseUrl: baseUrl,
            apiKey: apiKey,
            modelName: modelName,
          ),
        );
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 保存配置
  Future<bool> saveConfig(LLMConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureStorage = SecureStorageService.instance;
      secureStorage.init();      secureStorage.init();
      // 保存到 SharedPreferences（非敏感信息）
      await prefs.setString('llm_provider', config.provider.name);
      await prefs.setString('llm_base_url', config.baseUrl);
      await prefs.setString('llm_model_name', config.modelName);

      // 保存到安全存储（API Key）
      await secureStorage.saveApiKey(config.apiKey);

      // 更新状态
      state = AsyncValue.data(config);
      return true;
    } catch (e, st) {
      // 打印错误详情
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 更新配置
  Future<bool> updateConfig({
    LLMProvider? provider,
    String? baseUrl,
    String? apiKey,
    String? modelName,
  }) async {
    final current = state.value;
    if (current == null) return false;

    final updated = current.copyWith(
      provider: provider,
      baseUrl: baseUrl,
      apiKey: apiKey,
      modelName: modelName,
    );

    return await saveConfig(updated);
  }

  /// 清除配置
  Future<void> clearConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureStorage = SecureStorageService.instance;

      await prefs.remove('llm_provider');
      await prefs.remove('llm_base_url');
      await prefs.remove('llm_model_name');
      await secureStorage.deleteApiKey();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 测试连接
  Future<bool> testConnection() async {
    final config = state.value;
    if (config == null || !config.isValid) {
      return false;
    }

    try {
      final dio = Dio();
      final result = await OpenAICompatibleClient.testConnectionWithConfig(
        dio: dio,
        config: config,
      );
      return result;
    } catch (e) {
      return false;
    }
  }

  /// 检查是否已配置
  bool isConfigured() {
    final config = state.value;
    return config != null && config.isValid;
  }
}

/// LLM 配置 Provider
final llmConfigNotifierProvider =
    StateNotifierProvider<LlmConfigNotifier, AsyncValue<LLMConfig?>>((ref) {
      return LlmConfigNotifier();
    });

/// LLM 配置 Provider（便捷访问）
final llmConfigProvider = Provider<LLMConfig?>((ref) {
  return ref.watch(llmConfigNotifierProvider).value;
});

/// 是否已配置 Provider
final isLlmConfiguredProvider = Provider<bool>((ref) {
  final config = ref.watch(llmConfigProvider);
  return config != null && config.isValid;
});

/// 测试连接 Provider
final llmConnectionTestProvider = StateProvider<bool?>((ref) => null);
