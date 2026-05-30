/// 📁 音乐页面静态数据模型 (Music Static Data Model Constants)
class MusicModel {
  const MusicModel._();

  // --- Page / Room IDs ---
  static const String musicPageId = 'musicPage';

  // --- Zone IDs (与 building_map.dart 中的 + 前缀一一对应) ---
  static const String folderZoneId = 'music_folder';
  static const String listZoneId = 'music_list';
  static const String lyricsZoneId = 'music_lyrics';
  static const String controlZoneId = 'music_control';

  // --- Focus Node IDs ---
  static const String btnFastRewindId = 'music_fast_rewind';
  static const String btnPrevId = 'music_prev';
  static const String btnPlayId = 'music_play';
  static const String btnNextId = 'music_next';
  static const String btnFastForwardId = 'music_fast_forward';
  static const String btnPlayModeId = 'music_play_mode';
  static const String btnFullscreenId = 'music_fullscreen';
  static const String btnLyricsOffsetMinusId = 'music_lyrics_offset_minus';
  static const String btnLyricsOffsetPlusId = 'music_lyrics_offset_plus';
  static const String btnLyricsOffsetMinusSmallId = 'music_lyrics_offset_minus_small';
  static const String btnLyricsOffsetPlusSmallId = 'music_lyrics_offset_plus_small';
  static const String btnLyricsExportId = 'music_lyrics_export';
  static const String btnRecacheId = 'music_recache';
  static const String retryBtnId = 'music_retry_btn';
}
