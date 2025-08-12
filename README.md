# RISCV Benchmarks

Welcome! This repository contains several open-source benchmarks for performance evaluation of RISC-V based machines. The main goal is to provide simple setup scripts that can be directly run on RISC-V without worrying about compilation or dependency issues.

---

## Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/akifejaz/riscv-benchmarks.git
   cd riscv-benchmarks
   ```

## Important Tips

- You may need to edit certain variables in the scripts (marked with `EDIT`) for paths, versions, or credentials.
- Each benchmark may have its own dependencies (e.g., compilers, libraries, or tools) that are not checked by the main script. Please review the relevant benchmark script and install any required packages before running.
- Some benchmarks (like `spec2017` and `phoronix`) require `sudo` permissions.

---

2. **Install global dependencies:**
   - 

3. **Run a benchmark:**
   ```bash
   bash run.sh <benchmark>
   ```
   Replace `<benchmark>` with one of:
   - `coremark`
   - `spec2017`
   - `phoronix`
   - `geekbench`
   - `unixbench`

   Example:
   ```bash
   bash run.sh coremark
   sudo bash run.sh spec2017
   ```

4. **View logs:**
   - All logs are saved in the `logs/` directory with timestamped filenames.

---

## 📦 Benchmarks Included

- **Phoronix Test Suite**
- **SPEC 2017**
- **Geekbench 6**
- **UnixBench**
- **CoreMark**

---

⭐️ **Star this repo:** [Click here to star!](https://github.com/akifejaz/riscv-benchmarks/stargazers)
👤 **Follow the author:** [akifejaz on GitHub](https://github.com/akifejaz)

Stay tuned for updates and new benchmarks!