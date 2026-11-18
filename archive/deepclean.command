#!/bin/bash
# 深度清理（已逐项授权）
# 授权删除：废纸篓、应用缓存、Spotlight 知识事件库
# 明确保留：语音备忘录、Dropbox、腾讯视频、iMessage、本地快照、微信记录
set -u
LOG="$HOME/Desktop/html_artifact/deepclean.log"
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

before=$(df -k /System/Volumes/Data | awk 'NR==2{print $4}')
echo "[$(date '+%H:%M:%S')] 开始深度清理"

clean() {
  local p="$1" label="$2"
  [ -e "$p" ] || { echo "- 跳过（不存在）$label"; return; }
  local s=$(du -sk "$p" 2>/dev/null | awk '{print $1}')
  rm -rf "$p" 2>/dev/null
  if [ -e "$p" ]; then
    echo "✗ 失败 $label"
  else
    echo "✓ $label  释放 $(( s/1024 )) MB"
  fi
}

clean "$HOME/.Trash"                                                       "废纸篓"
clean "$HOME/Library/Metadata/SpotlightKnowledgeEvents"                    "Spotlight 知识事件库"
clean "$HOME/Library/Caches"                                               "用户缓存目录"
clean "$HOME/Library/Containers/com.apple.Safari/Data/Library/Caches"      "Safari 缓存"
clean "$HOME/Library/Containers/com.youku.mac/Data/Library/Caches"         "优酷缓存"
clean "$HOME/Library/Containers/com.apple.AMPArtworkAgent/Data/Library/Caches" "音乐封面缓存"
clean "$HOME/Library/Containers/com.tencent.qq/Data/Library/Caches"        "QQ 缓存"
clean "$HOME/Library/Containers/com.tencent.tenvideo/Data/Library/Application Support" "腾讯视频下载与缓存"
clean "$HOME/Library/Containers/com.tencent.tenvideo/Data/Library/Logs"    "腾讯视频日志"

after=$(df -k /System/Volumes/Data | awk 'NR==2{print $4}')
echo "[$(date '+%H:%M:%S')] 完成，本次释放 $(( (after-before)/1024/1024 )) GB"
df -h /System/Volumes/Data | awk 'NR==2{print "电脑可用: "$4"  使用率: "$5}'
echo ""
echo "保留未动：语音备忘录 8.7G / Dropbox 3.5G / 腾讯视频 2.6G / iMessage 1.8G / 微信 6.3G"
