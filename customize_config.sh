#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2026 GrandBIRDLizard
#
# bitmap-basilisk kernel config policy
# Applied after patching and before final olddefconfig/build.
# Root-level intentionally during pre-AUR development.
set -euo pipefail


set -euo pipefail

cfg() {
  ./scripts/config "$@"
}

try_enable() {
  local sym="$1"
  echo "  [+] Trying to enable $sym"
  cfg --enable "$sym" || echo "  [!] Could not enable $sym"
}

try_disable() {
  local sym="$1"
  echo "  [-] Trying to disable $sym"
  cfg --disable "$sym" || echo "  [!] Could not disable $sym"
}

try_module() {
  local sym="$1"
  echo "  [m] Trying to set module $sym"
  cfg --module "$sym" || echo "  [!] Could not set module $sym"
}

require_set() {
  local sym="$1"
  local want="$2"
  local cfgline="CONFIG_${sym}"

  case "$want" in
    y)
      if grep -q "^${cfgline}=y$" .config; then
        echo "  [ok] ${cfgline}=y"
      else
        echo "  [ERR] Expected ${cfgline}=y"
        exit 1
      fi
      ;;
    m)
      if grep -q "^${cfgline}=m$" .config; then
        echo "  [ok] ${cfgline}=m"
      else
        echo "  [ERR] Expected ${cfgline}=m"
        exit 1
      fi
      ;;
    n)
      if grep -q "^# ${cfgline} is not set$" .config; then
        echo "  [ok] ${cfgline} is not set"
      else
        echo "  [ERR] Expected ${cfgline} to be disabled"
        exit 1
      fi
      ;;
    *)
      echo "  [ERR] Unknown require_set state: $want"
      exit 1
      ;;
  esac
}

warn_if_not() {
  local sym="$1"
  local want="$2"
  local cfgline="CONFIG_${sym}"

  case "$want" in
    y)
      grep -q "^${cfgline}=y$" .config \
        && echo "  [ok] ${cfgline}=y" \
        || echo "  [WARN] ${cfgline} not y (tree/deps may differ)"
      ;;
    m)
      grep -q "^${cfgline}=m$" .config \
        && echo "  [ok] ${cfgline}=m" \
        || echo "  [WARN] ${cfgline} not m (tree/deps may differ)"
      ;;
    n)
      grep -q "^# ${cfgline} is not set$" .config \
        && echo "  [ok] ${cfgline} is not set" \
        || echo "  [WARN] ${cfgline} not disabled (tree/deps may differ)"
      ;;
  esac
}

echo "[*] Applying Bitmap-Basilisk X3D Policy (Liquorix-safe, 6.19+)..."

# ------------------------------------------------------------
# Advanced scheduler / BPF / BMQ infrastructure

try_enable DEBUG_INFO
try_enable DEBUG_INFO_BTF
try_enable BPF
try_enable BPF_SYSCALL
try_enable BPF_JIT
try_enable BPF_EVENTS

# sched-ext if present in this tree
try_enable SCHED_CLASS_EXT

# Alternate scheduler baseline: BMQ only
try_enable SCHED_ALT
try_enable SCHED_BMQ
try_disable SCHED_PDS

# ------------------------------------------------------------
# X3D / AMD topology-friendly settings

try_enable AMD_3D_VCACHE
try_enable X86_AMD_PSTATE
try_enable ACPI_CPPC_LIB
try_enable X86_MSR

# Optional / tree-dependent
try_enable X86_AMD_PSTATE_DEFAULT_MODE_EPP
try_enable SCHED_MC_PRIO

# ------------------------------------------------------------
# Latency / tick / jitter tuning

try_enable HZ_1000
try_disable HZ_300
try_disable HZ_250
try_disable HZ_100

try_enable HIGH_RES_TIMERS
try_enable NO_HZ_IDLE

# Optional advanced isolation-capable path
try_enable NO_HZ_FULL
try_disable NO_HZ_FULL_ALL
try_enable CONTEXT_TRACKING
try_enable VIRT_CPU_ACCOUNTING_GEN
try_enable RCU_NOCB_CPU

# ------------------------------------------------------------
# Hardware / debug / introspection

try_module DRM_AMDGPU
try_enable IKCONFIG
try_enable IKCONFIG_PROC
try_enable SCHED_DEBUG

# Console fonts if present
try_disable FONTS
try_enable FONT_8x8
try_enable FONT_8x16

echo "[*] Resolving dependencies with olddefconfig..."
make olddefconfig


echo "[*] Validating Bitmap-Basilisk baseline..."

# ------------------------------------------------------------
# Preferred scheduler baseline (best-effort for now)

warn_if_not SCHED_CLASS_EXT y
warn_if_not SCHED_ALT y
warn_if_not SCHED_BMQ y
warn_if_not SCHED_PDS n

# ------------------------------------------------------------
# Strongly desired core latency baseline (hard fail)

require_set HZ_1000 y
require_set HIGH_RES_TIMERS y
require_set NO_HZ_IDLE y

# ------------------------------------------------------------
# Best-effort / tree-dependent features (warn only)

warn_if_not DEBUG_INFO y
warn_if_not DEBUG_INFO_BTF y
warn_if_not BPF y
warn_if_not BPF_SYSCALL y
warn_if_not BPF_JIT y
warn_if_not BPF_EVENTS y

warn_if_not AMD_3D_VCACHE y
warn_if_not X86_AMD_PSTATE y
warn_if_not ACPI_CPPC_LIB y
warn_if_not X86_MSR y
warn_if_not X86_AMD_PSTATE_DEFAULT_MODE_EPP y
warn_if_not SCHED_MC_PRIO y

warn_if_not NO_HZ_FULL y
warn_if_not NO_HZ_FULL_ALL n
warn_if_not CONTEXT_TRACKING y
warn_if_not VIRT_CPU_ACCOUNTING_GEN y
warn_if_not RCU_NOCB_CPU y

warn_if_not DRM_AMDGPU m
warn_if_not IKCONFIG y
warn_if_not IKCONFIG_PROC y
warn_if_not SCHED_DEBUG y

warn_if_not FONTS n
warn_if_not FONT_8x8 y
warn_if_not FONT_8x16 y

echo
echo "[*] Bitmap-Basilisk config policy complete."
echo "[*] Final selected config summary:"
grep -E '^(CONFIG_(SCHED_ALT|SCHED_BMQ|SCHED_PDS|SCHED_CLASS_EXT|BPF|BPF_SYSCALL|BPF_JIT|BPF_EVENTS|DEBUG_INFO|DEBUG_INFO_BTF|X86_AMD_PSTATE|ACPI_CPPC_LIB|X86_MSR|IKCONFIG|IKCONFIG_PROC|HZ_1000|NO_HZ_FULL|NO_HZ_IDLE)=|# CONFIG_SCHED_PDS is not set)' .config || true
