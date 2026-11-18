#!/bin/bash
# 自动迁移（无交互）：视频 → U 盘，安装包与 iMovie → 废纸篓
set -u
USB="/Volumes/M&A_Backup"
DEST="$USB/iPhone_2026"
SRC="$HOME/Downloads"
TRASH="$HOME/.Trash"
LOG="$HOME/Desktop/html_artifact/migration.log"

: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "[$(date '+%H:%M:%S')] 开始迁移"

if [ ! -d "$USB" ]; then echo "✗ 未找到 U 盘"; exit 1; fi
mkdir -p "$DEST" || { echo "✗ U盘不可写"; exit 1; }

MANIFEST="$DEST/_backup_manifest.txt"
: > "$MANIFEST"
COUNT=0; SKIP=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  size=$(stat -f%z "$f" 2>/dev/null || echo 0)
  avail=$(df -k "$DEST" | awk 'NR==2{print $4*1024}')
  if [ "$avail" -gt $((size + 209715200)) ]; then
    if cp "$f" "$DEST/" 2>/dev/null; then
      echo "OK $(basename "$f") $(( size/1024/1024 ))MB" >> "$MANIFEST"
      COUNT=$((COUNT+1)); echo "✓ $(basename "$f")"
    else
      echo "FAIL $(basename "$f")" >> "$MANIFEST"
    fi
  else
    echo "SKIP $(basename "$f") $(( size/1024/1024 ))MB" >> "$MANIFEST"
    SKIP=$((SKIP+1))
  fi
done < <(ls -S "$SRC"/*.MOV "$SRC"/*.mov 2>/dev/null)

echo "[$(date '+%H:%M:%S')] 复制完成：成功 $COUNT，跳过 $SKIP"

# 清理（授权项，移入废纸篓）
n=0
for f in "$SRC"/*.dmg; do
  [ -e "$f" ] || continue
  mv "$f" "$TRASH/" 2>/dev/null && n=$((n+1))
done
echo "[$(date '+%H:%M:%S')] 安装包移入废纸篓：$n 个"

if [ -d /Applications/iMovie.app ]; then
  if mv /Applications/iMovie.app "$TRASH/" 2>/dev/null; then
    echo "[$(date '+%H:%M:%S')] iMovie 已移入废纸篓"
  else
    echo "[$(date '+%H:%M:%S')] iMovie 移动失败（需管理员权限）"
  fi
fi

echo "[$(date '+%H:%M:%S')] 全部完成"
df -h "$USB" | awk 'NR==2{print "U盘剩余: "$4}'
df -h /System/Volumes/Data | awk 'NR==2{print "电脑剩余: "$4}'
echo "日志：$LOG"
