/// P1 · 名片档案（姓名/头衔/二维码内容），prefs 持久化。
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String name;
  final String title;
  final String qrContent;

  const UserProfile({this.name = '', this.title = '', this.qrContent = ''});

  /// 姓名非空 = 档案可用（首次使用名片的门槛）
  bool get isComplete => name.trim().isNotEmpty;

  UserProfile copyWith({String? name, String? title, String? qrContent}) =>
      UserProfile(
        name: name ?? this.name,
        title: title ?? this.title,
        qrContent: qrContent ?? this.qrContent,
      );

  Map<String, Object?> toJson() =>
      {'name': name, 'title': title, 'qrContent': qrContent};

  factory UserProfile.fromJson(Map<String, Object?> json) => UserProfile(
        name: (json['name'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        qrContent: (json['qrContent'] as String?) ?? '',
      );
}

class UserProfileStore {
  static const key = 'user_profile.v1';

  static Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return const UserProfile();
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return const UserProfile(); // 损坏数据视为空档案
    }
  }

  static Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(profile.toJson()));
  }
}
