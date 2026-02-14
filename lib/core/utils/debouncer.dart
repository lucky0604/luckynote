import 'dart:async';

/// 防抖器
/// 用于延迟执行操作，避免频繁触发
class Debouncer {
  Debouncer({required this.milliseconds});

  /// 延迟时间（毫秒）
  final int milliseconds;

  /// 内部定时器
  Timer? _timer;

  /// 执行防抖操作
  /// [action] 要执行的操作
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// 取消待执行的操作
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// 释放资源
  void dispose() {
    cancel();
  }
}
