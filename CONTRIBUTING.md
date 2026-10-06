# Contributing to proper-wse

proper-wse is a fork of [wse-server](https://github.com/silvermpx/wse), kept for the
[Proper](https://github.com/jpsca/proper) web framework. This repository has the server
only: the Rust core and its Python bindings.

## Development setup

You need Python 3.12+ (free-threaded builds included), a stable Rust toolchain with
`rustfmt` and `clippy`, and [maturin](https://www.maturin.rs/).

```bash
git clone https://github.com/jpsca/proper-wse.git
cd proper-wse
python -m venv .venv && source .venv/bin/activate
pip install maturin pytest pytest-asyncio httpx websockets cryptography
maturin develop --release
```

## Checks

The CI runs these on every push to `main` and on pull requests:

```bash
cargo fmt --manifest-path rust/Cargo.toml -- --check
cargo clippy --manifest-path rust/Cargo.toml --all-targets -- -D warnings
ruff check wse_server/ tests/
ruff format --check wse_server/ tests/
pytest tests/
```

`cargo test` doesn't link: the crate is a `cdylib` built with PyO3's `extension-module`.
The tests are in `tests/`, in Python, against the built module.

## Project structure

```
rust/          # the server: tokio, tungstenite, PyO3 bindings
wse_server/    # the Python package (imports as wse_server) and its type stubs
tests/         # integration tests: the built module against real WebSocket clients
benchmarks/    # benchmark servers in Python and rust-bench, a load generator in Rust
docs/          # architecture, protocol, deployment, security
examples/      # small servers
```

## Code standards

- Rust: `cargo fmt`, and `cargo clippy -- -D warnings` with `--all-targets`.
- Python: `ruff format` and `ruff check`; type annotations and docstrings on public API.
  A new method of `RustWSEServer` goes in `wse_server/_wse_accel.pyi` too.
- A change in behavior comes with a test in `tests/`.

## Commit messages

Imperative, with a type prefix: `fix(server): ...`, `feat(server): ...`, `perf(server): ...`,
`build: ...`. A body says what changed and why, in short lines or bullets.

## Releases

1. Bump the version in `pyproject.toml` and `rust/Cargo.toml`, and add it to
   `CHANGELOG.md`.
2. Tag the commit `vX.Y.Z` and push the tag.
3. The `Release` workflow builds the wheels (abi3, and cp314t for free-threaded Python),
   tests them, publishes them to PyPI and creates the GitHub release. It can also be run
   by hand on `main` (`workflow_dispatch`) to build and test without publishing.

## Changes for upstream

If wse-server's upstream becomes active again, a change can go back to it as a pull
request. Such a change lives on its own branch, based on upstream's `main`, not on ours,
so it doesn't carry the fork's other changes: `fix/pending-handshake-503`
(silvermpx/wse#73) and `perf/shared-broadcast-frames` (silvermpx/wse#74) are such
branches. Merge it into our `main` as well.
