#!/usr/bin/env bash
# Rebuild Windows installation media without mounting it or needing root.
set -euo pipefail
umask 077

fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
if (( $# < 2 || $# > 3 )); then
    printf 'Usage: %s INPUT.iso OUTPUT.iso [autounattend.xml]\n' "$0" >&2
    exit 2
fi
for tool in xorriso python3 realpath sha256sum cmp; do
    command -v "$tool" >/dev/null || fail "Missing $tool. Install xorriso, 7zip, python3 and coreutils."
done
if command -v 7zz >/dev/null; then sevenzip=7zz
elif command -v 7z >/dev/null; then sevenzip=7z
else fail "Missing 7-Zip. Install the 7zip package."
fi
input=$(realpath -e -- "$1")
output=$(realpath -m -- "$2")
answer=$(realpath -e -- "${3:-$(dirname -- "${BASH_SOURCE[0]}")/autounattend.xml}")
[[ -f "$input" && -r "$input" ]] || fail "Input ISO is not a readable file."
[[ -f "$answer" && -r "$answer" ]] || fail "Answer file is not readable."
[[ "$input" != "$output" ]] || fail "Input and output must differ."
[[ ! -e "$output" && ! -L "$output" ]] || fail "Output already exists: $output"
[[ ! -e "$output.sha256" && ! -L "$output.sha256" ]] || fail "Checksum already exists: $output.sha256"
[[ -d "$(dirname -- "$output")" ]] || fail "Output directory does not exist."
python3 - "$input" "$(dirname -- "$output")" <<'PY'
import os, shutil, sys
needed = os.path.getsize(sys.argv[1]) * 2 + 256 * 1024**2
if shutil.disk_usage(sys.argv[2]).free < needed:
    raise SystemExit('Need free space for the extracted ISO and the new ISO (about twice the input size).')
PY
python3 - "$answer" <<'PY'
import sys
import xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
if root.tag != '{urn:schemas-microsoft-com:unattend}unattend':
    raise SystemExit('Not a Windows unattended answer file')
PY

work=$(mktemp -d -- "${output}.build.XXXXXX")
trap 'rm -rf -- "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# The answer file selects Slovenian; the ISO must supply the language files.
"$sevenzip" e -so "$input" sources/lang.ini >"$work/lang.ini"
python3 - "$work/lang.ini" <<'PY'
import configparser, sys
languages = configparser.ConfigParser()
languages.read(sys.argv[1], encoding='utf-8-sig')
if not languages.has_option('Available UI Languages', 'sl-si'):
    raise SystemExit('Use the Slovenian Windows 11 x64 ISO: this source lacks sl-SI language files.')
PY

# Credentials belong only in this local output, never in the public template.
if [[ -t 0 ]]; then
    read -r -p 'Administrator username [rr]: ' username
    username=${username:-rr}
    read -r -s -p "Password for $username: " admin_password
    printf '\n'
else
    username=${CYBERWIN_ADMIN_USER:-rr}
    IFS= read -r admin_password || [[ -n "$admin_password" ]]
fi
printf '%s' "$admin_password" | python3 "$(dirname -- "${BASH_SOURCE[0]}")/scripts/configure-answer.py" \
    "$answer" "$work/autounattend.xml" "$username"
unset admin_password
answer="$work/autounattend.xml"

# Require both boot platforms rather than silently producing BIOS-only media.
xorriso -abort_on FAILURE -indev "$input" -report_el_torito plain >"$work/input-boot.txt" 2>&1
check_boot() {
    python3 - "$1" <<'PY'
import re, sys
report = open(sys.argv[1]).read()
platforms = re.findall(r'El Torito boot img\s*:\s*\d+\s+(BIOS|UEFI)\s+y\s+', report)
if not {'BIOS', 'UEFI'} <= set(platforms):
    raise SystemExit('The ISO must have bootable BIOS and UEFI El Torito entries')
PY
}
check_boot "$work/input-boot.txt"
# Microsoft media can be UDF-only apart from an ISO9660 compatibility README.
# 7z reads UDF; xorriso alone cannot import those installation files.
printf 'Extracting Windows installation media...\n'
"$sevenzip" x -y "-o$work/files" "$input" >"$work/extraction.log"
for required in boot/etfsboot.com efi/microsoft/boot/efisys.bin efi/boot/bootx64.efi sources/boot.wim; do
    [[ -f "$work/files/$required" ]] || fail "Source lacks $required; use official Windows x64 installation media."
done
[[ -f "$work/files/sources/install.wim" || -f "$work/files/sources/install.esd" ]] || fail "Source lacks the Windows installation image."
cp -- "$answer" "$work/files/autounattend.xml"
# ISO level 3 supports WIM files larger than 4 GiB; include both boot platforms.
printf 'Building BIOS and UEFI installation media...\n'
xorriso -abort_on FAILURE -as mkisofs -iso-level 3 -J -joliet-long -V CYBERWIN \
    -b boot/etfsboot.com -no-emul-boot -boot-load-size 8 \
    -eltorito-alt-boot -e efi/microsoft/boot/efisys.bin -no-emul-boot \
    -o "$work/image.iso" "$work/files"
xorriso -abort_on FAILURE -indev "$work/image.iso" -report_el_torito plain >"$work/output-boot.txt" 2>&1
check_boot "$work/output-boot.txt"
xorriso -abort_on FAILURE -osirrox on -indev "$work/image.iso" \
    -extract /autounattend.xml "$work/readback.xml"
cmp -- "$answer" "$work/readback.xml" || fail "Answer file readback differs."

# A hard link publishes the completed file without overwriting a racing writer.
ln -- "$work/image.iso" "$output"
(cd -- "$(dirname -- "$output")" && sha256sum -- "$(basename -- "$output")") >"$work/checksum"
ln -- "$work/checksum" "$output.sha256"
printf '\nCreated: %s\nChecksum: %s.sha256\nBIOS/UEFI entries and answer file readback verified.\n' "$output" "$output"
printf 'The ISO contains the local administrator password. Keep it private.\n'
