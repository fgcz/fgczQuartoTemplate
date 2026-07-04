.DEFAULT_GOAL := check

PKG_NAME := $(shell awk '/^Package:/ {print $$2; exit}' DESCRIPTION)

.PHONY: help document sync example test check install site format clean

help:
	@echo "$(PKG_NAME) targets:"
	@echo "  make document  - regenerate roxygen2 docs (man/, NAMESPACE)"
	@echo "  make sync      - mirror inst/quarto assets into _extensions/ and verify _metadata.yml <-> _extension.yml agree"
	@echo "  make example   - sync, then render the live example report into pkgdown/assets/"
	@echo "  make test      - run testthat tests"
	@echo "  make check     - document + sync, then full R CMD check"
	@echo "  make install   - document + sync, then install into the active R library"
	@echo "  make site      - sync + render example, then build the pkgdown site locally"
	@echo "  make format    - format R sources with air"
	@echo "  make clean     - remove build artifacts"

document:
	Rscript -e "devtools::document()"

# The single source of truth is inst/quarto/. sync mirrors the shared assets into
# the Quarto extension and fails on any drift between the two channels' YAML, so
# everything that ships or renders the extension depends on it.
sync:
	Rscript data-raw/sync_assets.R

# render_example.R renders from _extensions/, so the extension must be synced first.
example: sync
	Rscript data-raw/render_example.R

test: document
	Rscript -e "devtools::test()"

check: document sync
	Rscript -e "devtools::check()"

install: document sync
	R CMD INSTALL .

site: example
	Rscript -e "pkgdown::build_site(install = TRUE)"

format:
	air format .

clean:
	rm -rf *.Rcheck docs
	rm -f Rplots.pdf pkgdown/assets/example-report.html
	rm -f ../$(PKG_NAME)_*.tar.gz
