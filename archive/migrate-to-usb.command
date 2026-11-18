#!/bin/bash
# ============================================================
# 下载目录视频 → U 盘 迁移 + 清理
# 用法：在 Finder 里双击本文件即可
# 安全说明：只复制，不删除电脑上的原片；删除项一律进废纸篓（可恢复）
# ============================================================

set -u

USB="/Volumes/M&A_Backup"
DEST="$USB/iPhone_2026"
SRC="$HOME/Downloads"
TRASH="$HOME/.Trash"

cd "$(dirname "$0")"

echo "================================================"
echo "  视频迁移与清理"
echo "================================================"
echo ""

# ---------- 1. 检查 U 盘 ----------
if [ ! -d "$USB" ]; then
  echo "✗ 未找到 U 盘：$USB"
  echo "  请插好 U 盘后重新双击本脚本。"
  read -n 1 -s -p "按任意键关闭…"
  exit 1
fi

AVAIL_START=$(df -k "$USB" | awk 'NR==2{print $4/1024/1024}')
echo "✓ U 盘已挂载，可用 ${AVAIL_START} GB"
echo ""

# ---------- 2. 复制视频（只复制，不删除） ----------
mkdir -p "$DEST" 2>/dev/null
if [ ! -d "$DEST" ]; then
  echo "✗ 无法在 U 盘创建目录，请确认 U 盘未锁定。"
  read -n 1 -s -p "按任意键关闭…"
  exit 1
fi

echo "开始复制（按体积从大到小，满盘即停）…"
echo ""

MANIFEST="$DEST/_backup_manifest.txt"
: > "$MANIFEST"
COUNT=0
SKIP=0
TOTAL=$(ls -S "$SRC"/*.MOV "$SRC"/*.mov 2>/dev/null | wc -l | tr -d ' ')
echo "共 $TOTAL 个文件"
echo ""

while IFS= read -r f; do
  [ -z "$f" ] && continue
  size=$(stat -f%z "$f" 2>/dev/null || echo 0)
  avail=$(df -k "$DEST" | awk 'NR==2{print $4*1024}')
  if [ "$avail" -gt $((size + 209715200)) ]; then
    if cp "$f" "$DEST/" 2>/dev/null; then
      echo "✓ $(basename "$f")  ($(( size/1024/1024 )) MB)" >> "$MANIFEST"
      COUNT=$((COUNT+1))
    else
      echo "✗ 复制失败 $(basename "$f")" >> "$MANIFEST"
    fi
  else
    echo "- 空间不足未复制 $(basename "$f")  ($(( size/1024/1024 )) MB)" >> "$MANIFEST"
    SKIP=$((SKIP+1))
  fi
done < <(ls -S "$SRC"/*.MOV "$SRC"/*.mov 2>/dev/null)

echo "----------------------------------------------"
echo "复制完成：成功 $COUNT 个，因空间不足跳过 $SKIP 个"
echo "清单已写入：$DEST/_backup_manifest.txt"
echo ""

# ---------- 3. 清理（进废纸篓，可恢复） ----------
echo "----------------------------------------------"
echo "可清理项目："
du -sh "$SRC"/*.dmg 2>/dev/null | sed 's/^/  /'
[ -d /Applications/iMovie.app ] && echo "  iMovie.app（3.6G）"
echo ""
read -p "把以上项目移到废纸篓？删错了可随时恢复。(y/N) " ans
if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
  n=0
  for f in "$SRC"/*.dmg; do
    [ -e "$f" ] || continue
    mv "$f" "$TRASH/" 2>/dev/null && n=$((n+1))
  done
  [ "$n" -gt 0 ] && echo "✓ $n 个安装包已移入废纸篓"
  if [ -d /Applications/iMovie.app ]; then
    mv /Applications/iMovie.app "$TRASH/" 2>/dev/null \
      && echo "✓ iMovie 已移入废纸篓" \
      || echo "✗ iMovie 移动失败，需要管理员密码，可在 Finder 里手动拖入废纸篓"
  fi
  echo ""
  echo "提示：废纸篓确认无误后再清空，可真正释放空间。"
else
  echo "已跳过清理。"
fi

echo ""
df -h "$USB" | awk 'NR==2{print "U 盘剩余: "$4}'
df -h /System/Volumes/Data | awk 'NR==2{print "电脑剩余: "$4}'
echo ""
read -n 1 -s -p "全部完成，按任意键关闭…"
