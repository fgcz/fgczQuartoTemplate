# fgczQuartoTemplate development targets.
#
# Modelled on the canonical ecosystem template (makefiles/R-package.Makefile in
# the prolfqua_fml root) so the standard target surface is identical to every
# other R package. Two deliberate divergences, marked DIVERGE below:
#   1. `sync` mirrors the single-source assets in inst/quarto/ into the Quarto
#      extension (_extensions/) and the demo vignette (vignettes/_extensions/).
#      It is a prerequisite of every target that builds vignettes or the tarball,
#      because the example-report.qmd vignette includes the mirrored extension.
#   2. `site` uses altdoc (Quarto Website backend), not pkgdown: pkgdown mangles
#      Quarto panel-tabsets, whereas altdoc renders vignettes natively through
#      Quarto with the tabsets intact. Deployment is handled by CI
#      (.github/workflows/altdoc.yml -> gh-pages), so there is no local `deploy`.

.DEFAULT_GOAL := check

PKG_NAME := $(shell awk '/^Package:/ {print $$2; exit}' DESCRIPTION)
PKG_VERSION := $(shell awk '/^Version:/ {print $$2; exit}' DESCRIPTION)
TARBALL := ../$(PKG_NAME)_$(PKG_VERSION).tar.gz

DOCUMENT_CMD = Rscript -e "devtools::document()"
SYNC_CMD = Rscript data-raw/sync_assets.R
BUILD_CMD = Rscript -e "devtools::build(vignettes = TRUE)"
CHECK_CMD = Rscript -e "devtools::check()"
CHECK_FAST_CMD = Rscript -e "devtools::check(build_args = '--no-build-vignettes', args = '--no-vignettes', vignettes = FALSE)"
CHECK_BIOC_CMD = Rscript -e "BiocCheck::BiocCheck()"
BUILD_VIGNETTES_CMD = Rscript -e "devtools::build_vignettes()"
TEST_CMD = Rscript -e "devtools::test()"
COVERAGE_CMD = Rscript -e "covr::package_coverage() |> print()"
INSTALL_CMD = R CMD INSTALL $(TARBALL)
LINT_CMD = Rscript -e "lintr::lint_package()"
SITE_CMD = Rscript -e "altdoc::render_docs(freeze = FALSE)"
NEW_VERSION_CMD = Rscript -e "d <- read.dcf('DESCRIPTION'); old <- d[1, 'Version']; parts <- as.integer(strsplit(old, '.', fixed = TRUE)[[1]]); if (length(parts) < 3) parts <- c(parts, rep(0L, 3L - length(parts))); parts[3] <- parts[3] + 1L; new <- paste(parts, collapse = '.'); x <- readLines('DESCRIPTION'); x <- sub('^Version: .*', paste0('Version: ', new), x); writeLines(x, 'DESCRIPTION'); cat(new)"

.PHONY: all help document sync hooks build build-vignettes vignettes install test check-fast check-bioc check coverage lint format site clean new-version new_version vignette

all: check

help:
	@echo "$(PKG_NAME) development targets:"
	@echo "  make document        - generate roxygen2 docs"
	@echo "  make sync            - regenerate _extensions/, vignettes/_extensions/, _extension.yml and example-report.qmd from inst/quarto/"
	@echo "  make hooks           - install the pre-commit hook that runs sync automatically"
	@echo "  make build           - build source tarball with vignettes"
	@echo "  make build-vignettes - build vignettes into inst/doc"
	@echo "  make vignettes       - alias for build-vignettes"
	@echo "  make install         - build source tarball with vignettes and install it"
	@echo "  make test            - run testthat tests"
	@echo "  make check-fast      - R CMD check without vignettes"
	@echo "  make check-bioc      - run BiocCheck"
	@echo "  make check           - full R CMD check"
	@echo "  make coverage        - code coverage report"
	@echo "  make lint            - run lintr"
	@echo "  make format          - format with air"
	@echo "  make site            - build the documentation site locally with altdoc"
	@echo "  make vignette V=Name - render a single vignette"
	@echo "  make new-version     - bump patch version, commit, tag, and push"
	@echo "  make clean           - remove build artifacts"

document:
	$(DOCUMENT_CMD)

# DIVERGE: single source of truth is inst/quarto/; regenerate every derived copy.
sync:
	$(SYNC_CMD)

# Point git at the versioned hook dir so `sync` runs on every commit.
hooks:
	git config core.hooksPath .githooks
	@echo "Installed pre-commit hook (core.hooksPath = .githooks)."

build: document sync
	$(BUILD_CMD)

build-vignettes: document sync
	rm -rf doc inst/doc
	$(BUILD_VIGNETTES_CMD)
	mkdir -p inst/doc
	cp doc/*.html doc/*.Rmd doc/*.R inst/doc/ 2>/dev/null || true

vignettes: build-vignettes

install: build
	$(INSTALL_CMD)

test: document
	$(TEST_CMD)

check-fast: document sync
	$(CHECK_FAST_CMD)

check-bioc:
	$(CHECK_BIOC_CMD)

check: build
	$(CHECK_CMD)

coverage: document
	$(COVERAGE_CMD)

lint:
	$(LINT_CMD)

format:
	air format .

# DIVERGE: altdoc (Quarto Website) instead of pkgdown; CI deploys to gh-pages.
site: install
	$(SITE_CMD)

vignette:
ifndef V
	$(error Usage: make vignette V=<vignette_name>, e.g. make vignette V=fgczQuartoTemplate)
endif
	Rscript -e "rmarkdown::render('vignettes/$(V).Rmd')"

new-version new_version:
	@NEW_VERSION="$$( $(NEW_VERSION_CMD) )"; \
	echo "Bumped version to $$NEW_VERSION"; \
	git add DESCRIPTION; \
	git commit -m "new version $$NEW_VERSION"; \
	git tag "$$NEW_VERSION"; \
	git push && git push --tags; \
	echo "Released $$NEW_VERSION"

clean:
	rm -rf *.Rcheck
	rm -f Rplots.pdf
	rm -rf inst/doc doc Meta
	rm -rf docs _quarto
	rm -f vignettes/*.html vignettes/*.R
	rm -f ../$(PKG_NAME)_*.tar.gz
