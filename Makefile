# Run the jobs of .github/workflows/ci.yml locally, in the same order:
#   make ci         lint -> rust-lint -> test -> audit, stopping at the first failure
#   make lint       Ruff check and format check, Ruff pinned as in CI
#   make rust-lint  cargo fmt --check and clippy with warnings as errors
#   make test       build the extension into .venv (Python 3.14t) and run pytest
#   make audit      cargo audit, installing cargo-audit if missing

PYTHON ?= 3.14t
RUFF_VERSION ?= 0.15.4
VENV ?= .venv
CARGO_MANIFEST := rust/Cargo.toml
TEST_DEPS := maturin pytest pytest-asyncio pytest-cov httpx websockets cryptography

.PHONY: ci lint rust-lint test audit venv clean

ci: lint rust-lint test audit

lint:
	uvx ruff@$(RUFF_VERSION) check wse_server/ tests/
	uvx ruff@$(RUFF_VERSION) format --check wse_server/ tests/

rust-lint:
	cargo fmt --manifest-path $(CARGO_MANIFEST) -- --check
	cargo clippy --manifest-path $(CARGO_MANIFEST) --all-targets -- -D warnings

$(VENV)/bin/python:
	uv venv --python $(PYTHON) $(VENV)

venv: $(VENV)/bin/python
	uv pip install --python $(VENV)/bin/python $(TEST_DEPS)

test: venv
	VIRTUAL_ENV=$(CURDIR)/$(VENV) $(VENV)/bin/maturin develop --release --uv
	$(VENV)/bin/python -m pytest tests/ -v --tb=short

# RUSTSEC-2023-0071: rsa crate Marvin Attack (timing side-channel in RSA decryption).
# Not exploitable: WSE uses jsonwebtoken for JWT signature verification only, never
# RSA decryption. No fix available upstream. (Same as in CI.)
audit:
	@cargo audit --version >/dev/null 2>&1 || cargo install cargo-audit --locked
	cargo audit --file rust/Cargo.lock --ignore RUSTSEC-2023-0071

clean:
	rm -rf $(VENV)
