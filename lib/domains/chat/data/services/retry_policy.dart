import 'dart:async';
import 'package:dio/dio.dart';

/// 网络请求重试策略
/// 提供指数退避重试机制
class RetryPolicy {
  const RetryPolicy._();

  /// 默认最大重试次数
  static const int defaultMaxRetries = 3;

  /// 默认初始延迟
  static const Duration defaultInitialDelay = Duration(seconds: 1);

  /// 执行带重试的异步操作
  ///
  /// [action] 要执行的异步操作
  /// [maxRetries] 最大重试次数
  /// [initialDelay] 初始延迟时间，每次重试会指数增加
  /// [shouldRetry] 判断是否应该重试的函数
  static Future<T> execute<T>(
    Future<T> Function() action, {
    int maxRetries = defaultMaxRetries,
    Duration initialDelay = defaultInitialDelay,
    bool Function(Exception)? shouldRetry,
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        attempts++;
        return await action();
      } on Exception catch (e) {
        if (attempts >= maxRetries) rethrow;
        if (shouldRetry != null && !shouldRetry(e)) rethrow;
        if (!_isRetryableException(e)) rethrow;

        await Future.delayed(delay);
        delay *= 2; // 指数退避
      }
    }
  }

  /// 判断异常是否可重试
  static bool _isRetryableException(Exception e) {
    if (e is DioException) {
      return _isRetryableDioError(e.type);
    }
    return false;
  }

  /// 判断 Dio 错误类型是否可重试
  static bool _isRetryableDioError(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }
}
