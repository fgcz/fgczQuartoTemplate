# fgczquartotemplate 0.2.0

* The opt-in toolbar now docks the **🔍 Find** and **📥 Download** buttons on
  the right side below the FGCZ banner, around one-quarter of the viewport height
  from the top. Downloaded ZIP files now include a current timestamp, encode
  Order/Workunit identifiers when report metadata is available, and write current
  ZIP entry timestamps instead of the 1980 default.
* The documentation website is now built with
  [altdoc](https://altdoc.etiennebacher.com/) (Quarto Website backend) instead of
  pkgdown. pkgdown mangles Quarto `panel-tabset`s (its `tweak_tabsets` step crashes
  on them), whereas altdoc renders vignettes natively through Quarto with the
  tabsets intact.
* The FGCZ layout demo now ships as a rendered vignette
  (`vignettes/example-report.qmd`), built with `format: fgczquartotemplate-html`
  from the vendored `vignettes/_extensions/`, and is shown on the documentation
  site with its nested tabsets preserved.
* The `fgcz-quarto-reports` skill's caption guidance now includes a concrete
  before/after example: a negative (decorative, unsearchable) figure caption
  contrasted with a positive one that names the statistics, panels, axes, and
  diagnostic reading.
* The `fgcz-quarto-reports` skill now recommends recording B-Fabric / SUSHI
  report provenance **once** — a field/value table in a final Session Info tab
  (plus `sessionInfo()` and the `#fgcz-report-metadata` marker) — rather than
  duplicating the metadata in a top-of-page report-information callout.

# fgczquartotemplate 0.1.0

* The opt-in toolbar's **🔍 Find** panel now opens tabs through Bootstrap's tab
  API so htmlwidgets such as DT tables redraw when revealed from inactive tabs.
* The opt-in toolbar's **🔍 Find** panel now renders Plotly htmlwidgets as
  thumbnail cards by rasterizing the embedded widget JSON in the browser.
* The opt-in toolbar's **🔍 Find** panel now uses Quarto figure captions for
  Plotly htmlwidgets inside figure floats instead of adding duplicate
  captionless Plotly cards.
* The opt-in toolbar's **📥 Save** panel now excludes Plotly htmlwidgets inside
  figure floats from the static-download list.
* The opt-in toolbar's **🔍 Find** panel now renders DT tables as table
  preview cards instead of generic figure placeholders.
* The opt-in toolbar's **🔍 Find** button opens a graphical table of contents
  showing figures and tables, including content in inactive tabs; click one to
  jump to it. Results are grouped by their report location, and
  section/subsection/tab titles are included in filtering. Figure thumbnails
  reuse the report's embedded images, so they work offline. The **📥 Save**
  panel also shows thumbnails for downloadable plots.
* The search + download toolbar is now **opt-in**. `fgcz_render()` gains a
  `buttons` argument (default `FALSE`); pass `buttons = TRUE` to add the
  right-edge 🔍 Find / 📥 Save toolbar. It is no longer wired into
  `_metadata.yml` or the Quarto extension by default; the extension and plain
  `quarto render` routes opt in with an `include-after-body:` line.
* `fgcz_copy_assets()` accepts either an existing directory or a `.qmd` file
  path.
