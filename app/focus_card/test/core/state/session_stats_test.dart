import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/core/state/card_state.dart';
import 'package:focus_card/core/state/session_stats.dart';
import 'package:focus_card/core/state/state_machine.dart';

SessionRecord rec(CardState s, DateTime a, DateTime b) =>
    SessionRecord(state: s, start: a, end: b);

void main() {
  // 2026-09-09 为"今天"
  DateTime at(int dayOffset, int h, [int m = 0]) =>
      DateTime(2026, 9, 9 + dayOffset, h, m);
  final now = at(0, 16, 0);

  group('R3 · 今日统计', () {
    test('sameDay 判定', () {
      expect(SessionStats.sameDay(at(0, 1), at(0, 23)), isTrue);
      expect(SessionStats.sameDay(at(-1, 23), at(0, 0)), isFalse);
    });

    test('todayByState：只算今天，跨日会话归开始日', () {
      final rs = [
        rec(CardState.focusing, at(0, 9, 0), at(0, 10, 30)),
        rec(CardState.focusing, at(0, 14, 0), at(0, 14, 45)),
        rec(CardState.onBreak, at(0, 10, 30), at(0, 10, 42)),
        rec(CardState.focusing, at(-1, 20, 0), at(-1, 21, 0)), // 昨天，不计入
      ];
      final m = SessionStats.todayByState(rs, now);
      expect(m[CardState.focusing], const Duration(minutes: 135)); // 90+45
      expect(m[CardState.onBreak], const Duration(minutes: 12));
      expect(m.containsKey(CardState.away), isFalse);
    });

    test('longestToday', () {
      final rs = [
        rec(CardState.focusing, at(0, 9), at(0, 11, 20)),
        rec(CardState.focusing, at(0, 14), at(0, 14, 45)),
      ];
      expect(SessionStats.longestToday(rs, now),
          const Duration(hours: 2, minutes: 20));
      expect(SessionStats.longestToday([], now), isNull);
    });

    test('fmtDuration 格式', () {
      expect(fmtDuration(Duration.zero), '0m');
      expect(fmtDuration(const Duration(minutes: 47)), '47m');
      expect(fmtDuration(const Duration(hours: 2, minutes: 14)), '2h 14m');
    });

    test('hhmm 补零', () {
      expect(hhmm(DateTime(2026, 9, 9, 9, 5)), '09:05');
    });
  });

  group('R4 · streak 规则', () {
    test('空记录 = 0', () {
      expect(SessionStats.streak([], now), 0);
    });

    test('连续 3 天（含今天）= 3', () {
      final rs = [
        rec(CardState.focusing, at(-2, 10), at(-2, 11)),
        rec(CardState.focusing, at(-1, 10), at(-1, 11)),
        rec(CardState.focusing, at(0, 10), at(0, 11)),
      ];
      expect(SessionStats.streak(rs, now), 3);
    });

    test('今天还没有、昨天+前天有 = 2（早晨不断链）', () {
      final rs = [
        rec(CardState.focusing, at(-2, 10), at(-2, 11)),
        rec(CardState.focusing, at(-1, 10), at(-1, 11)),
      ];
      expect(SessionStats.streak(rs, now), 2);
    });

    test('断链：只有前天 = 0', () {
      final rs = [rec(CardState.focusing, at(-2, 10), at(-2, 11))];
      expect(SessionStats.streak(rs, now), 0);
    });

    test('非专注会话不计入 streak', () {
      final rs = [rec(CardState.onBreak, at(0, 10), at(0, 11))];
      expect(SessionStats.streak(rs, now), 0);
    });

    test('同天多条只算一天', () {
      final rs = [
        rec(CardState.focusing, at(0, 9), at(0, 10)),
        rec(CardState.focusing, at(0, 14), at(0, 15)),
      ];
      expect(SessionStats.streak(rs, now), 1);
    });
  });
}
