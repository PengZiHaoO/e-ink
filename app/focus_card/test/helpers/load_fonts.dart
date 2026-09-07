/// 测试环境显式加载卡片画布字体（golden/渲染断言依赖真实字形）。
///
/// 注：FontLoader 在 package:flutter/services（不在 dart:ui）。
library;

import 'package:flutter/services.dart' show FontLoader, rootBundle;

Future<void> loadCardFonts() async {
  final loader = FontLoader('NotoSansSC')
    ..addFont(rootBundle.load('assets/fonts/NotoSansSC.ttf'));
  await loader.load();
}
