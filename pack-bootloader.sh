#!/bin/bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Pack an eMMC bootloader for this board. BL33/ACS are built the usual
# Amlogic way (`./fip/mk sc2_vontarx4 --avb2 --testkey`). ATV14 BL2E still
# does not hand off to GKI after "Starting kernel", so this overlays stock
# BBST+BL2E+BL2X (device ACS in that BBST matches board timing.c). Refuses
# stock BL31 (GKI 5.15 hangs in PSCI).
#

set -euo pipefail

SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
DEVICE_DIR="$(dirname "$SCRIPT")"
TOP="${ANDROID_BUILD_TOP:-$(cd "$DEVICE_DIR/../../.." && pwd)}"
UBOOT_SRC="${TOP}/hardware/amlogic/u-boot"
VENDOR_PATH="${TOP}/vendor/amlogic/vontarx4"
STOCK_SD="${STOCK_FIP:-${DEVICE_DIR}/factory/aml_sdc_burn.UBOOT}"
EARLY_BOOT_SIZE=$((0x64000))

UBOOT_BIN="${UBOOT_SRC}/bl33/v2019/build/u-boot.bin.signed"
if [[ ! -f "${UBOOT_BIN}" ]]; then
	echo "error: no packed U-Boot. Build the board first:" >&2
	echo "  cd ${UBOOT_SRC}" >&2
	echo "  export CROSS_COMPILE=/opt/toolchains/gcc-linaro-7.3.1-2018.05-i686_aarch64-elf/bin/aarch64-elf-" >&2
	echo "  export PATH=\"/opt/toolchains/gcc-linaro-7.3.1-2018.05-i686_aarch64-elf/bin:/opt/toolchains/xpack-riscv-none-embed-gcc-8.3.0-1.2/bin:\${PATH}\"" >&2
	echo "  ./fip/mk sc2_vontarx4 --avb2 --testkey" >&2
	exit 1
fi

# Signed FIP encrypts BL33, so check the unsigned image. Without
# TARGET_SC2_VONTARX4 in board/amlogic/Kconfig, fip/mk silently builds
# sc2_skt env (upgrade_key/fastboot loop) and still names the board vontarx4.
UBOOT_PLAIN="${UBOOT_SRC}/bl33/v2019/build/u-boot.bin"
if [[ ! -f "${UBOOT_PLAIN}" ]]; then
	echo "error: missing unsigned BL33 ${UBOOT_PLAIN}" >&2
	exit 1
fi
if ! grep -aq "skip sticky fastboot" "${UBOOT_PLAIN}" || \
   ! grep -aq "board=vontarx4" "${UBOOT_PLAIN}"; then
	echo "error: BL33 is not sc2_vontarx4 (env still skt?). Rebuild after wiring board/amlogic/Kconfig." >&2
	exit 1
fi

if [[ ! -f "${STOCK_SD}" ]]; then
	echo "error: stock eMMC FIP donor missing: ${STOCK_SD}" >&2
	exit 1
fi

PACKED="$(mktemp)"
trap 'rm -f "${PACKED}"' EXIT

python3 - "${STOCK_SD}" "${UBOOT_BIN}" "${PACKED}" "${EARLY_BOOT_SIZE}" <<'PY'
import pathlib, struct, sys

stock_sd, new_path, out_path, early = sys.argv[1:]
early = int(early)
stock = pathlib.Path(stock_sd).read_bytes()
new = pathlib.Path(new_path).read_bytes()

if stock[32:40] != b"@AMLBOOT":
    raise SystemExit(f"error: {stock_sd} is not an SC2 sd.bin FIP")
stock_sto = stock[512:]
if new[508 * 512 + 32 : 508 * 512 + 40] != b"@AMLBOOT":
    raise SystemExit(f"error: {new_path} is not an SC2 eMMC FIP")
if len(stock_sto) != len(new):
    raise SystemExit(f"error: stock FIP size {len(stock_sto)} != new {len(new)}")
if early >= len(new):
    raise SystemExit("error: early-boot overlay larger than FIP")

out = bytearray(new)
out[:early] = stock_sto[:early]
pathlib.Path(out_path).write_bytes(out)
print(f"spliced stock BBST+BL2E+BL2X ({early} bytes) onto new DEVF -> {out_path}")

def payload(data, entry):
    if data[32:40] == b"@AMLBOOT":
        data = data[512:]
    devf = 0xA4000
    ent = data[devf + 0x20 + entry * 0x28 : devf + 0x20 + (entry + 1) * 0x28]
    off, size = struct.unpack_from("<QQ", ent, 16)
    return data[devf + off : devf + off + size]

if payload(out, 2) == payload(stock, 2):
    raise SystemExit("error: packed FIP BL31 is stock Vontar; GKI 5.15 will hang in PSCI")
print("verified packed FIP BL31 is not stock Vontar")
PY

mkdir -p "${VENDOR_PATH}/radio"
cp -f "${PACKED}" "${VENDOR_PATH}/radio/bootloader.img"
cp -f "${PACKED}" "${DEVICE_DIR}/factory/bootloader.img"

sha1="$(sha1sum "${PACKED}" | awk '{print $1}')"
sed -i \
	-e "s@^bootloader\.img.*@bootloader.img|${sha1}@" \
	"${DEVICE_DIR}/proprietary-firmware.txt"
# setup-makefiles pins the same hash in vendor Android.mk for
# add-radio-file-sha1-checked; keep them in sync without a full regen.
if [[ -f "${VENDOR_PATH}/Android.mk" ]]; then
	sed -i \
		-e "s@add-radio-file-sha1-checked,radio/bootloader\.img,[0-9a-f]*@add-radio-file-sha1-checked,radio/bootloader.img,${sha1}@" \
		"${VENDOR_PATH}/Android.mk"
fi
echo "Installed: ${DEVICE_DIR}/factory/bootloader.img (${sha1})"
echo "Rebuild the upgrade package with: m aml_upgrade"
