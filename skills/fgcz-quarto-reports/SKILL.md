---
name: fgcz-quarto-reports
description: >-
  Conventions for authoring FGCZ Quarto analysis reports with the
  fgczquartotemplate package: tab-depth rules, one-screen layout, small gridded
  figures with lightbox zoom, and when interactive (plotly/ggplotly) figures are
  worth it. Use this skill whenever writing, structuring, or reviewing a `.qmd`
  report that uses the FGCZ template (fgczquartotemplate, `_metadata.yml`, or
  `format: fgczquartotemplate-html`), deciding how to lay out tabs and figures
  in an FGCZ / SUSHI report, or turning an analysis (ezRun, prolfqua,
  prolfquapp, DIA-NN, single-cell) into an FGCZ-styled HTML report — even if the
  user never names the template explicitly.
---

# Authoring FGCZ Quarto reports

This skill is about **how to structure a report** — the layout and content
decisions that make an FGCZ report readable. For *setting up* the template
(installing / wiring it), see the package `README.md`. Here we assume the
styling is already attached and focus on the choices that are easy to get wrong.

The golden rule behind everything below: **a reader should understand each tab
at a glance and navigate by clicking, not by scrolling and hunting.**

## Using the template: two ways (pick one)

The package ships the same FGCZ styling through two channels — both produce an
identical report, so choose by *how you render*. Full setup details live in the
package `README.md`; this is the short version.

**Way 1 — Quarto extension (render with the `quarto` CLI, no R).**
Install once per project, then opt in from the header:
```sh
quarto add prolfqua/fgczquartotemplate
```
```yaml
---
title: "My report"
format: fgczquartotemplate-html
---
```
Render with plain `quarto render my_report.qmd`.

**Way 2 — R helper (render from R, e.g. inside a package like prolfquapp).**
Install once (`remotes::install_github("prolfqua/fgczquartotemplate")`), keep the
report header free of any `format:` line, and render with:
```r
fgczquartotemplate::fgcz_render("my_report.qmd")
```
It stages `_metadata.yml` (plus the theme, header, and toolbar files) next to the
`.qmd`, and Quarto applies `_metadata.yml` automatically — no `format:` line and
no `quarto add`. Companion helpers: `fgcz_use_template()` starts a new report
from the annotated starter, `fgcz_copy_assets()` just stages the files, and
`fgcz_quarto_dir()` points at the installed assets.

Either way you get the theme and the FGCZ header for free. The top-right
**🔍 Find / 📥 Download** toolbar is opt-in — turn it on with
`fgcz_render(buttons = TRUE)` (or an `include-after-body:` line for the CLI
routes); see the last section. Start from `inst/quarto/template.qmd` (via
`fgcz_use_template()`), which demonstrates every layout pattern below in code.

## Tabs: keep them shallow

Organize the report with `::: {.panel-tabset}`. Depth is the single most common
mistake, so be deliberate:

- **Two tab levels is the norm.** Top-level tabs = major sections; one level of
  sub-tabs inside them is plenty for almost every report.
- **A third level is the exception**, allowed only when the third-level tabs are
  the **same across every second-level tab** — i.e. the nesting forms a clean
  matrix (pick a category, then pick a view).

  Good (third level is uniform → nest it):
  ```
  Method A → { Overview, Details }
  Method B → { Overview, Details }
  ```
  Not OK (third level diverges → do NOT nest):
  ```
  Method A → { Overview, Details }
  Method C → { Foo, Bar }          ← different sub-tabs
  ```
  When one branch's sub-tabs differ, that branch is really its own section:
  **promote it to a top-level tab** rather than forcing an inconsistent third
  level. Uniform sub-tabs read as "same views for each thing"; divergent ones
  hide structure and confuse the reader.

Note: `template.qmd` deliberately demonstrates nesting up to five levels — that
is a *capability* demo showing the mechanics render correctly, **not** a
recommendation. Real reports stay at two levels, occasionally three.

## Fit each tab on one screen

Aim for a tab's content to fit on screen **without vertical scrolling**. The
reader should take in a tab at a glance and switch tabs for more, rather than
scroll and search.

The one honest exception is **the same figure repeated per sample or
condition** — e.g. a TIC chromatogram shown separately for samples A, B, C,
stacked vertically. Repetition-by-sample stays legible when scrolled because the
reader knows exactly what each item is. Stacking *unrelated* content to fill a
long page does not — split that across tabs instead.

## Figures: small and gridded

- **Don't make figures large.** Every figure is click-to-zoom (lightbox is on by
  default), so a compact on-page figure plus zoom-on-click beats a giant inline
  one — and it lets more fit on a screen.
- **Lay figures out in a grid** so several share a screen. Use Quarto's layout:
  ```
  #| layout-ncol: 2
  ```
  inside a chunk (or `::: {layout-ncol="2"}` around several figures). The
  template also provides `.fig-row` / `.fig-main` / `.fig-side` for a figure
  with a side callout.
- **Always give a figure a `#| fig-cap:`.** Captions are what the Find toolbar
  indexes and what makes cross-references work.

## Figure captions are searchable scientific labels

Write captions as short scientific labels, not decorative titles. The Find /
Figures toolbar indexes captions, so a reader should be able to search for the
biology, assay, metric, or plot type and recognize the right figure from the
caption alone.

Each caption should usually name:

- the measured quantity or data layer (`log2 intensity`, `protein abundance`,
  `cell embedding`, `residual density`, ...),
- what points/lines/curves represent,
- the x/y axes or visual encoding when it matters,
- grouping variables such as condition, batch, sample, cluster, or cell type,
- transformations, normalization, filtering, or subset if those change the
  interpretation.

Prefer specific captions:

```yaml
#| fig-cap: >-
#|   Precursor intensity as a function of acquisition time. Each point is one
#|   precursor measurement; the x-axis shows acquisition time in minutes and the
#|   y-axis shows log2 intensity, coloured by sample group.
```

```yaml
#| fig-cap: >-
#|   Density of log2 precursor intensities by condition after median
#|   normalization. Each curve is one sample; shifts in the density indicate
#|   global signal differences.
```

```yaml
#| fig-cap: >-
#|   UMAP of filtered cells coloured by annotated cell type. Each point is one
#|   cell; UMAP axes are embedding coordinates and do not have physical units.
```

```yaml
#| fig-cap: >-
#|   PCA of sample-level protein intensities after normalization. Points are
#|   samples, coloured by condition and shaped by batch; axis labels report the
#|   variance explained by PC1 and PC2.
```

A concrete before / after, from a differential-expression report whose figure
combines a fold-change histogram and a p-value histogram side by side.

**Negative example (avoid)** — a decorative title: it indexes nothing a reader
would search for and never says what the two panels are or how to read them:

```yaml
#| fig-cap: "Fold-change and p-value summaries."
```

**Positive example (prefer)** — names the statistics, both panels, their axes,
and the diagnostic reading, so the caption stands on its own in the Find list:

```yaml
#| fig-cap: >-
#|   Distributions of the differential-abundance statistics across all features.
#|   Left: histogram of the estimated log2 fold-changes (x-axis log2
#|   fold-change, y-axis feature count), expected to centre near zero because
#|   most features are not differentially abundant. Right: histogram of the
#|   significance score (p-value, or FDR/BFDR depending on the model; x-axis
#|   0-1, y-axis feature count), expected to be roughly uniform with a peak near
#|   zero when true effects are present.
```

Avoid vague captions such as `"PCA"`, `"UMAP"`, `"Density plot"`, or
`"Scatter plot"`. They are bad search targets and do not let a reviewer verify
that the figure is labelled correctly.

## Interactive figures are the exception

Default to **static** figures (`ggplot`). They are lighter, print cleanly, and —
importantly — the 📥 Download toolbar (when enabled) can bundle them into a ZIP;
interactive `plotly` / `ggplotly` charts cannot be downloaded that way.

Reach for `ggplotly()` **only when interactivity genuinely improves
readability**, for example:

- a legend too large to fit on the plot (let the reader hover instead), or
- many overlapping lines in similar colours (e.g. density overlays) where
  hover/zoom is the only way to disentangle them.

If a static figure reads fine, keep it static.

## The Find / Download toolbar: opt-in, and don't hand-build it

The template ships a top-right toolbar with two tools — **🔍 Find** (a
searchable graphical table of contents for every figure and table; clicking one
opens the tab it lives in and scrolls to it) and **📥 Download** (tick-box
download of the static plots as a single ZIP). It is **off by default**; switch
it on with `fgcz_render(buttons = TRUE)` (or an `include-after-body:
…/fgcz-plot-finder.html` line for the extension / plain `quarto render` routes).
When you want it, use that switch — never hand-add buttons, a table-of-figures,
or a thumbnail gallery; the template's version is complete and tested.

For B-Fabric / SUSHI reports, add report provenance in two places:

- A visible report-information callout near the top with Workunit, Order,
  Project, who generated the report, generation timestamp, software, and model
  where applicable.
- A final **Session Info** tab with the same metadata plus `sessionInfo()`.

To let the Download ZIP filename include the Order and Workunit, expose the same
metadata to the toolbar with a hidden marker before the toolbar include runs:

```html
<div id="fgcz-report-metadata" hidden
  data-project-id="12345"
  data-order-id="67890"
  data-workunit-id="348267"
  data-generated-by="sushi-user"
  data-generated-at="2026-07-10 09:30:00 CEST"></div>
```

The toolbar also reads matching `<meta name="fgcz-order-id" …>` /
`<meta name="fgcz-workunit-id" …>` tags and falls back to visible `Order:` /
`Workunit:` text when present, but the hidden marker is the preferred,
unambiguous contract.

Because the finder indexes figures and tables by their **caption** and their
**tab breadcrumb**, the same two habits that make a report readable also make
the finder and the figure gallery useful: give every figure/table a clear `fig-cap` / caption, and give
tabs meaningful labels.

## Quick checklist before you ship

- [ ] Two tab levels (a third only if its sub-tabs are identical across siblings)
- [ ] Each tab fits on a screen (scroll only for the same figure repeated per sample)
- [ ] Figures small and gridded (`layout-ncol`), each with a `fig-cap`
- [ ] Captions name the metric, axes/encoding, grouping, and key preprocessing
- [ ] Static figures unless interactivity is truly needed for readability
- [ ] Toolbar via `buttons = TRUE` (or `include-after-body`) if wanted — never hand-built
- [ ] B-Fabric reports include an info callout, Session Info metadata, and `#fgcz-report-metadata`

## Pointers

- `README.md` — installing / wiring the template (the two usage models)
- `inst/quarto/template.qmd` — worked examples of every pattern above
- `_metadata.yml` / `_extensions/fgczquartotemplate/_extension.yml` — the format options
