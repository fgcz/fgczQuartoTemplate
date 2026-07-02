# fgczquartotemplate

Shared **Quarto report assets** for FGCZ analysis packages (`ezRun`,
`prolfqua`, …). It packages one common look-and-feel — a directory-level
`_metadata.yml`, an SCSS theme, and an HTML header — plus a starter report
template and small helpers to stage those files next to a `.qmd` and render it.

The goal: keep the FGCZ report styling in **one place** so every package that
produces Quarto reports shares it and a theme change is a single package bump.

## What's inside

Installed under `inst/quarto/`:

| File | Role |
|------|------|
| `_metadata.yml` | Shared format defaults. Quarto applies it **automatically** to every `.qmd` in its directory — reports need no reference to it. |
| `fgcz.scss` | Theme overrides — tabset/card styling, figure rows. |
| `fgcz_header_quarto.html` | FGCZ header, injected via `include-in-header`. |
| `template.qmd` | Generic starter report demonstrating the tabset, figure+callout, and nesting patterns. |

## How the styling attaches (no front-matter coupling)

Quarto automatically merges a file named `_metadata.yml` into every `.qmd` in
its directory and subdirectories. So a report carries **no** `metadata-files`
line and no path to this package — it stays a plain `.qmd`. As long as the
three files above sit in the same directory, a bare

```sh
quarto render CountQC.qmd
```

renders with full FGCZ styling **even if this package is not installed**.

The `_metadata.yml` references `fgcz.scss` and `fgcz_header_quarto.html` by bare
filename, which Quarto resolves relative to the input `.qmd`, so all three must
travel together. The package's only job is to *stage* them next to a `.qmd`
that lives elsewhere — that is what `fgcz_copy_assets()` / `fgcz_render()` do.

## Usage

Your report's front matter is just its own params/title — nothing FGCZ-specific:

```yaml
---
params:
  reportTitle: "CountQC"
title: "`r params$reportTitle`"
---
```

Render it through the wrapper — the shared assets are staged automatically:

```r
fgczquartotemplate::fgcz_render(
  "CountQC.qmd",
  execute_params = list(reportTitle = "CountQC")
)
```

Bootstrap a brand-new report from the starter template:

```r
fgczquartotemplate::fgcz_use_template("reports/my_analysis",
                                      to = "my_analysis.qmd")
# edit reports/my_analysis/my_analysis.qmd, then:
fgczquartotemplate::fgcz_render("reports/my_analysis/my_analysis.qmd")
```

Just need the paths (e.g. to stage assets yourself)?

```r
fgczquartotemplate::fgcz_quarto_dir()             # the inst/quarto directory
fgczquartotemplate::fgcz_copy_assets("some/dir")  # stage the 3 styling files
```

## Using it from ezRun / prolfqua

1. Add `fgczquartotemplate` to `Imports` in the consumer's `DESCRIPTION`.
2. Replace ad-hoc `quarto_render()` calls with `fgczquartotemplate::fgcz_render()`.
3. In the consumer, **git-ignore the staged copies** so the packaged assets
   remain the single source of truth — add to the render directory's
   `.gitignore`:

   ```
   _metadata.yml
   fgcz.scss
   fgcz_header_quarto.html
   ```

App-specific reports (e.g. `CountQC.qmd`, `ScSeurat.qmd`) stay in their own
package; only the shared *styling* lives here.

## Installation

```r
# from a local checkout
devtools::install("path/to/fgczquartotemplate")
```

## Requirements

- [Quarto](https://quarto.org/) on `PATH`
- R package `quarto`

## License

GPL-3 (matching `ezRun`).
