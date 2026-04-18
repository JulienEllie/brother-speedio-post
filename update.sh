#!/usr/bin/env bash
set -euo pipefail

# Downloads the latest Brother Speedio post processor from Autodesk CAM
# and archives it under upstream/<rev>_<date>.cps. If a new version was
# pulled, also bootstraps modified/<rev>_<date>.cps by copying the most
# recent modified version so you can begin merging on top.

URL="https://cam.autodesk.com/posts/post.php?name=brother%20speedio"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Downloading latest Brother Speedio post processor..."
html=$(curl -fsSL "$URL")

code=$(echo "$html" | sed -n '/<pre[^>]*>/,/<\/pre>/p' | sed '1s/.*<pre[^>]*>//;$s/<\/pre>.*//')

code=$(echo "$code" \
  | sed 's/&lt;/</g' \
  | sed 's/&gt;/>/g' \
  | sed 's/&amp;/\&/g' \
  | sed 's/&quot;/"/g' \
  | sed "s/&#039;/'/g" \
  | sed 's/&#39;/'"'"'/g' \
  | sed 's/&apos;/'"'"'/g')

tmp=$(mktemp)
printf '%s\n' "$code" | tr -d '\r' > "$tmp"
sed -i '' '1{/^$/d;}' "$tmp"

rev=$(grep -m1 '\$Revision:' "$tmp" | awk '{print $2}')
date=$(grep -m1 '\$Date:' "$tmp" | awk '{print $2}')
if [[ -z "$rev" || -z "$date" ]]; then
  echo "error: could not parse \$Revision / \$Date from download" >&2
  rm -f "$tmp"
  exit 1
fi

label="${rev}_${date}"
upstream_path="$SCRIPT_DIR/upstream/${label}.cps"
modified_path="$SCRIPT_DIR/modified/${label}.cps"

mkdir -p "$SCRIPT_DIR/upstream" "$SCRIPT_DIR/modified"

if [[ -f "$upstream_path" ]]; then
  if cmp -s "$tmp" "$upstream_path"; then
    echo "No change — $upstream_path is already at rev $rev ($date)."
    rm -f "$tmp"
    exit 0
  else
    echo "warning: $upstream_path already exists but content differs. Overwriting." >&2
  fi
fi

mv "$tmp" "$upstream_path"
echo "Saved upstream: $upstream_path"

if [[ ! -f "$modified_path" ]]; then
  prev=$(ls -1 "$SCRIPT_DIR/modified"/*.cps 2>/dev/null | sort | tail -1 || true)
  if [[ -n "$prev" ]]; then
    cp "$prev" "$modified_path"
    echo "Bootstrapped modified: $modified_path (copied from $(basename "$prev"))"
    echo ""
    echo "Next steps:"
    echo "  1. Diff $prev against $upstream_path's predecessor to see what upstream changed."
    echo "  2. Port the upstream changes into $modified_path."
    echo "  3. Run tests/regression.sh to verify."
  else
    echo "No prior modified version found — create $modified_path by hand."
  fi
else
  echo "Modified already exists: $modified_path (not touched)."
fi
