/// WYSIWYG 预览组件（UI 规范 §5）：
/// 显示与写入 payload **同一次渲染调用**产出的 CardBitmap；
/// 大图模式整数倍放大、FilterQuality.none（禁平滑）；
/// 纸质感由容器（边框/底色/阴影）模拟，不进位图。
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/hal/card_bitmap.dart';
import 'theme.dart';

class CardPreview extends StatefulWidget {
  final CardBitmap bitmap;

  /// 带纸质容器（屏2 大预览用）
  final bool framed;

  /// 紧凑缩略模式（屏1「现在」小预览）：按高度 contain、最近邻，不强制整数倍
  final bool compact;

  const CardPreview({
    super.key,
    required this.bitmap,
    this.framed = true,
    this.compact = false,
  });

  @override
  State<CardPreview> createState() => _CardPreviewState();
}

class _CardPreviewState extends State<CardPreview> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _convert(widget.bitmap);
  }

  @override
  void didUpdateWidget(covariant CardPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // CardBitmap 无值等价——每次渲染都是新对象，引用变化即重转换
    if (!identical(oldWidget.bitmap, widget.bitmap)) {
      _convert(widget.bitmap);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _convert(CardBitmap bmp) async {
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
    final img = await completer.future;
    if (!mounted) {
      img.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = img;
    });
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    if (img == null) {
      // 转换中的占位（保持布局稳定）
      return SizedBox(
        width: widget.bitmap.width.toDouble(),
        height: widget.bitmap.height.toDouble(),
      );
    }

    if (widget.compact) {
      return SizedBox(
        height: 64,
        child: RawImage(
          image: img,
          filterQuality: FilterQuality.none,
          fit: BoxFit.contain,
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      // 整数倍放大：取宽高约束下的最大整数倍（1~8）
      var scale = 1;
      if (constraints.maxWidth.isFinite) {
        scale = (constraints.maxWidth / img.width).floor().clamp(1, 8);
      }
      if (constraints.maxHeight.isFinite) {
        final byH = (constraints.maxHeight / img.height).floor().clamp(1, 8);
        if (byH < scale) scale = byH;
      }
      final card = SizedBox(
        width: img.width * scale.toDouble(),
        height: img.height * scale.toDouble(),
        child: RawImage(
          image: img,
          filterQuality: FilterQuality.none, // 禁平滑（规范 §5）
          fit: BoxFit.fill,
        ),
      );
      if (!widget.framed) return Center(child: card);
      return Center(
        child: Container(
          padding: const EdgeInsets.all(T.s2),
          decoration: BoxDecoration(
            color: T.paper,
            borderRadius: BorderRadius.circular(T.rCard),
            border: Border.all(color: T.lineStrong), // 卡片对象外框
            boxShadow: [
              BoxShadow(
                color: T.lineStrong.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: card,
        ),
      );
    });
  }
}
