/// S4 · AppState 持久化端口 + 两个实现。
///
/// 端口/实现分离：核心状态机只依赖 [AppStateStore] 抽象——
/// 生产用 [PrefsAppStateStore]（shared_preferences，全平台），
/// 测试用 [MemoryAppStateStore]（确定性 + 可断言写入次数）。
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';

abstract class AppStateStore {
  Future<AppState?> read();
  Future<void> write(AppState state);
}

class PrefsAppStateStore implements AppStateStore {
  static const String key = 'app_state.v1';

  @override
  Future<AppState?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return AppState.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return null; // 损坏数据视为首启，不炸 App
    }
  }

  @override
  Future<void> write(AppState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(state.toJson()));
  }
}

class MemoryAppStateStore implements AppStateStore {
  AppState? _saved;

  /// 测试断言用：持久化调用次数（S4"每次提交必落库"）
  int writeCount = 0;

  @override
  Future<AppState?> read() async => _saved;

  @override
  Future<void> write(AppState state) async {
    _saved = state;
    writeCount++;
  }
}
