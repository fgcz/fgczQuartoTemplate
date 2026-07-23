## Regenerate every derived copy from the single source of truth: inst/quarto/.
##
## The template ships through two channels (see README "Way 1 / Way 2"):
##   - Way 1, the Quarto extension (`quarto add ...`): reads
##     _extensions/fgczQuartoTemplate/ from the repo root.
##   - Way 2, the R helper (`fgcz_render()`): stages inst/quarto/ next to a report.
## Quarto cannot read assets out of an installed R package, so both trees must be
## committed. To avoid hand-editing the same thing twice, ONLY inst/quarto/ is
## edited by hand; this script regenerates everything else deterministically:
##
##   1. copies the byte-identical shared assets into _extensions/;
##   2. BUILDS _extensions/.../_extension.yml (nested) from inst/quarto/_metadata.yml
##      (flat) -- so the format options have one source, not two shapes;
##   3. mirrors the finished extension into vignettes/_extensions/;
##   4. mirrors the visual abstract into vignettes/;
##   5. BUILDS vignettes/example-report.qmd from inst/quarto/template.qmd by
##      swapping only the YAML header -- so the docs-site example IS the template.
##
## Run it after editing anything in inst/quarto/, then commit. CI re-runs it and
## fails on any resulting `git diff`; the pre-commit hook (.githooks/pre-commit)
## runs it and re-stages the generated files so you cannot forget.
##
##   Rscript data-raw/sync_assets.R

dest_dir <- file.path("_extensions", "fgczQuartoTemplate")
stopifnot(dir.exists(dest_dir), dir.exists(file.path("inst", "quarto")))

## Byte-compare two files in full (no size cap).
same_bytes <- function(a, b) {
  identical(
    readBin(a, "raw", n = file.size(a)),
    readBin(b, "raw", n = file.size(b))
  )
}

## (1) Sync the byte-identical shared files ----------------------------------
shared <- c(
  "fgcz.scss",
  "fgcz_header_quarto.html",
  "fgcz-plot-finder.html",
  "fgcz-buttons.lua"
)
src <- file.path("inst", "quarto", shared)
stopifnot(all(file.exists(src)))
ok <- file.copy(src, dest_dir, overwrite = TRUE)
if (!all(ok)) {
  stop("Failed to sync: ", paste(shared[!ok], collapse = ", "))
}
for (f in shared) {
  if (!same_bytes(file.path("inst", "quarto", f), file.path(dest_dir, f))) {
    stop("Out of sync after copy: ", f)
  }
}

## (2) Build _extension.yml from _metadata.yml -------------------------------
## _metadata.yml is the single config source. It keeps `format.html` plus the
## document-wide `execute`/`knitr`/`crossref`/`lightbox` blocks flat; the
## extension needs the same options nested under `contributes.formats.html`,
## plus a static header and the buttons filter. We copy the option *lines
## verbatim* (only re-indenting), rather than round-tripping through a YAML
## serializer: as.yaml() would rewrite booleans as `yes`/`no` (which Quarto's
## YAML-1.2 parser reads as strings, not true/false) and drop quoting like
## "40%". Copying the source lines keeps every value byte-faithful and makes the
## output deterministic across R / yaml versions, so the CI diff stays stable.
build_extension_yml <- function(meta_lines, version) {
  indent_of <- function(s) attr(regexpr("^ *", s), "match.length")
  drop_line <- function(s) grepl("^\\s*(#.*)?$", s) # blank or comment-only

  # (a) the format.html options: every line indented under `  html:`, up to the
  #     next top-level (indent 0) key. Comments/blanks dropped; re-indent +2
  #     (base 4 -> base 6) to sit under contributes.formats.html.
  html_at <- match(TRUE, grepl("^  html:[[:space:]]*$", meta_lines))
  if (is.na(html_at)) {
    stop("Expected a `  html:` line under `format:` in _metadata.yml.")
  }
  after <- meta_lines[(html_at + 1):length(meta_lines)]
  end <- which(!drop_line(after) & indent_of(after) == 0)
  html_block <- if (length(end)) after[seq_len(end[1] - 1)] else after
  html_block <- paste0("  ", html_block[!drop_line(html_block)])

  # (b) the document-wide blocks, re-indented from base 0 to base 6 (+6).
  fold_top <- function(key) {
    at <- match(TRUE, grepl(paste0("^", key, ":"), meta_lines))
    if (is.na(at)) stop("Expected top-level `", key, ":` in _metadata.yml.")
    block <- meta_lines[at]
    j <- at + 1L
    while (
      j <= length(meta_lines) &&
        (drop_line(meta_lines[j]) || indent_of(meta_lines[j]) > 0)
    ) {
      if (!drop_line(meta_lines[j])) block <- c(block, meta_lines[j])
      j <- j + 1L
    }
    paste0("      ", block)
  }
  folded <- unlist(
    lapply(c("execute", "knitr", "crossref", "lightbox"), fold_top),
    use.names = FALSE
  )

  c(
    "## ─────────────────────────────────────────────────────────────",
    "## FGCZ Quarto format extension  —  GENERATED FILE, DO NOT EDIT.",
    "## Regenerate with:  Rscript data-raw/sync_assets.R",
    "## Source of truth:  inst/quarto/_metadata.yml (flat) → nested here.",
    "## Installed with:   quarto add fgcz/fgczQuartoTemplate  (README: Way 1)",
    "## Reports declare:  format: fgczQuartoTemplate-html",
    "## `version` is stamped from DESCRIPTION.",
    "## ─────────────────────────────────────────────────────────────",
    "title: FGCZ Quarto Template",
    "author: FGCZ",
    paste0("version: ", version),
    'quarto-required: ">=1.4.0"',
    "contributes:",
    "  formats:",
    "    html:",
    html_block,
    "      # fgcz-buttons.lua reads an optional top-level `fgcz-buttons:`",
    "      # selection and passes it to the toolbar. The toolbar itself",
    "      # (fgcz-plot-finder.html) is opt-in: add per report",
    "      #   include-after-body: _extensions/fgczQuartoTemplate/fgcz-plot-finder.html",
    "      filters:",
    "        - fgcz-buttons.lua",
    folded
  )
}

meta_lines <- readLines(file.path("inst", "quarto", "_metadata.yml"), warn = FALSE)
version <- unname(read.dcf("DESCRIPTION", fields = "Version")[1, 1])
writeLines(
  build_extension_yml(meta_lines, version),
  file.path(dest_dir, "_extension.yml")
)

## (3) Mirror the finished extension into vignettes/ -------------------------
## The packaged demo vignette (vignettes/example-report.qmd) renders with
## `format: fgczQuartoTemplate-html`, so it needs the extension next to it at
## R CMD build time. This mirrors the already-synced _extensions/ tree verbatim.
vig_ext <- file.path("vignettes", "_extensions", "fgczQuartoTemplate")
dir.create(vig_ext, recursive = TRUE, showWarnings = FALSE)
ext_files <- list.files(dest_dir, full.names = TRUE)
ok3 <- file.copy(ext_files, vig_ext, overwrite = TRUE)
if (!all(ok3)) {
  stop("Failed to mirror extension into ", vig_ext)
}
for (f in basename(ext_files)) {
  if (!same_bytes(file.path(dest_dir, f), file.path(vig_ext, f))) {
    stop("Out of sync after mirror: vignettes copy of ", f)
  }
}

## The vignette and copied starter use the same visual abstract. Keep its
## packaged copy in inst/quarto/ as the source of truth too.
overview <- "fgcz-report-overview.svg"
overview_src <- file.path("inst", "quarto", overview)
overview_vignette <- file.path("vignettes", overview)
if (!file.copy(overview_src, overview_vignette, overwrite = TRUE)) {
  stop("Failed to mirror ", overview, " into vignettes/.")
}
if (!same_bytes(overview_src, overview_vignette)) {
  stop("Out of sync after mirror: vignettes copy of ", overview)
}

## (4) Build vignettes/example-report.qmd from template.qmd -------------------
## The two reports differ ONLY in their YAML header: template.qmd carries a
## `params`/`title` header for `fgcz_render()`, the vignette carries the
## `format: fgczQuartoTemplate-html` + `fgcz-buttons:` + VignetteEngine header.
## The ~450-line body is identical. We copy template.qmd's body verbatim and
## swap in the vignette header, so the docs-site example is provably the
## template and the CI diff-gate protects the shared body for free.
vignette_header <- c(
  "---",
  'title: "FGCZ tabset layout example"',
  "format:",
  "  fgczQuartoTemplate-html:",
  "    include-after-body: _extensions/fgczQuartoTemplate/fgcz-plot-finder.html",
  "fgcz-buttons: [search, download]",
  "vignette: >",
  "  %\\VignetteIndexEntry{Example FGCZ tabset report}",
  "  %\\VignetteEngine{quarto::format}",
  "  %\\VignetteEncoding{UTF-8}",
  "---"
)
tpl <- readLines(file.path("inst", "quarto", "template.qmd"), warn = FALSE)
fences <- which(tpl == "---")
if (length(fences) < 2 || fences[1] != 1L) {
  stop("inst/quarto/template.qmd must open with a `---` YAML header.")
}
body <- tpl[(fences[2] + 1):length(tpl)]
writeLines(
  c(vignette_header, body),
  file.path("vignettes", "example-report.qmd")
)

## (5) Belt-and-braces: both author-facing examples keep the required shell ----
validate_report_layout <- function(path) {
  qmd <- trimws(readLines(path, warn = FALSE))
  top_level <- grep("^# ", qmd, value = TRUE)
  session_info <- match("# Session Info", qmd)
  if (
    length(top_level) < 2 ||
      top_level[[1]] != "# Overview" ||
      tail(top_level, 1) != "# Session Info" ||
      is.na(session_info)
  ) {
    stop(path, " must start with Overview and end with Session Info.")
  }
  session_subtabs <- grep(
    "^## ",
    qmd[session_info:length(qmd)],
    value = TRUE
  )
  expected <- c("## Report provenance", "## R session info")
  if (!identical(session_subtabs, expected)) {
    stop(path, " must contain exactly the required Session Info subtabs.")
  }
  if (!any(grepl(overview, qmd, fixed = TRUE))) {
    stop(path, " must reference ", overview, ".")
  }
}

invisible(lapply(
  c(
    file.path("inst", "quarto", "template.qmd"),
    file.path("vignettes", "example-report.qmd")
  ),
  validate_report_layout
))

message(
  "OK: synced ",
  paste(shared, collapse = ", "),
  "; built _extension.yml from _metadata.yml and example-report.qmd from ",
  "template.qmd; mirrored the extension and visual abstract into vignettes/."
)
