/// UI 规范 §2 Token —— 设计语言 "Digital Card" v2（2026-09-09 定稿）。
///
/// Apple（留白/发丝线/克制）× Kindle（纸魂/墨字）× Nothing（点阵元信息/大写微标签）
/// × Figma（编辑器纪律/1px 结构）→ 合成原则：**每个界面元素都像一张卡片对象**。
library;

import 'package:flutter/material.dart';

abstract final class T {
  // ---- 纸与墨（Kindle 纸魂）----
  static const paper = Color(0xFFFAFAF8);
  static const ink = Color(0xFF141412);
  static const inkSub = Color(0xFF6E6E68); // 4.8:1 on paper
  static const hairline = Color(0xFFE4E2DC); // 1px 结构线 / 非当前卡格（Apple/Figma）
  static const lineStrong = Color(0xFF8A8A85); // 仅卡片对象外框
  static const onInk = Color(0xFFFAFAF8); // 墨卡上的纸色文字
  static const onInkSub = Color(0xB3FAFAF8); // 70% 纸色（墨卡上次级）

  // ---- 信号色：仅"活"的状态（写入中/当前点/CTA）----
  static const accent = Color(0xFFE8590C);
  static const onAccent = Color(0xFFFFFFFF);

  // ---- 字型：编辑感尺度对比 ----
  static const display = TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w700,
      color: ink,
      height: 1.05,
      letterSpacing: -0.5);
  static const title =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ink);
  static const body =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: ink);

  /// 大写微标签（Nothing 点阵感）；中文不做 uppercase 变换但保留字距
  static const micro = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: inkSub,
      letterSpacing: 1.2);

  /// 技术元信息（UID/画布规格/时间戳）——等宽，仪器般的诚实
  static const meta = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: inkSub,
      fontFamily: 'monospace');

  // ---- 间距（8px 网格）----
  static const s05 = 4.0;
  static const s1 = 8.0;
  static const s2 = 16.0;
  static const s3 = 24.0;
  static const s4 = 32.0;
  static const s6 = 48.0;

  // ---- 圆角：crisp（Figma）----
  static const rCard = 4.0; // 卡片对象
  static const rButton = 8.0; // 控件

  // ---- 尺寸 ----
  static const primaryHeight = 56.0;
  static const minTouch = 48.0;

  /// 物理卡比例（296:128）——"数字衣橱"格形
  static const cardAspect = 296 / 128;

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        // CJK 兜底：桌面端系统可能无中文字体
        fontFamily: 'NotoSansSC',
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
          surface: paper,
          primary: accent,
          onPrimary: onAccent,
        ),
        dividerTheme:
            const DividerThemeData(color: hairline, thickness: 1, space: 1),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: paper,
          indicatorColor: accent.withValues(alpha: 0.14),
          labelTextStyle: const WidgetStatePropertyAll(body),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(rButton)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(rButton),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
          counterStyle: meta,
          helperStyle: micro,
          errorStyle: const TextStyle(fontSize: 13, color: accent),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ink,
          contentTextStyle: TextStyle(color: paper, fontSize: 16),
        ),
      );
}
