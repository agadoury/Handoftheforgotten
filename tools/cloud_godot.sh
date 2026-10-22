#!/bin/sh
# Sets up Godot in a Claude Code cloud container (Ubuntu 24.04, x86_64), where GitHub release
# downloads are blocked: unpacks Ubuntu 25.10's Godot 4.4.1 package and its libraries into a folder,
# and installs a virtual display and software Vulkan so frames can be rendered without a GPU.
# Not needed on the Mac. Prints the path of a wrapper to use as GODOT.
#   sh tools/cloud_godot.sh [install_dir]      (default: ~/.local/godot)
set -eu
DEST="${1:-$HOME/.local/godot}"
MIRROR="http://archive.ubuntu.com/ubuntu"
RELEASE="questing"
PACKAGES="godot libembree4-4 libenet7 libharfbuzz-icu0 libicu76 libmbedcrypto16 libmbedtls21
libmbedx509-7 libminiupnpc18 librecast1 libwebp7 libwslay1 libtbb12 libsharpyuv0 libtheoradec1
libharfbuzz0b libfreetype6 libbrotli1 libpcre2-32-0 libpng16-16t64"

mkdir -p "$DEST/debs" "$DEST/root"
cd "$DEST"
for component in main universe; do
	curl -fsS "$MIRROR/dists/$RELEASE/$component/binary-amd64/Packages.xz" | xz -dc
done > Packages.txt

for pkg in $PACKAGES; do
	file=$(awk -v p="$pkg" '$1 == "Package:" { found = ($2 == p) } found && $1 == "Filename:" { print $2; exit }' Packages.txt)
	[ -n "$file" ] || { echo "Package $pkg not found in $RELEASE" >&2; exit 1; }
	curl -fsS -o "debs/$(basename "$file")" "$MIRROR/$file"
done
for deb in debs/*.deb; do dpkg-deb -x "$deb" root; done

cat > godot.sh <<EOF
#!/bin/sh
export LD_LIBRARY_PATH="$DEST/root/usr/lib/x86_64-linux-gnu"
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
exec "$DEST/root/usr/bin/godot" "\$@"
EOF
chmod +x godot.sh

if [ "$(id -u)" = 0 ] && ! [ -e /usr/share/vulkan/icd.d/lvp_icd.json ]; then
	apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mesa-vulkan-drivers xvfb > /dev/null
fi

"$DEST/godot.sh" --version
echo "GODOT=$DEST/godot.sh"
echo "Render frames with: xvfb-run -a -s '-screen 0 1280x720x24' \"\$GODOT\" --path . --resolution 1280x720 res://debug/shot.tscn -- --out=/tmp/hotf"
