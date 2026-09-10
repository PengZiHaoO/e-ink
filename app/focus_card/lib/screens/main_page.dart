/// 主框架：底部两 Tab（状态/记录）+ N3 演示横幅 + R5 补记提示（每次启动至多一次）。
library;

import 'package:flutter/material.dart';

import '../app/deps.dart';
import '../app/theme.dart';
import '../core/state/session_stats.dart';
import '../l10n/app_localizations.dart';
import 'records_screen.dart';
import 'status_screen.dart';

class MainPage extends StatefulWidget {
  final AppDeps deps;
  const MainPage({super.key, required this.deps});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    widget.deps.homeReady = true; // 认领意图路由开门
    _maybePromptOpenSession();
  }

  /// R5：跨日仍开放的专注会话 → 启动时提示补记（一次）。
  /// 「现在结束」= 关闭会话（区间 since→now）并自 now 重开，避免重复计入；
  /// 「仍在继续」= 不动。
  void _maybePromptOpenSession() {
    final s = widget.deps.machine.state;
    final now = DateTime.now();
    if (!s.isCardSynced || !s.currentState.isFocus) return;
    if (SessionStats.sameDay(s.since, now)) return; // 今天开始的，不算陈旧
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final zh = widget.deps.isZh;
      final act = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final ll = AppLocalizations.of(ctx);
          return AlertDialog(
            backgroundColor: T.paper,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(T.rButton)),
            title: Text(ll.openSessionTitle, style: T.title),
            content: Text(
              ll.openSessionBody(s.currentState.label(zh), hhmm(s.since)),
              style: T.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: T.inkSub,
                  minimumSize: const Size(T.minTouch, T.minTouch),
                ),
                child: Text(ll.stillGoing),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: T.accent,
                  foregroundColor: T.onAccent,
                  minimumSize: const Size(T.minTouch, T.minTouch),
                ),
                child: Text(ll.endNow,
                    style: T.body.copyWith(
                        fontWeight: FontWeight.w700, color: T.onAccent)),
              ),
            ],
          );
        },
      );
      if (act == true && mounted) {
        await widget.deps.machine.closeOpenSession(DateTime.now());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          if (widget.deps.isMock) const _DemoBanner(),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                StatusScreen(deps: widget.deps),
                RecordsScreen(deps: widget.deps),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        height: 64,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.adjust_outlined),
            selectedIcon: const Icon(Icons.adjust, color: T.accent),
            label: l.tabStatus,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart, color: T.accent),
            label: l.tabRecords,
          ),
        ],
      ),
    );
  }
}

/// N3 · 演示模式横幅（Mock writer 时常驻，诚实告知没有真实写卡）
class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      color: T.accent.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: T.s2, vertical: T.s1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                const BoxDecoration(shape: BoxShape.circle, color: T.accent),
          ),
          const SizedBox(width: T.s1),
          Text(l.demoBanner, style: T.micro),
        ],
      ),
    );
  }
}
