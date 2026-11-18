#!/bin/bash
# 清理：安装包 + iMovie → 废纸篓（可恢复）
set -u
SRC="$HOME/Downloads"
TRASH="$HOME/.Trash"
LOG="$HOME/Desktop/html_artifact/cleanup.log"
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "[$(date '+%H:%M:%S')] 开始清理"
n=0
for f in "$SRC"/*.dmg; do
  [ -e "$f" ] || continue
  if mv "$f" "$TRASH/" 2>/dev/null; then
    echo "✓ 移入废纸篓: $(basename "$f")"; n=$((n+1))
  else
    echo "✗ 失败: $(basename "$f")"
  fi
done
echo "安装包处理: $n 个"

if [ -d /Applications/iMovie.app ]; then
  if mv /Applications/iMovie.app "$TRASH/" 2>/dev/null; then
    echo "✓ iMovie 已移入废纸篓"
  else
    echo "✗ iMovie 移动失败（需管理员权限）"
  fi
else
  echo "- iMovie 不存在或已移除"
fi

echo "[$(date '+%H:%M:%S')] 清理完成"
df -h /System/Volumes/Data | awk 'NR==2{print "电脑剩余: "$4"  使用率: "$5}'
