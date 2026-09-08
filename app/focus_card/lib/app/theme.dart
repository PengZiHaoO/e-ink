/// UI 规范 §2 设计 Token —— 唯一合法取值表（A1/A2/A3 检查对照此处）。
library;

import 'package:flutter/material.dart';

abstract final class T {
  // ---- §2.1 颜色（纸白/墨黑/灰字/灰线/单橙）----
  static const paper = Color(0xFFFAFAF7);
  static const ink = Color(0xFF1A1A1A);
  static const inkSub = Color(0xFF6B6B66); // 4.9:1 ✓ 正文可用
  static const line = Color(0xFF8A8A85); // 3.3:1 仅边框/装饰，禁止文字
  static const accent = Color(0xFFE8590C); // 唯一彩色（图形/按钮底）
  static const accentText = Color(0xFFC74A08); // 强调色文字深变体（纸白上 4.6:1，A4 合规）
  static const onAccent = Color(0xFFFFFFFF);

  // ---- §2.2 字级（4 级、2 字重 w400/w700）----
  static const display = TextStyle(
      fontSize: 40, fontWeight: FontWeight.w700, color: ink, height: 1.1);
  static const title =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ink);
  static const body =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: ink);
  static const caption =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: inkSub);

  // ---- §2.3 间距（8px 网格；4 仅图标-文字间隙）----
  static const s05 = 4.0;
  static const s1 = 8.0;
  static const s2 = 16.0;
  static const s3 = 24.0;
  static const s4 = 32.0;
  static const s6 = 48.0;

  // ---- §2.4 圆角 / 尺寸 ----
  static const rCard = 4.0; // 卡片预览容器（模仿实体卡）
  static const rButton = 12.0;
  static const primaryHeight = 56.0; // 主按钮
  static const minTouch = 48.0; // 可点元素下限

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        // CJK 兜底：桌面端系统可能无中文字体，直接用已捆绑的 Noto Sans SC
        fontFamily: 'NotoSansSC',
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
          surface: paper,
          primary: accent,
          onPrimary: onAccent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: paper,
          indicatorColor: accent.withValues(alpha: 0.14),
          labelTextStyle: const WidgetStatePropertyAll(T.body),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(rButton)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(rButton),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
          counterStyle: caption,
          helperStyle: caption,
          errorStyle: const TextStyle(fontSize: 13, color: accent),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ink,
          contentTextStyle: TextStyle(color: paper, fontSize: 16),
        ),
      );
}
