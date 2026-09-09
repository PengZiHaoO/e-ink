/// 屏3「记录」v2（T5）：编辑感账本 = 英雄统计 + 分状态 breakdown + 会话流水。
/// 设计语言：发丝线表行、巨大数字、micro 标签、meta 等宽（Digital Card v2）。
library;

import 'package:flutter/material.dart';

import '../app/deps.dart';
import '../app/theme.dart';
import '../core/state/card_state.dart';
import '../core/state/session_stats.dart';
import '../l10n/app_localizations.dart';

class RecordsScreen extends StatelessWidget {
  final AppDeps deps;
  const RecordsScreen({super.key, required this.deps});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final zh = deps.isZh;
    return ListenableBuilder(
      listenable: deps.sessionLog,
      builder: (context, _) {
        final log = deps.sessionLog;
        final now = DateTime.now();
        final byState = SessionStats.todayByState(log.records, now);
        final focusToday = byState[CardState.focusing] ?? Duration.zero;
        final streak = SessionStats.streak(log.records, now);
        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(T.s2, T.s2, T.s2, T.s3),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.recordsTitle, style: T.title),
                    const SizedBox(height: T.s3),
                    // 英雄统计：今日专注 + streak
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fmtDuration(focusToday), style: T.display),
                              const SizedBox(height: T.s05),
                              Text(l.focusToday.toUpperCase(), style: T.micro),
                            ],
                          ),
                        ),
                        if (streak > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: T.s05),
                            child: Row(
                              children: [
                                const Icon(Icons.local_fire_department,
                                    color: T.accent, size: 20),
                                const SizedBox(width: T.s05),
                                Text(l.streakDays(streak),
                                    style: T.body.copyWith(
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: T.s3),
                    // 分状态 breakdown（今日，发丝线表行）
                    if (byState.isEmpty)
                      Text(l.todayEmpty,
                          style: T.body.copyWith(color: T.inkSub))
                    else
                      ...[
                        for (final e in byState.entries) ...[
                          const Divider(height: 1),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: T.s2),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: e.key.isFocus ? T.ink : T.inkSub,
                                  ),
                                ),
                                const SizedBox(width: T.s2),
                                Text(e.key.buttonLabel(zh), style: T.body),
                                const Spacer(),
                                Text(fmtDuration(e.value), style: T.meta),
                              ],
                            ),
                          ),
                        ],
                        const Divider(height: 1),
                      ],
                    const SizedBox(height: T.s3),
                    // 会话流水
                    Text(l.sessionsHeader.toUpperCase(), style: T.micro),
                    const SizedBox(height: T.s1),
                    if (log.records.isEmpty)
                      Text(l.recordsEmpty,
                          style: T.body.copyWith(color: T.inkSub))
                    else
                      for (final r in log.records.reversed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: T.s1),
                          child: Row(
                            children: [
                              Text('${hhmm(r.start)}–${hhmm(r.end)}',
                                  style: T.meta),
                              const SizedBox(width: T.s2),
                              Text(r.state.buttonLabel(zh), style: T.body),
                              const Spacer(),
                              Text(fmtDuration(r.duration), style: T.meta),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
