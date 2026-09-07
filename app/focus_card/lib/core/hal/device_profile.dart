/// H1 · DeviceProfile —— 硬件差异的唯一收敛点（硬件无感原则的支点）。
///
/// L3 核心域只认识本模型，不认识"296×128"或"8KB"这类具体数字；
/// Gen2 硬件 = 注册一个新 profile，核心域零改动（M5 校准 gate 实证此原则）。
///
/// 当前 Gen1 为开发占位（2.9" 296×128 1-bit + ST25DV64K 8KB），
/// 真实硬件输入到位后仅替换 [DeviceProfile.gen1Placeholder] 的参数。
library;

/// 画布上的矩形区域（布局单位）。
/// 区域命名约定——文字模板：stateWord / time / customText / accent；名片：name / title / qr。
class Region {
  final int x, y, w, h;
  const Region(this.x, this.y, this.w, this.h);

  /// other 是否完全落在本区域内（用于布局越界检查）
  bool contains(Region other) =>
      other.x >= x &&
      other.y >= y &&
      other.x + other.w <= x + w &&
      other.y + other.h <= y + h;

  @override
  bool operator ==(Object other) =>
      other is Region && other.x == x && other.y == y && other.w == w && other.h == h;

  @override
  int get hashCode => Object.hash(x, y, w, h);

  @override
  String toString() => 'Region($x,$y ${w}x$h)';
}

/// 单个卡片模板的布局规则：区域名 → Region。
/// 渲染器（H2）按此参数化定位，模板不硬编码像素——换 profile 即换布局。
class LayoutRule {
  final String templateId;
  final Map<String, Region> regions;
  const LayoutRule(this.templateId, this.regions);
}

/// 字体下限规则（H5 渲染约束，随 profile 变化）
class FontRules {
  /// 状态词（英文大字，如 FOCUSING）
  final int stateWordMinPx;

  /// 时间（如 14:32）
  final int timeMinPx;

  /// 中文留言下限
  final int cjkMinPx;

  const FontRules({
    required this.stateWordMinPx,
    required this.timeMinPx,
    required this.cjkMinPx,
  });
}

class DeviceProfile {
  final String profileId;
  final int generation;
  final int canvasW;
  final int canvasH;

  /// 色深：1 = 1-bit 黑白
  final int colorDepth;

  /// 标签用户内存（字节）
  final int memoryLimitBytes;

  /// NDEF 封装开销（保守估计）
  final int ndefOverheadBytes;

  /// 本协议版本（协议 v0 = 0；代际协商用）
  final int protocolVersion;

  /// 支持的压缩方法：0=none，1=RLE
  final List<int> compressions;

  final FontRules fontRules;

  /// templateId → 布局规则（五模板：focusing/break/available/away/card）
  final Map<String, LayoutRule> layoutRules;

  const DeviceProfile({
    required this.profileId,
    required this.generation,
    required this.canvasW,
    required this.canvasH,
    required this.colorDepth,
    required this.memoryLimitBytes,
    required this.ndefOverheadBytes,
    required this.protocolVersion,
    required this.compressions,
    required this.fontRules,
    required this.layoutRules,
  });

  /// 画布原始位图字节数（1-bit：W×H/8；占位画布 = 4736B）
  int get canvasBytes => canvasW * canvasH * colorDepth ~/ 8;

  /// 协议帧实际可用字节 = 标签内存 − NDEF 开销
  int get payloadBudget => memoryLimitBytes - ndefOverheadBytes;

  /// W5 容量预检的判定依据
  bool fitsPayload(int encodedFrameBytes) => encodedFrameBytes <= payloadBudget;

  LayoutRule? layoutFor(String templateId) => layoutRules[templateId];

  /// Gen1 开发占位 profile。
  /// ⚠️ 硬件规格未最终确定（见《产品方案_V1.1》）——本实例的参数都是占位值，
  /// M5 校准 gate 时以真实硬件输入替换，其余代码不动。
  static final DeviceProfile gen1Placeholder = DeviceProfile(
    profileId: 'gen1-dev-296x128',
    generation: 1,
    canvasW: 296,
    canvasH: 128,
    colorDepth: 1,
    memoryLimitBytes: 8192,
    ndefOverheadBytes: 64,
    protocolVersion: 0,
    compressions: const [0, 1],
    fontRules: const FontRules(stateWordMinPx: 40, timeMinPx: 28, cjkMinPx: 24),
    layoutRules: const {
      'focusing': LayoutRule('focusing', {
        'stateWord': Region(16, 20, 264, 52),
        'time': Region(16, 76, 130, 36),
        'customText': Region(150, 76, 130, 36),
        'accent': Region(264, 8, 24, 24),
      }),
      'break': LayoutRule('break', {
        'stateWord': Region(16, 20, 264, 52),
        'time': Region(16, 76, 130, 36),
        'customText': Region(150, 76, 130, 36),
        'accent': Region(264, 8, 24, 24),
      }),
      'available': LayoutRule('available', {
        'stateWord': Region(16, 20, 264, 52),
        'time': Region(16, 76, 130, 36),
        'customText': Region(150, 76, 130, 36),
        'accent': Region(264, 8, 24, 24),
      }),
      'away': LayoutRule('away', {
        'stateWord': Region(16, 20, 264, 52),
        'time': Region(16, 76, 130, 36),
        'customText': Region(150, 76, 130, 36),
        'accent': Region(264, 8, 24, 24),
      }),
      'card': LayoutRule('card', {
        'name': Region(16, 24, 176, 36),
        'title': Region(16, 64, 176, 28),
        'qr': Region(204, 20, 84, 84),
      }),
    },
  );
}
