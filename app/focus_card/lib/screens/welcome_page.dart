/// N1 · 首启欢迎（3 页可跳过）。
/// 完成后写 prefs 标记，二启不再出现（验收：首启出现、二启不出现）。
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/deps.dart';
import '../app/theme.dart';

class WelcomePage extends StatefulWidget {
  final VoidCallback onDone;
  const WelcomePage({super.key, required this.onDone});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    (
      icon: Icons.credit_card,
      title: '这是你的状态卡',
      desc: '贴在手机背面，无电池、不充电，\n画面一旦刷新就永久保持。',
    ),
    (
      icon: Icons.screen_rotation_alt,
      title: '翻转即写',
      desc: '选一个状态，翻转手机贴住卡片，\n几秒后卡片就是你现在的状态。',
    ),
    (
      icon: Icons.menu_book_outlined,
      title: '自动成账本',
      desc: '每次切换都会留下一条记录，\n专注多久，一目了然。',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.welcomeDone, true);
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final p in _pages)
                    Padding(
                      padding: const EdgeInsets.all(T.s4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(p.icon, size: 96, color: T.ink),
                          const SizedBox(height: T.s4),
                          Text(p.title, style: T.display, textAlign: TextAlign.center),
                          const SizedBox(height: T.s2),
                          Text(p.desc,
                              style: T.body.copyWith(color: T.inkSub),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // 页点（当前页 accent）
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: T.s1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index ? T.accent : T.line,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: T.s3),
            Padding(
              padding: const EdgeInsets.fromLTRB(T.s3, 0, T.s3, T.s3),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(T.minTouch, T.minTouch),
                      foregroundColor: T.inkSub,
                    ),
                    child: const Text('跳过'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (_index < _pages.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      } else {
                        _finish();
                      }
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, T.primaryHeight),
                      backgroundColor: T.accent,
                      foregroundColor: T.onAccent,
                    ),
                    child: Text(
                      _index < _pages.length - 1 ? '下一页' : '开始',
                      style: T.title.copyWith(color: T.onAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
