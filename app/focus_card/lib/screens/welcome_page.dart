/// N1 · 首启欢迎（3 页可跳过，文案走 l10n）。
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/deps.dart';
import '../app/theme.dart';
import '../l10n/app_localizations.dart';

class WelcomePage extends StatefulWidget {
  final VoidCallback onDone;
  const WelcomePage({super.key, required this.onDone});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _controller = PageController();
  int _index = 0;

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
    final l = AppLocalizations.of(context);
    final pages = [
      (
        icon: Icons.credit_card,
        title: l.welcome1Title,
        desc: l.welcome1Desc,
      ),
      (
        icon: Icons.screen_rotation_alt,
        title: l.welcome2Title,
        desc: l.welcome2Desc,
      ),
      (
        icon: Icons.menu_book_outlined,
        title: l.welcome3Title,
        desc: l.welcome3Desc,
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final p in pages)
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
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
                    child: Text(l.skip),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (_index < pages.length - 1) {
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
                      _index < pages.length - 1 ? l.next : l.start,
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
