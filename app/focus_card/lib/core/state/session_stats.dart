/// R3/R4 · 统计纯函数（可单测；UI 只做展示）。
library;

import 'card_state.dart';
import 'state_machine.dart';

/// HH:mm（meta 用）
String hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// 时长格式：≥1h → '2h 14m'；否则 '47m'
String fmtDuration(Duration d) {
  if (d.inMinutes <= 0) return '0m';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}

abstract final class SessionStats {
  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 今日各状态时长（跨日会话归开始日——M1 简单规则）
  static Map<CardState, Duration> todayByState(
      List<SessionRecord> rs, DateTime now) {
    final m = <CardState, Duration>{};
    for (final r in rs) {
      if (!sameDay(r.start, now)) continue;
      m[r.state] = (m[r.state] ?? Duration.zero) + r.duration;
    }
    return m;
  }

  /// 今日最长单次会话
  static Duration? longestToday(List<SessionRecord> rs, DateTime now) {
    Duration? best;
    for (final r in rs) {
      if (sameDay(r.start, now) && (best == null || r.duration > best)) {
        best = r.duration;
      }
    }
    return best;
  }

  /// R4 streak：有 ≥1 条已关闭专注会话的连续天数。
  /// 今日还没有时允许链条止于昨天（早晨不断链）。
  static int streak(List<SessionRecord> rs, DateTime now) {
    final days = <DateTime>{};
    for (final r in rs) {
      if (r.state.isFocus) {
        days.add(DateTime(r.start.year, r.start.month, r.start.day));
      }
    }
    if (days.isEmpty) return 0;
    var day = DateTime(now.year, now.month, now.day);
    if (!days.contains(day)) {
      day = day.subtract(const Duration(days: 1));
      if (!days.contains(day)) return 0;
    }
    var n = 0;
    while (days.contains(day)) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }
}
