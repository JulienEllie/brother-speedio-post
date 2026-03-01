#!/usr/bin/env bash
set -euo pipefail

# Downloads the latest Brother Speedio post processor from Autodesk CAM
# and extracts the JavaScript source into brother_speedio.cps.

URL="https://cam.autodesk.com/posts/post.php?name=brother%20speedio"
OUTPUT="brother_speedio.cps"

echo "Downloading latest Brother Speedio post processor..."
html=$(curl -fsSL "$URL")

# Extract content between <pre> tags
code=$(echo "$html" | sed -n '/<pre[^>]*>/,/<\/pre>/p' | sed '1s/.*<pre[^>]*>//;$s/<\/pre>.*//')

# Unescape HTML entities
code=$(echo "$code" \
  | sed 's/&lt;/</g' \
  | sed 's/&gt;/>/g' \
  | sed 's/&amp;/\&/g' \
  | sed 's/&quot;/"/g' \
  | sed "s/&#039;/'/g" \
  | sed 's/&#39;/'"'"'/g' \
  | sed 's/&apos;/'"'"'/g')

printf '%s\n' "$code" | tr -d '\r' > "$OUTPUT"
# Remove leading blank line if present
sed -i '' '1{/^$/d;}' "$OUTPUT"
echo "Saved to $OUTPUT"
echo ""

# Show revision info
grep -m1 '\$Revision:' "$OUTPUT" || true
grep -m1 '\$Date:' "$OUTPUT" || true

echo ""
echo "Review CUSTOMIZATIONS.md and re-apply changes to the new version."
