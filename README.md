# fgczquartotemplate

One shared **FGCZ look-and-feel** for Quarto reports (theme + header + defaults),
reusable across `ezRun`, `prolfqua`, `prolfquapp`, …. Reports can opt in to a
right-edge toolbar — **🔍 Find** any figure or table, browse them as a
**🖼️ Figures** thumbnail gallery, or **📥 Save** the plots as a ZIP.

**👉 [See the documentation site](https://prolfqua.github.io/fgczquartotemplate/)** — including a live example report with the real layout, tabsets, figures, and the Find / Figures / Save toolbar.

There are **two ways** to use it. Pick one.

---

## Way 1 — Quarto extension (plain `quarto render`, no R)

Best when you render with the `quarto` CLI.

**Step 1.** In your project, once:

```sh
quarto add prolfqua/fgczquartotemplate
```

This creates `_extensions/fgczquartotemplate/` in the project. Without that
extension directory, `format: fgczquartotemplate-html` will fail because Quarto
cannot resolve the custom format.

**Step 2.** In your report's YAML header:

```yaml
---
title: "My report"
format: fgczquartotemplate-html
---
```

**Step 3.** Render:

```sh
quarto render my_report.qmd
```

Done. ✅

**Optional — 🔍 Find / 🖼️ Figures / 📥 Save toolbar** (off by default). Switch it on per
report by adding one line to the header:

```yaml
include-after-body: _extensions/fgczquartotemplate/fgcz-plot-finder.html
```

---

## Way 2 — R helper (stage files, then render)

Best when you render from R (e.g. inside a package). **No `format:` line, no `quarto add`.**

**Step 1.** Install:

```r
remotes::install_github("prolfqua/fgczquartotemplate")
```

**Step 2.** Your report's YAML header — just this, nothing FGCZ-specific:

```yaml
---
title: "My report"
---
```

**Step 3.** Render with the one-call helper:

```r
fgczquartotemplate::fgcz_render("my_report.qmd")                 # no toolbar
fgczquartotemplate::fgcz_render("my_report.qmd", buttons = TRUE) # 🔍 Find / 🖼️ Figures / 📥 Save
```

Done. ✅ (`fgcz_render` copies `_metadata.yml`, `fgcz.scss`,
`fgcz_header_quarto.html`, and `fgcz-plot-finder.html` next to the `.qmd`, then
calls `quarto::quarto_render()`. The toolbar is staged either way but only wired
in when `buttons = TRUE`.)

If you want to separate these two steps, copy the assets first and render
yourself:

```r
input <- "my_report.qmd"
fgczquartotemplate::fgcz_copy_assets(input)
quarto::quarto_render(input)
```

`fgcz_copy_assets()` accepts either the `.qmd` path above, or an existing
directory. These two calls are equivalent:

```r
fgczquartotemplate::fgcz_copy_assets(input)
fgczquartotemplate::fgcz_copy_assets(dirname(normalizePath(input)))
```

---

## Which one?

| | Way 1 — Extension | Way 2 — R helper |
|---|---|---|
| Install | `quarto add …` (once per project) | `install_github` (once) |
| YAML | `format: fgczquartotemplate-html` | nothing |
| Render | `quarto render` | `fgczquartotemplate::fgcz_render()` |
| Use it when | CLI / non-R pipelines | rendering from R |

Both produce the **same** report. They can coexist in one repo.

---

## R helper cheatsheet (Way 2)

```r
fgcz_render("report.qmd")               # stage assets + render (the usual one)
fgcz_render("report.qmd", buttons = TRUE) # ...plus the 🔍 Find / 🖼️ Figures / 📥 Save toolbar
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

- Edit `fgcz.scss` / `fgcz_header_quarto.html` in `inst/quarto/`, then run
  `Rscript data-raw/sync_assets.R` to mirror them into `_extensions/` and
  `vignettes/_extensions/`.
- Keep `inst/quarto/_metadata.yml` and `_extensions/fgczquartotemplate/_extension.yml`
  in step (same format options, one flat / one nested under `contributes`).
- The live example report is the `vignettes/example-report.qmd` vignette; the
  documentation site (built with `altdoc` — `make site`) renders it through Quarto
  with its tabsets intact.

## License

GPL (>= 3), matching `ezRun`.
