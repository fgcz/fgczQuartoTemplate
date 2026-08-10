SITE_CMD = Rscript -e "altdoc::render_docs(freeze = FALSE)"

.PHONY: sync

build build-vignettes check-fast precommit-prepare: sync

sync:
	Rscript data-raw/sync_assets.R

clean-package:
	rm -rf docs _quarto
	rm -f ../$(PKG_NAME)_*.tar.gz

help-package:
	@echo ""
	@echo "Package-specific:"
	@echo "  make sync             - regenerate Quarto extension and example assets"
