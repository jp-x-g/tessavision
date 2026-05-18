#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

CRON_BLOCK_START="# mox display cron start"
CRON_BLOCK_END="# mox display cron end"

NEW_BLOCK="$(cat <<EOF
$CRON_BLOCK_START
*/5 * * * * cd "$BASE_DIR" && ./events.sh >> temp/events.cron.log 2>&1
0 */1 * * * cd "$BASE_DIR" && ./ticker.sh >> temp/ticker.cron.log 2>&1
0 */2 * * * cd "$BASE_DIR" && ./update.sh >> temp/update.cron.log 2>&1
$CRON_BLOCK_END
EOF
)"

# Keep existing crontab, but remove old copy of this managed block.
EXISTING="$(crontab -l 2>/dev/null || true)"

CLEANED="$(printf '%s\n' "$EXISTING" | awk "
  /$CRON_BLOCK_START/ {skip=1; next}
  /$CRON_BLOCK_END/ {skip=0; next}
  !skip {print}
")"

{
  printf '%s\n' "$CLEANED"
  printf '%s\n' "$NEW_BLOCK"
} | crontab -

echo "Installed display cron jobs:"
crontab -l | sed -n "/$CRON_BLOCK_START/,/$CRON_BLOCK_END/p"