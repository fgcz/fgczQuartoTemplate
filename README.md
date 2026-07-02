# fgczquartotemplate

One shared **FGCZ look-and-feel** for Quarto reports (theme + header + defaults),
reusable across `ezRun`, `prolfqua`, `prolfquapp`, …

**👉 [See a live example report](https://prolfqua.github.io/fgczquartotemplate/example-report.html)** — the real layout, tabsets, and figures.

There are **two ways** to use it. Pick one.

---

## Way 1 — Quarto extension (plain `quarto render`, no R)

Best when you render with the `quarto` CLI.

**Step 1.** In your project, once:

```sh
quarto add prolfqua/fgczquartotemplate
```

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

**Step 3.** Stage the styling next to the report, then render:

```r
fgczquartotemplate::fgcz_render("my_report.qmd")
```

Done. ✅ (`fgcz_render` copies `_metadata.yml` + `fgcz.scss` + `fgcz_header_quarto.html`
next to the `.qmd`, which Quarto then applies automatically.)

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
fgcz_copy_assets("dir")                 # just stage the 3 files into dir
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
  `Rscript data-raw/sync_assets.R` to mirror them into `_extensions/`.
- Keep `inst/quarto/_metadata.yml` and `_extensions/fgczquartotemplate/_extension.yml`
  in step (same format options, one flat / one nested under `contributes`).
- `Rscript data-raw/render_example.R` regenerates the live example report.

## License

GPL (>= 3), matching `ezRun`.
