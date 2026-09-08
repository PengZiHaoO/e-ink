/// 主框架：底部两 Tab（状态/记录）+ N3 演示模式横幅。
library;

import 'package:flutter/material.dart';

import '../app/deps.dart';
import '../app/theme.dart';
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
  Widget build(BuildContext context) {
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.adjust_outlined),
            selectedIcon: Icon(Icons.adjust, color: T.accent),
            label: '状态',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: T.accent),
            label: '记录',
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
    return Container(
      width: double.infinity,
      color: T.accent.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(
          horizontal: T.s2, vertical: T.s1),
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
          Text('演示模式 · 模拟写入，未连接真实卡片', style: T.caption),
        ],
      ),
    );
  }
}
