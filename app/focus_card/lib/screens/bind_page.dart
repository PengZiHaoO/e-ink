/// D1 · 轻配对仪式（M1 Mock 版，≤30 秒、3 步、可跳过）。
///
/// 发现（Mock 1.2s）→ 命名 → ✓ 庆祝。兜底：跳过也能用（M3 首写静默绑定）。
/// M3/T6 替换点：mockUid → 真实 NFC UID 发现；prefs → sqflite CardBinding 表。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/deps.dart';
import '../app/theme.dart';
import '../core/device/card_binding.dart';

class BindPage extends StatefulWidget {
  final VoidCallback onDone;
  const BindPage({super.key, required this.onDone});

  @override
  State<BindPage> createState() => _BindPageState();
}

class _BindPageState extends State<BindPage> {
  /// 0=发现中 1=已发现（命名） 2=庆祝
  int _step = 0;
  late final String _uid = CardBinding.mockUid();
  final _nameController = TextEditingController(text: '我的专注卡');
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Mock 发现过程（M3：真实 NFC 会话发现标签）
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _step = 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _complete({required String name}) async {
    setState(() => _step = 2);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PrefsKeys.binding,
      CardBinding.encode(CardBinding(
        uid: _uid,
        name: name.trim().isEmpty ? '我的专注卡' : name.trim(),
        boundAt: DateTime.now(),
      )),
    );
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(T.s3),
              child: switch (_step) {
                0 => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(color: T.accent),
                      ),
                      const SizedBox(height: T.s4),
                      Text('认识你的卡片', style: T.display),
                      const SizedBox(height: T.s2),
                      Text('把手机贴住卡片…', style: T.body.copyWith(color: T.inkSub)),
                      const SizedBox(height: T.s1),
                      Text('（演示模式：模拟发现过程）', style: T.caption),
                    ],
                  ),
                1 => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 64, color: T.ink),
                      const SizedBox(height: T.s3),
                      Text('发现卡片', style: T.title),
                      const SizedBox(height: T.s1),
                      Text('编号 $_uid', style: T.caption),
                      const SizedBox(height: T.s3),
                      TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: '给它起个名字',
                          helperText: '跳过则用默认名',
                        ),
                      ),
                      const SizedBox(height: T.s3),
                      SizedBox(
                        width: double.infinity,
                        height: T.primaryHeight,
                        child: FilledButton(
                          onPressed: () =>
                              _complete(name: _nameController.text),
                          style: FilledButton.styleFrom(
                            backgroundColor: T.accent,
                            foregroundColor: T.onAccent,
                          ),
                          child: Text('完成绑定',
                              style: T.title.copyWith(color: T.onAccent)),
                        ),
                      ),
                      const SizedBox(height: T.s1),
                      TextButton(
                        onPressed: () => _complete(name: '我的专注卡'),
                        style: TextButton.styleFrom(
                          minimumSize:
                              const Size(T.minTouch, T.minTouch),
                          foregroundColor: T.inkSub,
                        ),
                        child: const Text('跳过'),
                      ),
                    ],
                  ),
                _ => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 96, color: T.accent),
                      const SizedBox(height: T.s3),
                      Text('绑定完成', style: T.display),
                      const SizedBox(height: T.s2),
                      Text('这张卡现在是你的了',
                          style: T.body.copyWith(color: T.inkSub)),
                    ],
                  ),
              },
            ),
          ),
        ),
      ),
    );
  }
}
