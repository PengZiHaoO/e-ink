import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/core/profile/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('默认档案：空 + isComplete false', () {
    const p = UserProfile();
    expect(p.isComplete, isFalse);
  });

  test('isComplete 只看姓名', () {
    expect(const UserProfile(name: ' A ').isComplete, isTrue);
    expect(const UserProfile(title: 'PM').isComplete, isFalse);
  });

  test('prefs round-trip', () async {
    SharedPreferences.setMockInitialValues({});
    await UserProfileStore.save(const UserProfile(
        name: 'ALEX CHEN', title: 'PRODUCT DESIGN', qrContent: 'https://a.b/c'));
    final p = await UserProfileStore.load();
    expect(p.name, 'ALEX CHEN');
    expect(p.title, 'PRODUCT DESIGN');
    expect(p.qrContent, 'https://a.b/c');
  });

  test('损坏数据 → 空档案（不炸）', () async {
    SharedPreferences.setMockInitialValues(
        {UserProfileStore.key: '{{{not-json'});
    final p = await UserProfileStore.load();
    expect(p.isComplete, isFalse);
  });

  test('copyWith 局部更新', () {
    const p = UserProfile(name: 'A', title: 'T', qrContent: 'Q');
    final q = p.copyWith(title: 'T2');
    expect(q.name, 'A');
    expect(q.title, 'T2');
    expect(q.qrContent, 'Q');
  });
}
