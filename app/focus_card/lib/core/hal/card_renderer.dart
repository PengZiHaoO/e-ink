/// H2 · CardRenderer —— 唯一渲染源（WYSIWYG 同源原则的支点）。
///
/// render(profile, input) → CardBitmap：
/// 屏2 预览与 NFC 写入 payload **必须出自同一次调用的输出**（全景 C1 检查项）。
///
/// 管线（图片生态预留，全景 §7）：布局 → 栅格 →（压缩/编码由 H4/H3 承接）。
/// 布局全部由 profile.layoutRules 参数化驱动，零硬编码像素——
/// 换硬件 = 换 profile，本文件不改（M5 校准 gate 验证点）。
library;

import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;

import 'card_bitmap.dart';
import 'device_profile.dart';

/// 渲染输入：由 W1 编排器组装（S 域状态 + P 域档案 + 时间快照）
class CardRenderInput {
  final String templateId;

  /// 英文状态词大字，如 FOCUSING
  final String? stateWord;

  /// 时间快照文本，如 "14:32"（卡片=快照，禁止实时走动）
  final String? timeText;

  /// 自定义留言（可中文，渲染下限 = fontRules.cjkMinPx）
  final String? customText;

  /// 名片模板：姓名 / 头衔
  final String? name;
  final String? title;

  /// 名片模板：QR 位图（M4/T7 生成；null → 渲染占位框）
  final CardBitmap? qrBitmap;

  const CardRenderInput({
    required this.templateId,
    this.stateWord,
    this.timeText,
    this.customText,
    this.name,
    this.title,
    this.qrBitmap,
  });
}

class CardRenderer {
  final DeviceProfile profile;

  CardRenderer(this.profile);

  static const String _fontFamily = 'NotoSansSC';
  static const ui.Color _ink = ui.Color(0xFF000000);
  static const ui.Color _paper = ui.Color(0xFFFFFFFF);

  Future<CardBitmap> render(CardRenderInput input) async {
    final layout = profile.layoutFor(input.templateId);
    if (layout == null) {
      throw StateError('模板不存在于 profile: ${input.templateId}');
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // 纸白底
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, profile.canvasW.toDouble(), profile.canvasH.toDouble()),
      ui.Paint()..color = _paper,
    );

    if (input.templateId == 'card') {
      _renderCardTemplate(canvas, layout, input);
    } else {
      _renderStateTemplate(canvas, layout, input);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(profile.canvasW, profile.canvasH);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    picture.dispose();
    image.dispose();
    if (data == null) {
      throw StateError('画布栅格化失败');
    }
    return CardBitmap.fromRgba(
      width: profile.canvasW,
      height: profile.canvasH,
      rgba: data.buffer.asUint8List(),
    );
  }

  // ---- 模板：状态卡（focusing/break/available/away 共用布局区域）----

  void _renderStateTemplate(
      ui.Canvas c, LayoutRule layout, CardRenderInput input) {
    final sw = input.stateWord;
    final swR = layout.regions['stateWord'];
    if (sw != null && sw.isNotEmpty && swR != null) {
      _drawText(c, sw, swR,
          minPx: profile.fontRules.stateWordMinPx.toDouble(), bold: true);
    }

    final t = input.timeText;
    final tR = layout.regions['time'];
    if (t != null && t.isNotEmpty && tR != null) {
      _drawText(c, t, tR,
          minPx: profile.fontRules.timeMinPx.toDouble(), bold: true);
    }

    final custom = input.customText;
    final cR = layout.regions['customText'];
    if (custom != null && custom.isNotEmpty && cR != null) {
      _drawText(c, custom, cR,
          minPx: profile.fontRules.cjkMinPx.toDouble());
    }

    // accent 状态点（实心圆）
    final aR = layout.regions['accent'];
    if (aR != null) {
      c.drawCircle(
        ui.Offset(aR.x + aR.w / 2.0, aR.y + aR.h / 2.0),
        aR.w * 0.4,
        ui.Paint()..color = _ink,
      );
    }
  }

  // ---- 模板：名片（card）----

  void _renderCardTemplate(
      ui.Canvas c, LayoutRule layout, CardRenderInput input) {
    final name = input.name;
    final nR = layout.regions['name'];
    if (name != null && name.isNotEmpty && nR != null) {
      _drawText(c, name, nR,
          minPx: profile.fontRules.cjkMinPx.toDouble(), bold: true);
    }

    final title = input.title;
    final tR = layout.regions['title'];
    if (title != null && title.isNotEmpty && tR != null) {
      _drawText(c, title, tR,
          minPx: profile.fontRules.cjkMinPx.toDouble());
    }

    final qR = layout.regions['qr'];
    if (qR != null) {
      final qr = input.qrBitmap;
      if (qr != null) {
        _drawQrBitmap(c, qr, qR);
      } else {
        // 占位框（M4/T7 生成真实 QR 后替换）
        c.drawRect(
          ui.Rect.fromLTWH(
              qR.x.toDouble(), qR.y.toDouble(), qR.w.toDouble(), qR.h.toDouble()),
          ui.Paint()
            ..color = _ink
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        _drawText(c, 'QR', qR, minPx: 20, bold: true, center: true);
      }
    }
  }

  /// QR 位图按区域缩放逐像素绘制（最近邻，保持 1-bit 锐利）
  void _drawQrBitmap(ui.Canvas c, CardBitmap qr, Region r) {
    final sx = r.w / qr.width;
    final sy = r.h / qr.height;
    final paint = ui.Paint()..color = _ink;
    for (var y = 0; y < qr.height; y++) {
      for (var x = 0; x < qr.width; x++) {
        if (qr.pixelAt(x, y)) {
          c.drawRect(
            ui.Rect.fromLTWH(
                r.x + x * sx, r.y + y * sy, sx + 0.5, sy + 0.5),
            paint,
          );
        }
      }
    }
  }

  /// 自适应字号文字绘制：
  /// 从区域高 90% 起逐级收缩到 minPx；到 minPx 仍超宽 → 省略号截断。
  /// 垂直居中；水平左对齐（center=true 时居中）。
  void _drawText(
    ui.Canvas c,
    String text,
    Region r, {
    required double minPx,
    bool bold = false,
    bool center = false,
  }) {
    final maxW = r.w.toDouble();

    TextStyle styleAt(double px) => TextStyle(
          fontFamily: _fontFamily,
          fontSize: px,
          color: _ink,
          fontWeight: bold ? ui.FontWeight.w700 : ui.FontWeight.w400,
          fontVariations: [ui.FontVariation('wght', bold ? 700 : 400)],
          height: 1.0,
        );

    var size = r.h * 0.9;
    if (size < minPx) size = minPx;
    while (size > minPx) {
      final probe = TextPainter(
        text: TextSpan(text: text, style: styleAt(size)),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (probe.width <= maxW) break;
      size -= 1;
    }

    final tp = TextPainter(
      text: TextSpan(text: text, style: styleAt(size)),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxW);

    final dx = center ? r.x + (r.w - tp.width) / 2 : r.x.toDouble();
    final dy = r.y + (r.h - tp.height) / 2;
    tp.paint(c, ui.Offset(dx, dy));
  }
}
