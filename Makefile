SHELL := /bin/bash

# Absolute path to this Makefile's directory, so the targets work from anywhere.
ROOT := $(dir $(firstword $(MAKEFILE_LIST)))

PYTHON := $(ROOT).venv/bin/python

.DEFAULT_GOAL := help
.PHONY: help build build-lectures build-project test lint links duplicates diagrams \
        format-vhdl format-vhdl-check clean

help: ## Show this help.
	@echo "Targets:"
	@grep -hE '^[a-z-]+:.*##' $(MAKEFILE_LIST) \
	  | sed -e 's/:.*## / /' -e 's/^/  /' \
	  | awk '{ printf "  %-18s %s\n", $$1, substr($$0, index($$0, $$2)) }'
	@echo
	@echo "Build one lecture example instead of all of them:"
	@echo "  make build-lectures MODULE=fsm_led"

build: build-lectures build-project ## Everything: the lecture examples, then the project.

build-lectures: ## Analyze, elaborate, and simulate every L01-L08 example. Optional: MODULE=<name>
	$(ROOT)ci/build.sh $(MODULE)

# controller/ and bridge/ ship only the provided testbenches here, so a fresh clone reports every
# testbench as skipped. That is the expected state; see the header of ci/build_project.sh.
build-project: ## Analyze, elaborate, and simulate controller/ and bridge/ (the group project).
	$(ROOT)ci/build_project.sh

test: build ## Alias for build: building an example also runs its testbench.

# The CI lint job runs this exact target, so a green "make lint" locally means a green lint in
# CI, and a prerequisite added here is picked up there without touching the workflow.
lint: duplicates links format-vhdl-check ## Run every non-simulation check.

duplicates: ## Check that vendored copies of shared modules are still identical.
	$(ROOT)ci/duplicates.sh

links: ## Check that every relative link in the Markdown resolves.
	$(ROOT)ci/links.sh

# Deliberately not part of build or lint: the generated PNGs are committed, and redrawing them
# needs a Python environment this repo does not otherwise require. See diagrams/README.md for the
# one-time venv setup.
diagrams: ## Redraw the generated lecture figures. Optional: FIGURE=<name>
	@test -x $(PYTHON) || { \
	  echo "No Python environment at $(PYTHON). Create it once with:"; \
	  echo "  python3 -m venv .venv"; \
	  echo "  .venv/bin/pip install -r diagrams/requirements.txt"; \
	  exit 1; }
	$(PYTHON) $(ROOT)diagrams/build.py $(FIGURE)

format-vhdl: ## Strip trailing whitespace from the VHDL sources in place.
	$(ROOT)ci/format_vhdl.sh

format-vhdl-check: ## Fail if any VHDL source has trailing whitespace.
	$(ROOT)ci/format_vhdl.sh --check

clean: ## Remove GHDL work libraries, waveforms, and other generated files.
	$(ROOT)ci/clean.sh
