/// R2 · 会话持久化端口 + 实现（T4：账本落库，重启不丢）。
///
/// - Android/iOS：sqflite 原生
/// - 桌面（Linux/macOS/Windows）：sqflite_common_ffi（系统 libsqlite3）
/// - 测试：MemorySessionRepository 或 in-memory ffi
library;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, debugPrint;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // 重导出 sqflite API（含原生 databaseFactory）

import 'card_state.dart';
import 'state_machine.dart';

abstract class SessionRepository {
  Future<void> insert(SessionRecord record);

  /// 全部会话，按开始时间升序
  Future<List<SessionRecord>> all();

  Future<void> close() async {}
}

/// 测试 / M1 之前的行为兼容
class MemorySessionRepository implements SessionRepository {
  final List<SessionRecord> _rows = [];

  @override
  Future<void> insert(SessionRecord record) async => _rows.add(record);

  @override
  Future<List<SessionRecord>> all() async => List.unmodifiable(_rows);

  @override
  Future<void> close() async {}
}

class SqfliteSessionRepository implements SessionRepository {
  SqfliteSessionRepository(this._db);

  final Database _db;

  static const _createTable = '''
    CREATE TABLE sessions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      state TEXT NOT NULL,
      start_ms INTEGER NOT NULL,
      end_ms INTEGER NOT NULL,
      note TEXT)
  ''';

  /// 平台感知开库：移动原生 vs 桌面 FFI
  static Future<SqfliteSessionRepository> open() async {
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'focus_card.db');
    final DatabaseFactory factory;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      factory = databaseFactory;
    } else {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
    }
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute(_createTable),
      ),
    );
    return SqfliteSessionRepository(db);
  }

  @override
  Future<void> insert(SessionRecord record) async {
    await _db.insert('sessions', {
      'state': record.state.name,
      'start_ms': record.start.millisecondsSinceEpoch,
      'end_ms': record.end.millisecondsSinceEpoch,
      'note': record.note,
    });
  }

  @override
  Future<List<SessionRecord>> all() async {
    final rows = await _db.query('sessions', orderBy: 'start_ms ASC');
    return rows
        .map((m) => SessionRecord(
              state: CardState.values.firstWhere(
                (s) => s.name == m['state'],
                orElse: () => CardState.available, // 未来版本降级兼容
              ),
              start: DateTime.fromMillisecondsSinceEpoch(m['start_ms'] as int),
              end: DateTime.fromMillisecondsSinceEpoch(m['end_ms'] as int),
              note: m['note'] as String?,
            ))
        .toList();
  }

  @override
  Future<void> close() => _db.close();
}

/// 静默落库失败的兜底日志（账本不因 IO 错误炸 App）
void logPersistError(Object e) => debugPrint('session persist failed: $e');
