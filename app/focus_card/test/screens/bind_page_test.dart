import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/core/device/card_binding.dart';
import 'package:focus_card/l10n/app_localizations.dart';
import 'package:focus_card/screens/bind_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('D1：realUid 优先于 mock（真机配对入口）', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BindPage(realUid: 'ABC123', onDone: () {}),
    ));
    await tester.pump(const Duration(milliseconds: 1300)); // 发现 timer
    expect(find.text('发现卡片'), findsOneWidget);
    expect(find.textContaining('ABC123'), findsOneWidget);

    await tester.tap(find.text('完成绑定'));
    await tester.pump();
    final b = await CardBindingStore.load();
    expect(b?.uid, 'ABC123');
  });

  testWidgets('D1：无 realUid → mock UID 兜底', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BindPage(onDone: () {}),
    ));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.tap(find.text('完成绑定'));
    await tester.pump();
    final b = await CardBindingStore.load();
    expect(b?.uid, startsWith('MOCK-'));
  });
}
