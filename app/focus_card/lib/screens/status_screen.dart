/// 屏1「状态」：现在卡（当前状态迷你预览）+ 专注英雄位 + 2×2 状态网格。
/// 功能映射（全景 §5）：S1/S2 网格 · S4 现在卡 · D3/P 设置溢出 · 语言开关（T3.5）。
library;

import 'package:flutter/material.dart';

import '../app/card_preview.dart';
import '../app/deps.dart';
import '../app/theme.dart';
import '../core/hal/card_bitmap.dart';
import '../core/state/card_state.dart';
import '../l10n/app_localizations.dart';
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

  bool _isCurrent(CardState s) =>
      deps.machine.state.isCardSynced && deps.machine.state.currentState == s;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                        Text(l.statusTitle, style: T.title),
                        const Spacer(),
                        _OverflowMenu(deps: deps),
                      ],
                    ),
                    const SizedBox(height: T.s2),
                    _NowCard(deps: deps),
                    const SizedBox(height: T.s3),
                    Text(l.switchTitle.toUpperCase(), style: T.micro),
                    const SizedBox(height: T.s2),
                    // 专注 = 英雄位：实底墨卡（衣橱里抽出的那张），物理卡比例
                    AspectRatio(
                      aspectRatio: T.cardAspect,
                      child: _StateCell(
                        state: CardState.focusing,
                        isCurrent: _isCurrent(CardState.focusing),
                        hint: l.flipHint,
                        zh: deps.isZh,
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
                      childAspectRatio: T.cardAspect, // 数字衣橱：格=卡
                      children: [
                        for (final s in _gridStates)
                          _StateCell(
                            state: s,
                            isCurrent: _isCurrent(s),
                            zh: deps.isZh,
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
}

/// 「现在」卡：当前已提交状态的迷你预览（S4）+ 上卡时间。
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

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = widget.deps.machine.state;
    final zh = widget.deps.isZh;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(T.s2),
      decoration: BoxDecoration(
        color: T.paper,
        borderRadius: BorderRadius.circular(T.rCard),
        border: Border.all(color: T.lineStrong), // 卡片对象外框
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
                Text(l.nowLabel.toUpperCase(), style: T.micro),
                const SizedBox(height: T.s05),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.isCardSynced ? T.ink : T.inkSub,
                      ),
                    ),
                    const SizedBox(width: T.s1),
                    Flexible(
                      child: Text(
                        s.isCardSynced
                            ? s.currentState.label(zh)
                            : l.notWritten,
                        style: T.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: T.s05),
                Text(
                  s.isCardSynced
                      ? l.writtenAt(_hhmm(s.since))
                      : l.notWrittenHint,
                  style: s.isCardSynced ? T.meta : T.micro,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 状态卡格（数字衣橱）：每格 = 物理卡比例的卡片对象。
/// 英雄（专注）= 实底墨卡（抽出的那张）；其余 = 发丝线描边；
/// 当前 = 墨描边 + ON CARD 微标签 + 信号点。
class _StateCell extends StatelessWidget {
  final CardState state;
  final bool isCurrent;
  final bool zh;
  final bool horizontal;
  final String? hint;
  final VoidCallback onTap;

  const _StateCell({
    required this.state,
    required this.isCurrent,
    required this.zh,
    required this.onTap,
    this.horizontal = false,
    this.hint,
  });

  bool get _isHero => state == CardState.focusing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fg = _isHero ? T.onInk : T.ink;
    final subFg = _isHero ? T.onInkSub : T.inkSub;
    final caption = isCurrent ? l.onCard : hint;
    return Material(
      color: _isHero ? T.ink : T.paper,
      borderRadius: BorderRadius.circular(T.rCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(T.rCard),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(T.rCard),
            border: Border.all(
              color: _isHero ? T.ink : (isCurrent ? T.ink : T.hairline),
              width: isCurrent && !_isHero ? 1.5 : 1,
            ),
          ),
          // 卡格=物理卡比例，竖向空间紧：格子内边距收紧，英雄位保持宽松
          padding: EdgeInsets.all(horizontal ? T.s2 : T.s1),
          child: horizontal
              ? Row(
                  children: [
                    Icon(stateIcon(state), color: fg, size: 24),
                    const SizedBox(width: T.s2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.buttonLabel(zh),
                              style: T.title.copyWith(color: fg)),
                          if (caption != null) ...[
                            const SizedBox(height: T.s05),
                            Text(caption.toUpperCase(),
                                style: T.micro.copyWith(color: subFg)),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent ? T.accent : T.onInkSub,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(stateIcon(state), color: fg, size: 20),
                        const Spacer(),
                        if (isCurrent)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: T.accent),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(state.buttonLabel(zh),
                        style: T.body
                            .copyWith(fontWeight: FontWeight.w700, color: fg)),
                    if (caption != null)
                      Text(caption.toUpperCase(),
                          style: T.micro.copyWith(color: subFg)),
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
    final l = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: T.ink),
      onSelected: (v) {
        if (v == 'about') {
          showAboutDialog(
            context: context,
            applicationName: 'focus_card',
            applicationVersion: 'M1 · demo',
            children: [
              Text('profile: ${deps.profile.profileId}', style: T.meta),
              Text('writer: ${deps.isMock ? "Mock" : "NFC"}', style: T.meta),
              Text(l.aboutTagline,
                  style: T.body.copyWith(color: T.inkSub)),
            ],
          );
        } else if (v == 'lang') {
          deps.localeController.toggle();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'lang',
          child: Text(
              '${l.menuLanguage}: ${deps.isZh ? "中文" : "English"} ⇄'),
        ),
        PopupMenuItem(value: 'about', child: Text(l.menuAbout)),
        PopupMenuItem(
          value: 'profile',
          enabled: false,
          child: Text(l.menuProfile,
              style: T.body.copyWith(color: T.inkSub)),
        ),
        PopupMenuItem(
          value: 'unbind',
          enabled: false,
          child: Text(l.menuUnbind, style: T.body.copyWith(color: T.inkSub)),
        ),
      ],
    );
  }
}
