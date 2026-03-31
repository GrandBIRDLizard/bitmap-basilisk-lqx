# Maintainer: GrandBirdLizard (Bitmap-Basilisk Edition)
# Liquorix-based X3D test kernel with advanced scheduler infrastructure enabled

### BUILD OPTIONS
_makenconfig=
_makemenuconfig=
_makexconfig=
_makegconfig=
_localmodcfg=
_use_current=

### Scheduler policy selector
# Keep Liquorix as the known-good tuned baseline.
# "none" means: do NOT try to apply extra legacy ALT/BMQ patch stacks on top.
# Native Liquorix + bitmap-basilisk config policy will enable SCHED_ALT/BMQ if available.
_projectc='none'

_htmldocs_enable=

_major=6.19
_srcname=linux-${_major}
_lqxpatchname=liquorix-package
_lqxpatchrel=5
_lqxpatchver=${_lqxpatchname}-${_major}-${_lqxpatchrel}

# --- Bitmap-Basilisk ---
pkgbase=bitmap-basilisk-lqx
pkgver=6.19.10.lqx1
pkgrel=1
pkgdesc='Bitmap-Basilisk Liquorix X3D tuned test kernel'
url='https://github.com/GrandBIRDLizard/bitmap-basilisk-lqx'
arch=(x86_64)
license=(GPL-2.0-only)

# advanced toolchain support for BTF/BPF + future sched-ext compatibility
makedepends=(
  bc cpio gettext git libelf pahole perl python
  rust rust-src rust-bindgen
  tar xz zstd
  llvm clang
)

options=(!debug !strip)

# NOTE:
# We intentionally omit the kernel .sign file for local custom builds to avoid makepkg PGP pain.
# This kernel is still in development / a test kernel.
source=(
  "https://cdn.kernel.org/pub/linux/kernel/v6.x/${_srcname}.tar.xz"
  "https://github.com/damentz/${_lqxpatchname}/archive/${_major}-${_lqxpatchrel}.tar.gz"
  "config.x86_64"
  "customize_config.sh"
)

pkgname=("$pkgbase" "$pkgbase-headers" "$pkgbase-docs")

sha512sums=(
  '01b29c7f4e5bc0c9802794c2cd027fece825f90417be229a71e60eefce530010d5d301749c54ae744e9d4a483518e769e2bb7e6e9209687681ad7fff11c3ed86'
  'b922779bcb011692fb27fda8412d7290459ec3ce9471768e05a2a88a54d13ec6d85b2fd7a7d43a364b503ec64f88ef7a3d18e0b65f218ae67102ab0c966883d7'
  'SKIP'
  'SKIP'
)

prepare() {
  cd "${srcdir}/${_srcname}"

  echo "[*] Applying Liquorix patches..."
  local _patchfolder="${srcdir}/${_lqxpatchver}/linux-liquorix/debian/patches"

  if [[ ! -d "$_patchfolder" ]]; then
    echo "ERROR: Liquorix patch folder not found: $_patchfolder"
    echo "Check extracted source layout under: ${srcdir}/${_lqxpatchver}"
    exit 1
  fi

  if [[ ! -f "$_patchfolder/series" ]]; then
    echo "ERROR: Liquorix patch series file not found: $_patchfolder/series"
    exit 1
  fi

  grep -P '^(zen|lqx)/' "$_patchfolder/series" | while IFS= read -r line; do
    echo "[*] Applying patch: $line"
    patch -Np1 -N -i "$_patchfolder/$line" || echo "    [!] Skipping redundant/already-applied patch: $line"
  done

  echo "[*] Setting local version..."
  echo "-$pkgrel" > localversion.10-pkgrel
  echo "${pkgbase#linux}" > localversion.20-pkgname

  echo "[*] Installing base config..."
  cp "${srcdir}/config.x86_64" .config

  echo "[*] First pass: normalize base config..."
  yes "" | make olddefconfig

  echo "[*] Applying bitmap-basilisk config policy..."
  chmod +x "${srcdir}/customize_config.sh"
  bash "${srcdir}/customize_config.sh"

  echo "[*] Hard-enabling BTF/BPF support (safe best-effort)..."
  scripts/config -e BPF || true
  scripts/config -e BPF_SYSCALL || true
  scripts/config -e BPF_JIT || true
  scripts/config -e BPF_EVENTS || true
  scripts/config -e DEBUG_INFO || true
  scripts/config -e DEBUG_INFO_BTF || true
  scripts/config -d DEBUG_INFO_BTF_SELFTEST || true

  echo "[*] Second pass: resolve post-policy dependencies..."
  yes "" | make olddefconfig

  echo "[*] Final kernel release string..."
  make -s kernelrelease > version

  echo "[*] Final selected config summary:"
  grep -E '^(CONFIG_(SCHED_ALT|SCHED_BMQ|SCHED_CLASS_EXT|BPF|BPF_SYSCALL|BPF_JIT|BPF_EVENTS|DEBUG_INFO|DEBUG_INFO_BTF|X86_AMD_PSTATE|ACPI_CPPC_LIB|X86_MSR|IKCONFIG|IKCONFIG_PROC|HZ_1000|NO_HZ_FULL|NO_HZ_IDLE)=|# CONFIG_SCHED_PDS is not set)' .config || true
}

build() {
  cd "${srcdir}/${_srcname}"

  echo "[*] Building kernel..."
  make all

  echo "[*] Generating vmlinux.h for future sched-ext work (non-fatal)..."
  make -C tools/bpf/bpftool V=1 vmlinux.h || echo "[!] vmlinux.h generation skipped"
}

_package() {
  pkgdesc="The $pkgdesc kernel and modules"
  depends=('coreutils' 'kmod')
  optdepends=('linux-firmware: firmware images needed for some devices')
  provides=("linux=${pkgver}" "VIRTUALBOX-GUEST-MODULES" "WIREGUARD-MODULE")
  replaces=('virtualbox-guest-modules-arch' 'wireguard-arch')

  cd "${srcdir}/${_srcname}"
  local kernver
  kernver="$(<version)"
  local modulesdir="$pkgdir/usr/lib/modules/$kernver"

  echo "[*] Installing boot image..."
  install -Dm644 "$(make -s image_name)" "$pkgdir/boot/vmlinuz-$pkgbase"

  echo "[*] Installing modules..."
  make INSTALL_MOD_PATH="$pkgdir/usr" INSTALL_MOD_STRIP=1 modules_install

  echo "[*] Removing build and source links..."
  rm -f "$modulesdir"/build
  rm -f "$modulesdir"/source
}

_package-headers() {
  pkgdesc="Headers and scripts for building modules for the $pkgdesc kernel"
  depends=('pahole')

  cd "${srcdir}/${_srcname}"
  local builddir="$pkgdir/usr/lib/modules/$(<version)/build"

  echo "[*] Installing headers..."
  install -Dt "$builddir" -m644 .config Makefile Module.symvers System.map vmlinux version localversion*
  install -Dt "$builddir/kernel" -m644 kernel/Makefile
  install -Dt "$builddir/arch/x86" -m644 arch/x86/Makefile
  install -Dt "$builddir/arch/x86/kernel" -m644 arch/x86/kernel/asm-offsets.s

  cp -a scripts "$builddir/"

  echo "[*] Installing symlinks..."
  mkdir -p "$pkgdir/usr/src"
  ln -sr "$builddir" "$pkgdir/usr/src/$pkgbase"
}

_package-docs() {
  pkgdesc="Documentation for the $pkgdesc kernel"
  cd "${srcdir}/${_srcname}"
  local builddir="$pkgdir/usr/lib/modules/$(<version)/build"

  echo "[*] Installing documentation..."
  mkdir -p "$builddir"
  cp -r Documentation "$builddir/"
}

package_bitmap-basilisk-lqx() {
  _package
}

package_bitmap-basilisk-lqx-headers() {
  _package-headers
}

package_bitmap-basilisk-lqx-docs() {
  _package-docs
}
