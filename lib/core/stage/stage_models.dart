/// 舞台防区枚举
enum StageZone {
  /// 一楼常规主舞台：受 Padding 约束，与侧边栏并排，带圆角，作为应用主要展示区。
  firstFloorMain,

  /// 二楼沉浸大屏幕：撑满全屏，无边距，覆盖在一楼之上，但在侧边栏之下，用于详情页等。
  secondFloorScreen,

  /// 三楼沉浸覆盖区：Z 轴顶层，全屏无边界，覆盖所有内容(含侧边栏)，用于全屏播放器等。
  thirdFloorOverlay,
}
