/// 应用壳：FocusCardApp + LaunchGate（首启流：欢迎 → 绑定 → 主页）。
/// T3.5：locale 由 LocaleController 驱动，热切换不重启。
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/device/card_binding.dart';
import '../l10n/app_localizations.dart';
import '../screens/bind_page.dart';
import '../screens/main_page.dart';
import '../screens/welcome_page.dart';
import 'deps.dart';
import 'theme.dart';

class FocusCardApp extends StatelessWidget {
  final AppDeps deps;
  const FocusCardApp({super.key, required this.deps});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: deps.localeController,
      builder: (context, _) => MaterialApp(
        title: 'focus_card',
        debugShowCheckedModeBanner: false,
        theme: T.light(),
        locale: deps.localeController.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LaunchGate(deps: deps),
      ),
    );
  }
}

enum _GateStep { loading, welcome, bind, home }

class LaunchGate extends StatefulWidget {
  final AppDeps deps;
  const LaunchGate({super.key, required this.deps});

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  _GateStep _step = _GateStep.loading;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (!(prefs.getBool(PrefsKeys.welcomeDone) ?? false)) {
      setState(() => _step = _GateStep.welcome);
      return;
    }
    if (CardBinding.decode(prefs.getString(PrefsKeys.binding)) == null) {
      setState(() => _step = _GateStep.bind);
      return;
    }
    setState(() => _step = _GateStep.home);
  }

  /// 欢迎完成 → 有绑定直接进主页，否则进绑定仪式
  Future<void> _afterWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _step =
        CardBinding.decode(prefs.getString(PrefsKeys.binding)) == null
            ? _GateStep.bind
            : _GateStep.home);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _GateStep.loading => const _Splash(),
      _GateStep.welcome => WelcomePage(onDone: _afterWelcome),
      _GateStep.bind =>
        BindPage(onDone: () => setState(() => _step = _GateStep.home)),
      _GateStep.home => MainPage(deps: widget.deps),
    };
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: T.paper,
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(color: T.accent, strokeWidth: 3),
          ),
        ),
      );
}
