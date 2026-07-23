# fgczQuartoTemplate

One shared **FGCZ look-and-feel** for Quarto reports (theme + header + defaults),
reusable across `ezRun`, `prolfqua`, `prolfquapp`, …. Reports can opt in to a
top-right toolbar — **🔍 Find** any figure or table in a graphical table of
contents, or **📥 Download** the plots as a ZIP.

**👉 [See the documentation site](https://fgcz.github.io/fgczQuartoTemplate/)** — including a live example report with the real layout, tabsets, figures, and the Find / Download toolbar.

There are **two ways** to use it. Pick one.

---

## Way 1 — Quarto extension (plain `quarto render`, no R)

Best when you render with the `quarto` CLI.

**Step 1.** In your project, once:

```sh
quarto add fgcz/fgczQuartoTemplate
```

This creates `_extensions/fgczQuartoTemplate/` in the project. Without that
extension directory, `format: fgczQuartoTemplate-html` will fail because Quarto
cannot resolve the custom format.

**Step 2.** In your report's YAML header:

```yaml
---
title: "My report"
format: fgczQuartoTemplate-html
---
```

**Step 3.** Render:

```sh
quarto render my_report.qmd
```

Done. ✅

**Optional — 🔍 Find / 📥 Download toolbar** (off by default). Switch it on and
select its buttons in the report header:

```yaml
format:
  fgczQuartoTemplate-html:
    include-after-body: _extensions/fgczQuartoTemplate/fgcz-plot-finder.html
fgcz-buttons: [search, download]
```

Use `fgcz-buttons: search` or `fgcz-buttons: download` for one button. Omit
`fgcz-buttons` to show both when the toolbar is included. Unknown names stop the
render instead of silently hiding controls.

---

## Way 2 — R helper (stage files, then render)

Best when you render from R (e.g. inside a package). **No `format:` line, no `quarto add`.**

**Step 1.** Install:

```r
remotes::install_github("fgcz/fgczQuartoTemplate")
```

**Step 2.** Your report's YAML header — just this, nothing FGCZ-specific:

```yaml
---
title: "My report"
---
```

**Step 3.** Render with the one-call helper:

```r
fgczQuartoTemplate::fgcz_render("my_report.qmd")                 # no toolbar
fgczQuartoTemplate::fgcz_render("my_report.qmd", buttons = TRUE) # 🔍 Find / 📥 Download
fgczQuartoTemplate::fgcz_render("my_report.qmd", buttons = "search") # 🔍 Find only
```

Done. ✅ (`fgcz_render` copies `_metadata.yml`, `fgcz.scss`,
`fgcz_header_quarto.html`, and `fgcz-plot-finder.html` next to the `.qmd`, then
calls `quarto::quarto_render()`. The toolbar is staged either way but only wired
in when enabled. `TRUE` and `FALSE` remain supported; button names allow finer
selection.)

If you want to separate these two steps, copy the assets first and render
yourself:

```r
input <- "my_report.qmd"
fgczQuartoTemplate::fgcz_copy_assets(input)
quarto::quarto_render(input)
```

`fgcz_copy_assets()` accepts either the `.qmd` path above, or an existing
directory. These two calls are equivalent:

```r
fgczQuartoTemplate::fgcz_copy_assets(input)
fgczQuartoTemplate::fgcz_copy_assets(dirname(normalizePath(input)))
```

---

## Which one?

| | Way 1 — Extension | Way 2 — R helper |
|---|---|---|
| Install | `quarto add …` (once per project) | `install_github` (once) |
| YAML | `format: fgczQuartoTemplate-html` | nothing |
| Render | `quarto render` | `fgczQuartoTemplate::fgcz_render()` |
| Use it when | CLI / non-R pipelines | rendering from R |

Both produce the **same** report. They can coexist in one repo.

---

## R helper cheatsheet (Way 2)

```r
fgcz_render("report.qmd")               # stage assets + render (the usual one)
fgcz_render("report.qmd", buttons = TRUE) # ...plus the 🔍 Find / 📥 Download toolbar
fgcz_render("report.qmd", buttons = "download") # ...or just 📥 Download
fgcz_copy_assets("report.qmd")          # stage assets next to that file
fgcz_copy_assets("dir")                 # or stage assets into an existing dir
fgcz_use_template("dir", "report.qmd")  # start a new report from the template
fgcz_quarto_dir()                       # where the installed assets live
```

## Why two mechanisms exist (30-second version)

Quarto can't reach into an installed R package to fetch styling — the files must
sit next to the `.qmd` at render time. Two clean ways to get them there:

- **Extension**: `quarto add` drops them into `_extensions/`; you opt in with `format:`.
- **`_metadata.yml`**: a file with that exact name is auto-applied to every `.qmd`
  in its directory (no `format:` line); the R helper stages it for you.

## For maintainers

- **`inst/quarto/` is the only place you hand-edit.** Everything else is
  generated from it by `Rscript data-raw/sync_assets.R` (or `make sync`):
  - `fgcz.scss`, `fgcz_header_quarto.html`, `fgcz-plot-finder.html`,
    `fgcz-buttons.lua` — byte-copied into `_extensions/` and
    `vignettes/_extensions/`.
  - `_extensions/fgczQuartoTemplate/_extension.yml` (nested, Way 1) — **built**
    from `inst/quarto/_metadata.yml` (flat, Way 2); edit the format options in
    `_metadata.yml` only. `version` is stamped from `DESCRIPTION`.
  - `vignettes/example-report.qmd` — **built** from `inst/quarto/template.qmd`
    (same body, vignette header swapped in); edit the report in `template.qmd`.
- **Install the hook once per clone:** `make hooks` (or
  `git config core.hooksPath .githooks`). It runs the sync and re-stages the
  generated files on every commit, so editing `inst/quarto/` is enough. CI
  (`.github/workflows/altdoc.yml`) re-runs the sync and fails on any drift as a
  backstop.
- The live example report is the `vignettes/example-report.qmd` vignette; the
  documentation site (built with `altdoc` — `make site`) renders it through Quarto
  with its tabsets intact.

## License

GPL (>= 3), matching `ezRun`.
