/// M1 过渡 · 内存会话日志。
///
/// T2 的 StateMachine.sessionSink 先挂这里（证明打点管线通）；
/// T4 换成 sqflite repository 后本类退役（或降级为调试工具）。
library;

import 'package:flutter/foundation.dart';

import 'state_machine.dart';

class SessionLog extends ChangeNotifier {
  final List<SessionRecord> records = [];

  void add(SessionRecord record) {
    records.add(record);
    notifyListeners();
  }

  /// 启动时从 repository 批量恢复（单次通知）
  void addAll(Iterable<SessionRecord> past) {
    final list = past.toList();
    if (list.isEmpty) return;
    records.addAll(list);
    notifyListeners();
  }

  int get count => records.length;

  /// 今日会话（本地日界，R3 的过渡版）
  List<SessionRecord> today() {
    final now = DateTime.now();
    return records
        .where((r) =>
            r.start.year == now.year &&
            r.start.month == now.month &&
            r.start.day == now.day)
        .toList();
  }
}
