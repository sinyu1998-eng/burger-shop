#!/bin/bash
# ============================================================
# 周六活动海报生成器
# 用法：
#   ./make-posters.sh                 # 以「最近的周六」为首场，自动排 8 周
#   ./make-posters.sh 2026-11-14      # 指定首场日期，自动往后每周一场
# 产物：posters/week1.png ... week8.png（2160×2880，微信朋友圈 3:4 满屏）
# ============================================================

set -e
DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PORT=8765
START="${1:-}"

if [ ! -x "$CHROME" ]; then
  echo "未找到 Chrome，请安装 Google Chrome 后重试"
  exit 1
fi

mkdir -p "$DIR/posters"

# 临时起一个静态服务器（图片需要 http 协议才能加载）
python3 -m http.server "$PORT" --directory "$DIR" >/dev/null 2>&1 &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null' EXIT
sleep 1.5

for i in 1 2 3 4 5 6 7 8; do
  URL="http://127.0.0.1:$PORT/poster-series.html?p=$i"
  [ -n "$START" ] && URL="$URL&start=$START"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=2 --window-size=1080,1440 \
    --virtual-time-budget=3000 \
    --screenshot="$DIR/posters/week$i.png" "$URL" >/dev/null 2>&1
  echo "✔ posters/week$i.png"
done

echo ""
echo "完成，共 8 张，输出目录：$DIR/posters"
[ -z "$START" ] && echo "（日期按「最近的周六」自动计算，如需指定首场：./make-posters.sh 2026-11-14）"
