import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/core/state/card_state.dart';
import 'package:focus_card/core/state/session_log.dart';
import 'package:focus_card/core/state/session_repository.dart';
import 'package:focus_card/core/state/state_machine.dart';
import 'package:focus_card/core/state/state_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  final t1 = DateTime(2026, 9, 9, 14, 32);
  final t2 = DateTime(2026, 9, 9, 15, 19);

  SessionRecord rec(CardState s, DateTime a, DateTime b, [String? note]) =>
      SessionRecord(state: s, start: a, end: b, note: note);

  Future<Database> openMem() => databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) => db.execute('''
            CREATE TABLE sessions(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              state TEXT NOT NULL,
              start_ms INTEGER NOT NULL,
              end_ms INTEGER NOT NULL,
              note TEXT)
          '''),
        ),
      );

  group('R2 · SqfliteSessionRepository', () {
    late SqfliteSessionRepository repo;

    setUp(() async => repo = SqfliteSessionRepository(await openMem()));
    tearDown(() => repo.close());

    test('insert→all round-trip（note 空/值、时长、状态）', () async {
      await repo.insert(rec(CardState.focusing, t1, t2, '深度工作'));
      await repo.insert(rec(CardState.onBreak, t2, t2.add(const Duration(minutes: 12))));
      final rows = await repo.all();
      expect(rows.length, 2);
      expect(rows[0].state, CardState.focusing);
      expect(rows[0].note, '深度工作');
      expect(rows[0].duration, const Duration(minutes: 47));
      expect(rows[1].note, isNull);
      expect(rows[1].state, CardState.onBreak);
    });

    test('all 按开始时间升序', () async {
      await repo.insert(rec(CardState.away, t2, t2.add(const Duration(minutes: 5))));
      await repo.insert(rec(CardState.focusing, t1, t2));
      final rows = await repo.all();
      expect(rows.first.state, CardState.focusing);
      expect(rows.last.state, CardState.away);
    });
  });

  group('R2 · 接线：打点 → 落库 → 重启恢复', () {
    test('两次写卡产一行；新 SessionLog 从同库读回（模拟重启）', () async {
      final repo = SqfliteSessionRepository(await openMem());
      final machine = StateMachine(store: MemoryAppStateStore());
      final log = SessionLog();
      machine.sessionSink = (r) {
        log.add(r);
        repo.insert(r);
      };

      await machine.onWriteSuccess(newState: CardState.focusing, writeTs: t1);
      await machine.onWriteSuccess(newState: CardState.onBreak, writeTs: t2);
      await Future<void>.delayed(Duration.zero); // 等静默落库微任务

      expect(log.count, 1, reason: '首写不产会话');
      final rows = await repo.all();
      expect(rows.length, 1);
      expect(rows.single.state, CardState.focusing);

      // 模拟重启：新 SessionLog 从 repository 恢复
      final log2 = SessionLog()..addAll(await repo.all());
      expect(log2.count, 1);
      expect(log2.records.single.state, CardState.focusing);
      expect(log2.records.single.note, isNull);
      await repo.close();
    });
  });
}
