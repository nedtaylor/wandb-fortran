# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.0] — 2026-03-18

### Added

- Initial standalone release extracted from the
  [ATHENA](https://github.com/nedtaylor/athena) `ext/wandb` extension.
- `wf__wandb` Fortran module providing:
  - `wandb_init` / `wandb_finish` / `wandb_shutdown`
  - `wandb_log` — overloaded for `integer`, `real32`, `real64`
  - `wandb_config_set` / `wandb_config_get` — overloaded for all scalar types
  - `wandb_sweep` — raw JSON and `wandb_sweep_config_type` builder variants
  - `wandb_sweep_start_agent` / `wandb_sweep_next_params` / `wandb_sweep_run_done`
    — non-blocking sweep agent API
- `wf_wandb_c.c` — C bridge that embeds the Python interpreter via the
  Python C API.
- `include/wandb.h` — public C header for downstream consumers.
- fpm build system with `tools/setup_env.sh` for automatic Python flag
  detection.
- Example: `athena_logging` — ATHENA neural network training with wandb.
- Example: `neural_fortran_logging` — neural-fortran training with wandb.
- Smoke test: `test_logging` (sweep config builder + offline wandb round-trip).
- Sphinx documentation (ReadTheDocs-compatible).
- FORD API documentation configuration.
- GitHub Actions CI workflow.
