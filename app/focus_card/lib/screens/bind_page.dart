/// D1 · 轻配对仪式（M1 Mock 版，≤30 秒、3 步、可跳过；文案走 l10n）。
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/device/card_binding.dart';
import '../l10n/app_localizations.dart';

class BindPage extends StatefulWidget {
  final VoidCallback onDone;

  /// D1 真机配对：认领意图递来的真实 UID（优先于 mock）
  final String? realUid;
  const BindPage({super.key, required this.onDone, this.realUid});

  @override
  State<BindPage> createState() => _BindPageState();
}

class _BindPageState extends State<BindPage> {
  /// 0=发现中 1=已发现（命名） 2=庆祝
  int _step = 0;
  late final String _uid = widget.realUid ?? CardBinding.mockUid();
  late TextEditingController _nameController;
  bool _nameInit = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Localizations 不能在 initState 查（InheritedWidget 限制）→ didChangeDependencies
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _step = 1);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_nameInit) {
      _nameInit = true;
      _nameController = TextEditingController(
          text: AppLocalizations.of(context).bindDefaultName);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_nameInit) _nameController.dispose();
    super.dispose();
  }

  Future<void> _complete({required String name}) async {
    final l = AppLocalizations.of(context); // await 前捕获，避免跨异步用 context
    setState(() => _step = 2);
    await CardBindingStore.save(CardBinding(
      uid: _uid,
      name: name.trim().isEmpty ? l.bindDefaultName : name.trim(),
      boundAt: DateTime.now(),
    ));
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                      Text(l.bindDiscovering, style: T.display),
                      const SizedBox(height: T.s2),
                      Text(l.bindDiscoverHint,
                          style: T.body.copyWith(color: T.inkSub)),
                      const SizedBox(height: T.s1),
                      Text(l.bindMockNote, style: T.micro),
                    ],
                  ),
                1 => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 64, color: T.ink),
                      const SizedBox(height: T.s3),
                      Text(l.bindFound, style: T.title),
                      const SizedBox(height: T.s1),
                      Text('${l.bindUidPrefix} $_uid', style: T.meta),
                      const SizedBox(height: T.s3),
                      TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: l.bindNameLabel,
                          helperText: l.bindNameHelper,
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
                          child: Text(l.bindComplete,
                              style: T.title.copyWith(color: T.onAccent)),
                        ),
                      ),
                      const SizedBox(height: T.s1),
                      TextButton(
                        onPressed: () =>
                            _complete(name: l.bindDefaultName),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(T.minTouch, T.minTouch),
                          foregroundColor: T.inkSub,
                        ),
                        child: Text(l.skip),
                      ),
                    ],
                  ),
                _ => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 96, color: T.accent),
                      const SizedBox(height: T.s3),
                      Text(l.bindDone, style: T.display),
                      const SizedBox(height: T.s2),
                      Text(l.bindDoneSub,
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
