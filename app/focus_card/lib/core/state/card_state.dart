/// S1 · 五态定义 + S5 · 状态→模板解析。
///
/// 定位 B：五态平权，专注为主打（isFocus 标记统计英雄位）。
/// 新增第六态 = 添加枚举项 + profile 布局规则，核心逻辑零改动（全景 S1 验收）。
library;

import '../hal/card_bitmap.dart';
import '../hal/card_renderer.dart';
import '../hal/device_profile.dart';

enum CardState {
  focusing(
      templateId: 'focusing',
      stateWord: 'FOCUSING',
      labelZh: '专注中',
      buttonLabelZh: '专注',
      isFocus: true),
  onBreak(
      templateId: 'break',
      stateWord: 'BREAK',
      labelZh: '休息中',
      buttonLabelZh: '休息'),
  available(
      templateId: 'available',
      stateWord: 'AVAILABLE',
      labelZh: '可打扰',
      buttonLabelZh: '可打扰'),
  away(templateId: 'away', stateWord: 'AWAY', labelZh: '离开', buttonLabelZh: '离开'),
  namecard(
      templateId: 'card', stateWord: null, labelZh: '名片', buttonLabelZh: '名片');

  const CardState({
    required this.templateId,
    required this.stateWord,
    required this.labelZh,
    required this.buttonLabelZh,
    this.isFocus = false,
  });

  /// profile 布局模板 id（对应 DeviceProfile.layoutRules 的键）
  final String templateId;

  /// 画布英文大字（名片模板为 null——用 name/title 渲染）
  final String? stateWord;

  /// UI 中文名（描述态：「现在」卡/记录列表用，如"专注中"）
  final String labelZh;

  /// 按钮短标签（动作态：屏1 网格用，如"专注"——对齐线框图）
  final String buttonLabelZh;

  /// 统计英雄位标记（R3：专注时长视觉最大）
  final bool isFocus;

  /// S5：从 profile 解析布局规则。
  /// 模板缺失抛 StateError——M5 换硬件 profile 后由 golden/单测第一时间抓住。
  LayoutRule resolveLayout(DeviceProfile profile) {
    final rule = profile.layoutFor(templateId);
    if (rule == null) {
      throw StateError(
          'DeviceProfile(${profile.profileId}) 缺少模板: $templateId');
    }
    return rule;
  }

  /// 时间快照文本（本地 HH:mm）——卡片=快照，禁止实时走动
  String timeSnapshot(DateTime since) {
    final h = since.hour.toString().padLeft(2, '0');
    final m = since.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// S5→H2 桥接：组装渲染输入。
  /// 名片档案字段（name/title/qr）由上层（P 域，T7）传入，可空。
  CardRenderInput buildRenderInput({
    DateTime? since,
    String? customText,
    String? name,
    String? title,
    CardBitmap? qrBitmap,
  }) {
    if (this == CardState.namecard) {
      return CardRenderInput(
        templateId: templateId,
        name: name,
        title: title,
        qrBitmap: qrBitmap,
      );
    }
    return CardRenderInput(
      templateId: templateId,
      stateWord: stateWord,
      timeText: since == null ? null : timeSnapshot(since),
      customText: customText,
    );
  }
}
