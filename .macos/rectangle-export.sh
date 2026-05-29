#!/usr/bin/env bash
set -euo pipefail

# Save the current Rectangle preferences into the repo (system -> repo).
# Run this manually after changing Rectangle settings in the app, then commit
# Rectangle.plist. The reverse (repo -> system) happens in settings.sh.

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

if ! defaults read com.knollsoft.Rectangle &> /dev/null; then
	echo "Rectangle has no preferences on this machine; nothing to export." >&2
	exit 1
fi

defaults export com.knollsoft.Rectangle ./Rectangle.plist
echo "Saved Rectangle preferences -> .macos/Rectangle.plist"
