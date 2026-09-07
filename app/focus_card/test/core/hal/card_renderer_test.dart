import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/core/hal/card_bitmap.dart';
import 'package:focus_card/core/hal/card_renderer.dart';
import 'package:focus_card/core/hal/device_profile.dart';
import 'package:focus_card/core/hal/protocol.dart';
import 'package:focus_card/core/hal/rle.dart';

import '../../helpers/load_fonts.dart';

/// CardBitmap → ui.Image（golden 比对用）
Future<ui.Image> _toImage(CardBitmap bmp) {
  final rgba = Uint8List(bmp.width * bmp.height * 4);
  for (var y = 0; y < bmp.height; y++) {
    for (var x = 0; x < bmp.width; x++) {
      final i = (y * bmp.width + x) * 4;
      final v = bmp.pixelAt(x, y) ? 0 : 255;
      rgba[i] = v;
      rgba[i + 1] = v;
      rgba[i + 2] = v;
      rgba[i + 3] = 255;
    }
  }
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
      rgba, bmp.width, bmp.height, ui.PixelFormat.rgba8888, completer.complete);
  return completer.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final profile = DeviceProfile.gen1Placeholder;
  final renderer = CardRenderer(profile);

  CardRenderInput focusing({String? custom}) => CardRenderInput(
        templateId: 'focusing',
        stateWord: 'FOCUSING',
        timeText: '14:32',
        customText: custom,
      );

  setUpAll(() async {
    await loadCardFonts();
  });

  group('H2 · CardRenderer 基础契约', () {
    test('尺寸与字节数：296×128 → 4736B', () async {
      final bmp = await renderer.render(focusing());
      expect(bmp.width, 296);
      expect(bmp.height, 128);
      expect(bmp.stride, 37);
      expect(bmp.byteLength, 4736);
      expect(bmp.bytes.length, profile.canvasBytes);
    });

    test('确定性：同输入两次渲染字节一致（WYSIWYG 同源前提）', () async {
      final a = await renderer.render(focusing(custom: '15:30 后可打扰'));
      final b = await renderer.render(focusing(custom: '15:30 后可打扰'));
      expect(a.bytes, b.bytes);
    });

    test('未知模板抛 StateError', () {
      expect(
          () => renderer.render(const CardRenderInput(templateId: 'nope')),
          throwsStateError);
    });
  });

  group('H2 · 渲染内容断言', () {
    test('纸面干净：四角白，全图黑占比在合理区间', () async {
      final bmp = await renderer.render(focusing());
      expect(bmp.pixelAt(0, 0), isFalse);
      expect(bmp.pixelAt(295, 0), isFalse);
      expect(bmp.pixelAt(0, 127), isFalse);
      expect(bmp.pixelAt(295, 127), isFalse);
      expect(bmp.blackRatio(), greaterThan(0.0));
      expect(bmp.blackRatio(), lessThan(0.4));
    });

    test('stateWord/time 区域有墨，accent 为实心点', () async {
      final bmp = await renderer.render(focusing());
      final r = profile.layoutFor('focusing')!;
      final sw = r.regions['stateWord']!;
      expect(bmp.blackRatioIn(sw.x, sw.y, sw.w, sw.h), greaterThan(0.02));
      final t = r.regions['time']!;
      expect(bmp.blackRatioIn(t.x, t.y, t.w, t.h), greaterThan(0.02));
      final a = r.regions['accent']!;
      expect(bmp.blackRatioIn(a.x, a.y, a.w, a.h), greaterThan(0.3));
    });

    test('中文自定义留言渲染有墨（CJK 字体生效）', () async {
      final bmp = await renderer.render(focusing(custom: '15:30 后可打扰'));
      final cr = profile.layoutFor('focusing')!.regions['customText']!;
      expect(bmp.blackRatioIn(cr.x, cr.y, cr.w, cr.h), greaterThan(0.01));
    });

    test('名片模板：name/title 有墨 + QR 占位框上边线', () async {
      final bmp = await renderer.render(const CardRenderInput(
        templateId: 'card',
        name: 'ALEX CHEN',
        title: 'PRODUCT DESIGN',
      ));
      final r = profile.layoutFor('card')!;
      final n = r.regions['name']!;
      expect(bmp.blackRatioIn(n.x, n.y, n.w, n.h), greaterThan(0.02));
      final t = r.regions['title']!;
      expect(bmp.blackRatioIn(t.x, t.y, t.w, t.h), greaterThan(0.02));
      final q = r.regions['qr']!;
      expect(bmp.blackRatioIn(q.x, q.y, q.w, 3), greaterThan(0.5));
    });
  });

  group('H2×H3×H4 · 集成探针', () {
    test('渲染 → RLE → 协议帧 装进 payload 预算，且文字态压缩显著', () async {
      final bmp = await renderer.render(focusing(custom: '开会中，急事电话'));
      final compressed = rleEncode(bmp.bytes);
      final frame = CardFrame(
        deviceId: 1,
        compression: CardFrame.compressionRle,
        imageData: compressed,
      );
      expect(profile.fitsPayload(frame.encodedSize), isTrue);
      expect(compressed.length, lessThan(bmp.bytes.length ~/ 2));
      // 协议 round-trip 后位图不变
      final decoded = CardFrame.decode(frame.encode());
      expect(rleDecode(decoded.imageData), bmp.bytes);
    });
  });

  group('H2 · golden（本机基线，M5 换 profile 时重新生成）', () {
    test('focusing 模板', () async {
      final bmp = await renderer.render(focusing(custom: '15:30 后可打扰'));
      await expectLater(
          _toImage(bmp), matchesGoldenFile('goldens/card_focusing.png'));
    });

    test('card 名片模板', () async {
      final bmp = await renderer.render(const CardRenderInput(
        templateId: 'card',
        name: 'ALEX CHEN',
        title: 'PRODUCT DESIGN',
      ));
      await expectLater(
          _toImage(bmp), matchesGoldenFile('goldens/card_namecard.png'));
    });
  });
}
