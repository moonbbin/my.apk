/**
 * 健壮的音乐 ID 提取器
 * 兼容所有常见字段名：hash / songmid / songId / id / mid / musicId / song_id
 * 
 * 用法：在你的脚本里替换原来的取值逻辑
 *   // 原来：
 *   const id = musicInfo.hash ?? musicInfo.songmid ?? musicInfo.id;
 *   // 改成：
 *   const id = extractMusicId(musicInfo);
 */

// 1. 调试日志：打印 musicInfo 的完整结构
function logMusicInfo(musicInfo, tag) {
  try {
    tag = tag || 'MusicInfo';
    console.log('[' + tag + '] 完整数据: ' + JSON.stringify(musicInfo).substring(0, 1500));
    console.log('[' + tag + '] 所有键: ' + Object.keys(musicInfo || {}).join(', '));
  } catch (e) {
    console.log('[' + tag + '] 日志失败: ' + e.message);
  }
}

// 2. 健壮提取：按优先级尝试所有可能的字段名
function extractMusicId(musicInfo) {
  if (!musicInfo || typeof musicInfo !== 'object') {
    console.log('[extractMusicId] musicInfo 无效: ' + typeof musicInfo);
    return null;
  }
  
  // 优先级从高到低：各平台专用 ID > 通用 ID
  var candidates = [
    musicInfo.hash,        // 酷狗
    musicInfo.songmid,     // 腾讯 songmid
    musicInfo.strMediaMid, // 腾讯 strMediaMid
    musicInfo.songId,      // 通用 songId
    musicInfo.id,          // 通用 id
    musicInfo.mid,         // 通用 mid
    musicInfo.musicId,     // 备用
    musicInfo.song_id,     // 下划线风格
    musicInfo.audioId,     // 音频 ID
    musicInfo.copyrightId  // 咪咕
  ];
  
  for (var i = 0; i < candidates.length; i++) {
    var v = candidates[i];
    // 排除 null/undefined/空字符串（注意：?? 不认空字符串，这里手动过滤）
    if (v !== null && v !== undefined && String(v).trim() !== '') {
      console.log('[extractMusicId] 命中字段 #' + i + ': ' + String(v).substring(0, 50));
      return String(v).trim();
    }
  }
  
  console.log('[extractMusicId] 所有字段都为空！musicInfo=' + JSON.stringify(musicInfo).substring(0, 300));
  return null;
}

// 3. 一站式：打日志 + 提取 + 抛错（直接替换你脚本里的三行）
//   原来：
//     const id = musicInfo.hash ?? musicInfo.songmid ?? musicInfo.id;
//     if (!id) throw new Error('缺少 songId');
//   改成：
//     const id = requireMusicId(musicInfo);
function requireMusicId(musicInfo) {
  logMusicInfo(musicInfo, 'requireMusicId');
  var id = extractMusicId(musicInfo);
  if (!id) {
    throw new Error('缺少 songId（已尝试 hash/songmid/songId/id/mid 等 10 个字段，全空）');
  }
  return id;
}
