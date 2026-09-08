/// 屏1「状态」：现在卡（当前状态迷你预览）+ 切换状态网格。
/// 功能映射（全景 §5）：S1/S2 网格 · S4 现在卡 · D3/P 设置溢出 · N3 由 MainPage 横幅承载。
library;

import 'package:flutter/material.dart';

import '../app/card_preview.dart';
import '../app/deps.dart';
import '../app/theme.dart';
import '../core/hal/card_bitmap.dart';
import '../core/state/card_state.dart';
import 'write_screen.dart';

/// 2×2 网格中的四个次级状态（专注=英雄位单独整行，产品主打）
const _gridStates = [
  CardState.onBreak,
  CardState.available,
  CardState.away,
  CardState.namecard,
];

IconData stateIcon(CardState s) => switch (s) {
      CardState.focusing => Icons.center_focus_strong,
      CardState.onBreak => Icons.free_breakfast_outlined,
      CardState.available => Icons.chat_bubble_outline,
      CardState.away => Icons.directions_walk,
      CardState.namecard => Icons.badge_outlined,
    };

class StatusScreen extends StatelessWidget {
  final AppDeps deps;
  const StatusScreen({super.key, required this.deps});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: deps.machine,
      builder: (context, _) {
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
                    Row(
                      children: [
                        Text('状态', style: T.title),
                        const Spacer(),
                        _OverflowMenu(deps: deps),
                      ],
                    ),
                    const SizedBox(height: T.s2),
                    _NowCard(deps: deps),
                    const SizedBox(height: T.s3),
                    Text('切换状态', style: T.body.copyWith(color: T.inkSub)),
                    const SizedBox(height: T.s2),
                    // 专注 = 英雄位：整行 + 翻转即写入提示（B 轮评审：专注最重要）
                    SizedBox(
                      width: double.infinity,
                      height: 72,
                      child: _StateCell(
                        state: CardState.focusing,
                        isCurrent: _isCurrent(CardState.focusing),
                        hint: '翻转即写入',
                        horizontal: true,
                        onTap: () => _openWrite(context, CardState.focusing),
                      ),
                    ),
                    const SizedBox(height: T.s2),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: T.s2,
                      crossAxisSpacing: T.s2,
                      childAspectRatio: 1.8,
                      children: [
                        for (final s in _gridStates)
                          _StateCell(
                            state: s,
                            isCurrent: _isCurrent(s),
                            onTap: () => _openWrite(context, s),
                          ),
                      ],
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

  void _openWrite(BuildContext context, CardState s) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => WriteScreen(deps: deps, targetState: s),
    ));
  }

  /// 「卡上」= 曾成功写入且当前状态（未写卡时任何格不高亮）
  bool _isCurrent(CardState s) =>
      deps.machine.state.isCardSynced && deps.machine.state.currentState == s;
}

/// 「现在」卡：当前已提交状态的迷你预览（S4）+ 上卡时间。
/// 未写过卡 → 诚实占位文案。
class _NowCard extends StatefulWidget {
  final AppDeps deps;
  const _NowCard({required this.deps});

  @override
  State<_NowCard> createState() => _NowCardState();
}

class _NowCardState extends State<_NowCard> {
  CardBitmap? _bitmap;
  String? _renderedKey;

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void didUpdateWidget(covariant _NowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _render();
  }

  /// 状态机每次 notify 都会触发 didUpdateWidget 路径外的重建——
  /// 由父级 ListenableBuilder 重建本组件，didUpdateWidget 捕获变化。
  String get _key {
    final s = widget.deps.machine.state;
    return '${s.currentState.name}|${s.since.toIso8601String()}|${s.customText ?? ''}';
  }

  Future<void> _render() async {
    final s = widget.deps.machine.state;
    if (!s.isCardSynced) {
      if (_bitmap != null) setState(() => _bitmap = null);
      _renderedKey = null;
      return;
    }
    final key = _key;
    if (key == _renderedKey) return;
    // T7 前名片档案用占位（P1 落地后从 UserProfile 读）
    final input = s.currentState.buildRenderInput(
      since: s.since,
      customText: s.customText,
      name: 'YOUR NAME',
      title: '',
    );
    final bmp = await widget.deps.renderer.render(input);
    if (!mounted || key != _key) return;
    setState(() {
      _bitmap = bmp;
      _renderedKey = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.deps.machine.state;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(T.s2),
      decoration: BoxDecoration(
        color: T.paper,
        borderRadius: BorderRadius.circular(T.rCard),
        border: Border.all(color: T.line),
      ),
      child: Row(
        children: [
          if (_bitmap != null)
            CardPreview(bitmap: _bitmap!, framed: false, compact: true)
          else
            const SizedBox(width: 148, height: 64),
          const SizedBox(width: T.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('现在', style: T.caption),
                const SizedBox(height: T.s05),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.isCardSynced ? T.accent : T.line,
                      ),
                    ),
                    const SizedBox(width: T.s1),
                    Flexible(
                      child: Text(
                        s.isCardSynced ? s.currentState.labelZh : '还没写过卡',
                        style: T.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: T.s05),
                Text(
                  s.isCardSynced
                      ? '${s.since.hour.toString().padLeft(2, '0')}:${s.since.minute.toString().padLeft(2, '0')} 写入'
                      : '选一个状态，翻转贴卡开始',
                  style: T.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 状态按钮格（主行动在屏2，这里全部是选择格 → A6 合规）。
/// 视觉语义（B 轮评审定稿）：**状态强调 = 墨黑 monochrome**（当前态 2px 墨边）；
/// 橙色只属于"行动"（写入按钮/演示标记），不用于状态。
class _StateCell extends StatelessWidget {
  final CardState state;
  final bool isCurrent;
  final bool horizontal;

  /// 英雄位提示语（专注：翻转即写入）
  final String? hint;
  final VoidCallback onTap;

  const _StateCell({
    required this.state,
    required this.isCurrent,
    required this.onTap,
    this.horizontal = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final fg = T.ink;
    final caption = isCurrent ? '卡上' : hint;
    return Material(
      color: T.paper,
      borderRadius: BorderRadius.circular(T.rButton),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(T.rButton),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(T.rButton),
            border: Border.all(color: isCurrent ? T.ink : T.line, width: isCurrent ? 2 : 1),
          ),
          padding: const EdgeInsets.all(T.s1),
          child: horizontal
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(stateIcon(state), color: fg, size: 24),
                    const SizedBox(width: T.s1),
                    Text(state.buttonLabelZh,
                        style: T.body.copyWith(
                            fontWeight: FontWeight.w700, color: fg)),
                    if (caption != null) ...[
                      const SizedBox(width: T.s1),
                      Text('· $caption', style: T.caption),
                    ],
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(stateIcon(state), color: fg, size: 28),
                    const SizedBox(height: T.s1),
                    Text(state.buttonLabelZh,
                        style: T.body.copyWith(
                            fontWeight: FontWeight.w700, color: fg)),
                    if (caption != null) Text(caption, style: T.caption),
                  ],
                ),
        ),
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  final AppDeps deps;
  const _OverflowMenu({required this.deps});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: T.ink),
      tooltip: '更多',
      onSelected: (v) {
        if (v == 'about') {
          showAboutDialog(
            context: context,
            applicationName: 'focus_card',
            applicationVersion: 'M1 · demo',
            children: [
              Text('profile: ${deps.profile.profileId}', style: T.caption),
              Text('writer: ${deps.isMock ? "Mock（演示）" : "NFC"}',
                  style: T.caption),
              const Text('状态卡，专注为主打 —— 让你的状态，看得见',
                  style: T.caption),
            ],
          );
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'about', child: Text('关于')),
        PopupMenuItem(
          value: 'profile',
          enabled: false,
          child: Text('名片档案（M4）', style: T.caption),
        ),
        PopupMenuItem(
          value: 'unbind',
          enabled: false,
          child: Text('解绑卡片（M3）', style: T.caption),
        ),
      ],
    );
  }
}
