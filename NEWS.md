# fgczquartotemplate 0.0.0.9000

* The opt-in toolbar's **🔍 Find** button opens a graphical table of contents
  showing figures and tables, including content in inactive tabs; click one to
  jump to it. Results are grouped by their report location, and
  section/subsection/tab titles are included in filtering. Figure thumbnails
  reuse the report's embedded images, so they work offline.
* The search + download toolbar is now **opt-in**. `fgcz_render()` gains a
  `buttons` argument (default `FALSE`); pass `buttons = TRUE` to add the
  right-edge 🔍 Find / 📥 Save toolbar. It is no longer wired into
  `_metadata.yml` or the Quarto extension by default; the extension and plain
  `quarto render` routes opt in with an `include-after-body:` line.
* `fgcz_copy_assets()` accepts either an existing directory or a `.qmd` file
  path.
