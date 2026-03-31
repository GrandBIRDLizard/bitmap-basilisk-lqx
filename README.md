# bitmap-basilisk-lqx

`bitmap-basilisk-lqx` is a **Liquorix-based X3D-oriented test kernel** for modern AMD desktop systems.

It is built as a practical development base for:

- **low-latency desktop behavior**
- **mixed-workload responsiveness**
- **BMQ-first scheduler experimentation when available**
- **`sched_ext` / BPF / BTF scheduler experimentation**
- **cleaner interaction with `x3dctl`**
- **real-world X3D tuning rather than generic distro defaults**

This project is currently a **GitHub-first development/test kernel** and is **not yet finalized for AUR**.

---

## What it is

`bitmap-basilisk-lqx` starts from a **Liquorix kernel base** and applies a focused configuration policy for:

- **AMD X3D systems**
- **low-latency desktop use**
- **scheduler experimentation**
- **better policy alignment with `x3dctl`**

---


## Relationship to x3dctl

`x3dctl` is the **user-space policy layer**.  
`bitmap-basilisk-lqx` is the **kernel-side execution layer**.

In simple terms:

- **`x3dctl`** decides what kind of workload is running
- **`bitmap-basilisk-lqx`** provides a kernel base that is easier to steer and reason about

The goal is not to fight generic scheduler behavior with more user-space hacks.

The goal is:

- **clearer policy**
- **cleaner scheduling behavior**
- **more repeatable results**

---

## Current configuration direction

The current config policy enables a practical X3D-focused baseline with:

- **Liquorix base patches**
- **`sched_ext` support when available**
- **BPF / BTF support for future scheduler work**
- **AMD X3D / AMD P-State / CPPC-related support**
- **1000 Hz tick + high-resolution timers**
- **`NO_HZ_IDLE` baseline**
- **`NO_HZ_FULL` / advanced isolation-capable support where available**
- **BMQ / `SCHED_ALT` as a preferred path when the tree supports it**

This is still an active development target and may change as the project matures.

---

### UNIX-style view

- `x3dctl` does **one job**: define and apply workload policy
- `bitmap-basilisk` does **one job**: schedule in a way that respects that policy

Each layer stays simple.  
Each layer stays focused.  
Together, they produce behavior that is stronger than either one alone.

---

## Fun fact about the name:

The name **bitmap-basilisk** is intentional.

### `bitmap`
This references the heart of **BMQ**:

- bitmap-based runnable task tracking
- fast priority lookup
- low-overhead dispatch
- simple, direct scheduler logic

### `basilisk`
A basilisk is a predator: focused, selective, and lethal.

That mirrors what this patch tries to make BMQ do:

- stop treating all runnable work as equal
- identify what matters most
- protect the important workload
- place tasks with purpose instead of passively distributing them

**BMQ provides the fast bitmap eyes.  
bitmap-basilisk gives it the instinct to strike deliberately.**

That is the whole idea:

---

## Design philosophy

`bitmap-basilisk` follows a simple philosophy:

- **Do less, but do it deliberately**
- **Favor predictable behavior over complex heuristics**
- **Preserve low scheduler overhead**
- **Improve real desktop feel, not just synthetic throughput**
- **Make kernel behavior cooperate with user-space policy**
- **Keep scheduler paths swappable and testable**
- **Stay small, understandable, and composable**

This is not a “kitchen sink” scheduler patch.

---
## Build notes

This project currently targets an Arch Linux / makepkg-style workflow.

Typical flow:

1. fetch kernel + Liquorix sources
2. apply Liquorix patches
3. install base config
4. run customize_config.sh
5. resolve with olddefconfig
6. build and package

This repository is currently intended for advanced users testing on their own hardware.

---

## License

This project is licensed under GPL-2.0-only.

### Contact

Please use repository issues for:
- build failures
- config regressions
- scheduler behavior reports
- compatibility notes

For project-related contact:

https://github.com/GrandBIRDLizard
