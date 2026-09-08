/// focus_card 入口：生产装配（AppDeps.create）→ FocusCardApp。
/// 测试直接构造 AppDeps 注入 FocusCardApp，不经过本文件的 Bootstrap。
library;

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/deps.dart';
import 'app/theme.dart';

void main() {
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});

  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  AppDeps? _deps;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final deps = await AppDeps.create();
    if (mounted) setState(() => _deps = deps);
  }

  @override
  Widget build(BuildContext context) {
    final deps = _deps;
    if (deps == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: T.paper,
          child: Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(color: T.accent, strokeWidth: 3),
            ),
          ),
        ),
      );
    }
    return FocusCardApp(deps: deps);
  }
}
