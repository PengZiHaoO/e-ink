/// D1 · 卡片绑定记录（M1 轻版）。
///
/// M1：Mock UID + prefs 存储（桌面演示绑定仪式流程）；
/// M3/T6：真实 NFC UID 发现 + 迁移 sqflite（CardBinding 表，全景 §4.1）。
library;

import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class CardBindingStore {
  static const key = 'card_binding.v1';

  static Future<CardBinding?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return CardBinding.decode(prefs.getString(key));
  }

  static Future<void> save(CardBinding binding) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, CardBinding.encode(binding));
  }
}

class CardBinding {
  final String uid;
  final String name;
  final DateTime boundAt;

  const CardBinding({
    required this.uid,
    required this.name,
    required this.boundAt,
  });

  Map<String, Object?> toJson() => {
        'uid': uid,
        'name': name,
        'boundAt': boundAt.toIso8601String(),
      };

  factory CardBinding.fromJson(Map<String, Object?> json) => CardBinding(
        uid: json['uid'] as String,
        name: json['name'] as String,
        boundAt: DateTime.parse(json['boundAt'] as String),
      );

  static String encode(CardBinding b) => jsonEncode(b.toJson());

  /// 损坏数据返回 null（视为未绑定，走仪式重绑）
  static CardBinding? decode(String? raw) {
    if (raw == null) return null;
    try {
      return CardBinding.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return null;
    }
  }

  /// Mock UID（桌面演示）：MOCK-XXXX 十六进制尾号
  static String mockUid() {
    final r = Random();
    final tail = r.nextInt(0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0');
    return 'MOCK-$tail';
  }
}
