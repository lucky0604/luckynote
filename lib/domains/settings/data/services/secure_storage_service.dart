import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 安全存储服务
/// 使用系统级安全存储（Keychain/Keystore）保存敏感信息
class SecureStorageService {
  SecureStorageService._internal();
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  static SecureStorageService get instance => _instance;

  FlutterSecureStorage? _storage;

  /// 初始化安全存储
  void init() {
    _storage ??= const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
  }

  /// 获取存储实例（自动初始化）
  FlutterSecureStorage _getStorage() {
    if (_storage == null) {
      init();
    }
    return _storage!;
  }

  /// 保存 API Key（使用 SharedPreferences 作为后备）
  Future<void> saveApiKey(String key) async {
    try {
      await _getStorage().write(key: _Keys.apiKey, value: key);
    } catch (e) {
      // 如果 Keychain 失败，使用 SharedPreferences 作为后备
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('llm_api_key_backup', key);
    }
  }

  /// 读取 API Key（优先 Keychain，失败则读 SharedPreferences）
  Future<String?> getApiKey() async {
    try {
      final key = await _getStorage().read(key: _Keys.apiKey);
      if (key != null) return key;
    } catch (e) {
      // Keychain 读取失败，继续使用后备
    }

    // 后备：从 SharedPreferences 读取
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('llm_api_key_backup');
  }

  /// 删除 API Key
  Future<void> deleteApiKey() async {
    try {
      await _getStorage().delete(key: _Keys.apiKey);
    } catch (e) {
      // 忽略错误
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('llm_api_key_backup');
  }

  /// 检查是否存在 API Key
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// 保存所有配置（API Key 除外，它单独存储）
  Future<void> saveConfig({
    required String baseUrl,
    required String modelName,
    required String provider,
  }) async {
    try {
      await _getStorage().write(key: _Keys.baseUrl, value: baseUrl);
      await _getStorage().write(key: _Keys.modelName, value: modelName);
      await _getStorage().write(key: _Keys.provider, value: provider);
    } catch (e) {
      // Keychain 失败，使用 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('llm_base_url_backup', baseUrl);
      await prefs.setString('llm_model_name_backup', modelName);
      await prefs.setString('llm_provider_backup', provider);
    }
  }

  /// 读取配置
  Future<Map<String, String?>> getConfig() async {
    try {
      return {
        'baseUrl': await _getStorage().read(key: _Keys.baseUrl),
        'modelName': await _getStorage().read(key: _Keys.modelName),
        'provider': await _getStorage().read(key: _Keys.provider),
      };
    } catch (e) {
      // 后备：从 SharedPreferences 读取
      final prefs = await SharedPreferences.getInstance();
      return {
        'baseUrl': prefs.getString('llm_base_url_backup'),
        'modelName': prefs.getString('llm_model_name_backup'),
        'provider': prefs.getString('llm_provider_backup'),
      };
    }
  }

  /// 删除所有配置
  Future<void> deleteAll() async {
    try {
      await _getStorage().deleteAll();
    } catch (e) {
      // 忽略错误
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('llm_api_key_backup');
    await prefs.remove('llm_base_url_backup');
    await prefs.remove('llm_model_name_backup');
    await prefs.remove('llm_provider_backup');
  }

  /// 清空所有数据（用于测试）
  Future<void> clearAll() async {
    await deleteAll();
  }
}

/// 存储键常量
abstract class _Keys {
  static const String apiKey = 'llm_api_key';
  static const String baseUrl = 'llm_base_url';
  static const String modelName = 'llm_model_name';
  static const String provider = 'llm_provider';
}
