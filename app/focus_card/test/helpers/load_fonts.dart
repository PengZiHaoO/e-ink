/// 测试环境显式加载卡片画布字体（golden/渲染断言依赖真实字形）。
///
/// 注：FontLoader 在 package:flutter/services（不在 dart:ui）。
library;

import 'package:flutter/services.dart' show FontLoader, rootBundle;

Future<void> loadCardFonts() async {
  final loader = FontLoader('NotoSansSC')
    ..addFont(rootBundle.load('assets/fonts/NotoSansSC.ttf'));
  await loader.load();
  // 测试环境补载 Material 图标字体（否则 golden 里图标呈方框；
  // 生产环境由 SDK 自带，不受影响）
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}
