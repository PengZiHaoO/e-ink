/// T9 · 姿态规则机（扣下专注 / 拿起结束）。
///
/// 规则表（冲突消解，2026-09-10 定稿）：
/// | 卡当前状态        | 扣下≥3s                    | 拿起≥10s                 |
/// |------------------|---------------------------|--------------------------|
/// | 可打扰（待机武装） | 自动开始 focus + 写卡       | —                        |
/// | 专注中            | —                         | 自动结束 + 重写可打扰      |
/// | 休息/离开/名片     | 不响应（不覆盖故意状态）     | 不响应                   |
/// | 屏2 会话中        | 让位                       | 让位                     |
/// | 充电中            | 抑制自动开始（误触发源）     | 自动结束不受影响          |
/// | 未配对            | 不响应                     | 不响应                   |
///
/// 手动写入永远最高优先级：任何 UI 写入立即改状态，姿态计时自然失效。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/device/card_binding.dart';
import '../core/state/card_state.dart';
import '../l10n/app_localizations.dart';
import 'deps.dart';
import 'nfc_intent_router.dart';

void _log(String m) => debugPrint('[POSTURE] $m');

class PostureWatcher {
  PostureWatcher({
    required this.deps,
    this.faceDownHold = const Duration(seconds: 3),
    this.faceUpHold = const Duration(seconds: 10),
  });

  final AppDeps deps;
  final Duration faceDownHold;
  final Duration faceUpHold;

  static const _channel = MethodChannel('focus_card/posture');
  Timer? _timer;

  void attach() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onPosture') return;
      final args = call.arguments as Map<Object?, Object?>?;
      handlePosture(
        (args?['posture'] as String?) ?? 'unknown',
        (args?['charging'] as bool?) ?? false,
      );
    });
  }

  /// 测试暴露入口：姿态转换经持续时间定时器生效（去抖）
  void handlePosture(String posture, bool charging) {
    _log('handle $posture charging=$charging');
    _timer?.cancel();
    if (posture != 'faceDown' && posture != 'faceUp') return;
    final hold = posture == 'faceDown' ? faceDownHold : faceUpHold;
    if (hold == Duration.zero) {
      // 零持续（测试）走 microtask；生产走真实 Timer
      Future.microtask(() => _fire(posture, charging));
    } else {
      _timer = Timer(hold, () {
        _log('sustain timer fired');
        _fire(posture, charging);
      });
    }
  }

  Future<void> _fire(String posture, bool charging) async {
    _log('fire $posture charging=$charging');
    if (deps.writeScreenActive) {
      _log('skip: writeScreenActive');
      return; // 屏2 会话拥有写入
    }
    final binding = await CardBindingStore.load();
    if (binding == null) {
      _log('skip: unbound');
      return; // 未配对不响应
    }
    final state = deps.machine.state;
    final l = _l10n();
    if (l == null) {
      _log('skip: no l10n context');
      return;
    }

    if (posture == 'faceDown') {
      if (charging) {
        _log('skip: charging');
        return; // 充电扣放 = 误触发源
      }
      if (state.currentState != CardState.available || !state.isCardSynced) {
        _log('skip: state=${state.currentState.name} synced=${state.isCardSynced}');
        return; // 只武装待机态；故意状态不覆盖
      }
      final prepared =
          await deps.orchestrator.prepare(newState: CardState.focusing);
      final r = await deps.orchestrator.submit(prepared);
      if (r.ok) _toast(l.postureFocusStarted);
    } else {
      if (state.currentState != CardState.focusing || !state.isCardSynced) {
        return; // 拿起只结束专注
      }
      final prepared =
          await deps.orchestrator.prepare(newState: CardState.available);
      final r = await deps.orchestrator.submit(prepared);
      if (r.ok) _toast(l.postureFocusEnded);
    }
  }

  AppLocalizations? _l10n() {
    final ctx = AppNavigator.key.currentContext;
    return ctx == null ? null : AppLocalizations.of(ctx);
  }

  void _toast(String msg) {
    final ctx = AppNavigator.key.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void dispose() => _timer?.cancel();
}
