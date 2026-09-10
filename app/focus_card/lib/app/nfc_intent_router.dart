/// 认领意图路由（Flutter 侧）：MainActivity 递来 {action, uid} 后决策：
/// - 屏2 写入会话进行中 → 忽略（会话自己拥有标签）
/// - 未配对 → 推配对流（真实 UID，D1 真机配对入口）
/// - 已配对且 UID 同源 → 推屏2 写入（当前状态）
/// - 已配对但 UID 异源 → 忽略 + 日志（不是我们的卡）
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/device/card_binding.dart';
import '../screens/bind_page.dart';
import '../screens/write_screen.dart';
import 'deps.dart';

/// 全局导航键：路由从非 UI 上下文（MethodChannel 回调）推页面
class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}

class NfcIntentRouter {
  static const _channel = MethodChannel('focus_card/nfc_intent');
  static AppDeps? _deps;

  static void attach(AppDeps deps) {
    _deps = deps;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onCardIntent') return;
      final args = call.arguments as Map<Object?, Object?>?;
      final uid = (args?['uid'] as String?) ?? '';
      final action = (args?['action'] as String?) ?? '';
      _handle(uid, action);
    });
  }

  static Future<void> _handle(String uid, String action) async {
    final deps = _deps;
    if (deps == null || !deps.homeReady) return; // 欢迎/绑定 gate 期间不路由
    if (deps.writeScreenActive) return; // 屏2 会话拥有标签
    if (uid.isEmpty) return;
    debugPrint('[NFC-INTENT] uid=$uid action=$action');

    final nav = AppNavigator.key.currentState;
    if (nav == null) return;
    final binding = await CardBindingStore.load(); // 新鲜读，避免陈旧

    if (binding == null) {
      // 未配对：真机配对入口（D1）——空白卡首页贴近即达；完成即 pop
      nav.push(MaterialRouteP(
        builder: (_) => BindPage(
          realUid: uid,
          onDone: () => AppNavigator.key.currentState?.pop(),
        ),
      ));
    } else if (binding.uid == uid) {
      // 我们的卡：刷新/写入当前状态
      nav.push(MaterialRouteP(
        builder: (_) => WriteScreen(
          deps: deps,
          targetState: deps.machine.state.currentState,
        ),
      ));
    } else {
      debugPrint('[NFC-INTENT] ignore unknown uid (bound=${binding.uid})');
    }
  }
}

/// 小封装，避免路由调用处重复 MaterialPageRoute 泛型噪音
class MaterialRouteP extends MaterialPageRoute<void> {
  MaterialRouteP({required super.builder});
}
