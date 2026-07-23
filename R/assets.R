#' Shared FGCZ Quarto report assets
#'
#' The package ships a common set of Quarto report assets under
#' `inst/quarto/` so that FGCZ analysis packages (ezRun, prolfqua, ...) share
#' one look and feel:
#'
#' \describe{
#'   \item{`_metadata.yml`}{Shared format defaults. Quarto applies this file
#'     automatically to every `.qmd` in its directory (and subdirectories)
#'     because of its reserved name -- reports need no reference to it.}
#'   \item{`fgcz.scss`}{Theme overrides (tabset/card styling, figure rows).}
#'   \item{`fgcz_header_quarto.html`}{FGCZ header injected via
#'     `include-in-header`.}
#'   \item{`fgcz-plot-finder.html`}{Top-right search + download toolbar.
#'     Opt-in: staged next to every report but only injected (via
#'     `include-after-body`) when asked for, e.g.
#'     `fgcz_render(buttons = "search")`.}
#'   \item{`fgcz-buttons.lua`}{Quarto extension filter that validates and
#'     applies a report's optional `fgcz-buttons:` YAML selection.}
#'   \item{`template.qmd`}{A generic starter report demonstrating the tabset,
#'     figure-with-callout, and nesting patterns. It is copied with
#'     `fgcz-report-overview.svg`, the starter's visual abstract.}
#' }
#'
#' Because `_metadata.yml` is applied by directory, a `.qmd` rendered with a
#' plain `quarto render` picks up the FGCZ styling with **no package involved
#' and no front-matter reference** -- as long as the styling files sit in the
#' same directory. The `_metadata.yml` references `fgcz.scss` and
#' `fgcz_header_quarto.html` by bare filename, which Quarto resolves relative to
#' the input `.qmd`, so they must travel together; see [fgcz_copy_assets()] and
#' [fgcz_render()]. The toolbar (`fgcz-plot-finder.html`) is staged too but is
#' opt-in -- enable both buttons with `fgcz_render(buttons = TRUE)`, or select
#' buttons by name.
#'
#' @name fgczQuartoTemplate-assets
NULL

#' The names of the shared styling assets
#'
#' The files that every FGCZ report needs alongside it: the directory metadata
#' (`_metadata.yml`), the SCSS theme, the HTML header, and the search + download
#' toolbar. The first three are wired in by `_metadata.yml`; the toolbar is
#' staged too but stays opt-in (see [fgcz_render()]'s `buttons` argument).
#' `template.qmd` is deliberately excluded -- it is a starter you copy once, not
#' an asset staged on every render.
#'
#' @keywords internal
.fgcz_style_assets <- c(
  "_metadata.yml",
  "fgcz.scss",
  "fgcz_header_quarto.html",
  "fgcz-plot-finder.html"
)

#' Path to the installed Quarto assets
#'
#' @param ... Character path components appended to the asset directory, e.g.
#'   `fgcz_quarto_dir("template.qmd")`.
#'
#' @return An absolute path to the package's `inst/quarto` directory (or a file
#'   within it).
#' @export
#'
#' @examples
#' fgcz_quarto_dir()
#' fgcz_quarto_dir("template.qmd")
fgcz_quarto_dir <- function(...) {
  system.file("quarto", ..., package = "fgczQuartoTemplate", mustWork = TRUE)
}

#' Copy the shared report assets next to a `.qmd`
#'
#' Copies the shared styling files (`_metadata.yml`, `fgcz.scss`,
#' `fgcz_header_quarto.html`, `fgcz-plot-finder.html`) from the installed
#' package next to a report. `path` may be either an existing directory, or an
#' existing `.qmd` file whose containing directory should receive the assets.
#' Because `_metadata.yml` is directory metadata, any `.qmd` in the target
#' directory then renders with the FGCZ styling automatically. The toolbar is
#' staged but remains opt-in. Call this before rendering, or use [fgcz_render()],
#' which calls it for you.
#'
#' @param path An existing directory to stage the assets into, or a path to the
#'   `.qmd` itself (assets go into its containing directory).
#' @param overwrite Overwrite existing copies in the target directory. Defaults
#'   to `TRUE` so the packaged assets stay the single source of truth.
#'
#' @return Character vector of the copied file paths, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' fgcz_copy_assets("path/to/report/dir")
#' fgcz_copy_assets("path/to/report.qmd")
#' }
fgcz_copy_assets <- function(path, overwrite = TRUE) {
  target <- .fgcz_asset_target_dir(path)
  src <- fgcz_quarto_dir(.fgcz_style_assets)
  ok <- file.copy(src, target, overwrite = overwrite)
  if (!all(ok)) {
    stop(
      "Failed to copy assets: ",
      paste(.fgcz_style_assets[!ok], collapse = ", ")
    )
  }
  invisible(file.path(target, .fgcz_style_assets))
}

# Resolve `path` (a directory, or a .qmd file) to the directory the assets
# should be copied into. Same message for every "wrong kind of path" case so
# the contract reads the same wherever it is hit.
.fgcz_asset_target_dir <- function(path) {
  bad <- "`path` must be a single directory or a path to a .qmd file."
  if (!is.character(path) || length(path) != 1 || is.na(path)) {
    stop(bad, call. = FALSE)
  }
  if (dir.exists(path)) {
    return(normalizePath(path, mustWork = TRUE))
  }
  if (file.exists(path)) {
    if (!grepl("[.]qmd$", path, ignore.case = TRUE)) {
      stop(bad, call. = FALSE)
    }
    return(dirname(normalizePath(path, mustWork = TRUE)))
  }
  stop("`path` does not exist: ", path, call. = FALSE)
}

#' Copy the starter template into a directory
#'
#' Copies `template.qmd` (a generic FGCZ report skeleton) and its
#' `fgcz-report-overview.svg` visual abstract into `dir`, together with the
#' styling assets they need. Use this to bootstrap a new report.
#'
#' @param dir Destination directory. Created if it does not exist.
#' @param to Filename for the copied template within `dir`.
#' @param overwrite Overwrite an existing file of the same name.
#'
#' @return Path to the copied template, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' fgcz_use_template("my_report", to = "my_report.qmd")
#' }
fgcz_use_template <- function(dir, to = "template.qmd", overwrite = FALSE) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
  dest <- file.path(dir, to)
  if (file.exists(dest) && !overwrite) {
    stop("'", dest, "' already exists; pass overwrite = TRUE to replace it.")
  }
  if (
    !file.copy(fgcz_quarto_dir("template.qmd"), dest, overwrite = overwrite)
  ) {
    stop("Failed to copy template to '", dest, "'.")
  }
  overview <- "fgcz-report-overview.svg"
  overview_dest <- file.path(dir, overview)
  if (
    (overwrite || !file.exists(overview_dest)) &&
      !file.copy(
        fgcz_quarto_dir(overview),
        overview_dest,
        overwrite = overwrite
      )
  ) {
    stop("Failed to copy template visual abstract to '", dir, "'.")
  }
  fgcz_copy_assets(dir)
  invisible(dest)
}

#' Render an FGCZ Quarto report
#'
#' Stages the shared styling assets next to `input` (via [fgcz_copy_assets()])
#' and then renders it with [quarto::quarto_render()]. The `.qmd` needs no
#' styling front matter at all: the staged `_metadata.yml` is picked up by
#' Quarto automatically, so the report stays fully portable.
#'
#' @param input Path to the `.qmd` to render.
#' @param buttons Which top-right toolbar buttons (`fgcz-plot-finder.html`) to
#'   add. Defaults to `FALSE`; `TRUE` enables both buttons for backward
#'   compatibility. Alternatively, pass `"search"` for Find, `"download"` for
#'   Download, or `c("search", "download")` for both. `FALSE`, `NULL`, and
#'   `character(0)` disable the toolbar.
#' @param ... Passed on to [quarto::quarto_render()] (e.g. `execute_params`,
#'   `output_file`, `quarto_args`). A `metadata` list passed here is honored;
#'   enabling buttons merges `include-after-body` into it.
#'
#' @return The value of [quarto::quarto_render()], invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' fgcz_render("CountQC.qmd", execute_params = list(reportTitle = "CountQC"))
#' fgcz_render("CountQC.qmd", buttons = TRUE) # with the Find/Download toolbar
#' fgcz_render("CountQC.qmd", buttons = "search") # Find only
#' }
fgcz_render <- function(input, buttons = FALSE, ...) {
  buttons <- .fgcz_validate_buttons(buttons)
  if (!requireNamespace("quarto", quietly = TRUE)) {
    stop("Package 'quarto' is required to render reports.")
  }
  stopifnot(file.exists(input))
  # Re-stages a pristine fgcz-plot-finder.html every render. Load-bearing: the
  # default overwrite = TRUE restores the `__FGCZ_BUTTONS__` placeholder that
  # .fgcz_set_toolbar_buttons() consumes below, so a second render with a
  # different `buttons` selection is not stuck with the first render's choice.
  fgcz_copy_assets(input)
  dots <- list(...)
  if (length(buttons)) {
    # The toolbar is opt-in: fgcz_copy_assets() staged it next to `input`.
    # Patch the staged copy so its JS shows only the selected buttons, then wire
    # it in for this render via include-after-body, merged into any
    # caller-supplied `metadata` so we do not clobber it.
    toolbar <- normalizePath(
      file.path(.fgcz_asset_target_dir(input), "fgcz-plot-finder.html"),
      mustWork = TRUE
    )
    .fgcz_set_toolbar_buttons(toolbar, buttons)
    md <- if (is.null(dots$metadata)) list() else dots$metadata
    md[["include-after-body"]] <- toolbar
    dots$metadata <- md
  }
  invisible(do.call(quarto::quarto_render, c(list(input = input), dots)))
}

# Valid toolbar button names, in display order.
.fgcz_valid_buttons <- c("search", "download")

# Validate and normalize the `buttons` argument. Logical scalars are retained
# for backward compatibility; named selections are returned in display order.
.fgcz_validate_buttons <- function(buttons) {
  if (is.null(buttons)) {
    return(character(0))
  }
  if (is.logical(buttons)) {
    if (length(buttons) != 1L || is.na(buttons)) {
      stop(
        "`buttons` must be a single TRUE or FALSE, NULL, or a character ",
        "vector containing only \"search\" and/or \"download\".",
        call. = FALSE
      )
    }
    if (buttons) {
      return(.fgcz_valid_buttons)
    }
    return(character(0))
  }
  if (!is.character(buttons) || anyNA(buttons)) {
    stop(
      "`buttons` must be a single TRUE or FALSE, NULL, or a character ",
      "vector containing only \"search\" and/or \"download\".",
      call. = FALSE
    )
  }
  bad <- setdiff(unique(buttons), .fgcz_valid_buttons)
  if (length(bad)) {
    stop(
      "Unknown toolbar button name(s): ",
      paste(bad, collapse = ", "),
      ". Valid names are: ",
      paste(.fgcz_valid_buttons, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  .fgcz_valid_buttons[.fgcz_valid_buttons %in% buttons]
}

# Replace the button-selection placeholder in a staged toolbar. The packaged
# source must contain it exactly once so configuration cannot silently fail.
.fgcz_set_toolbar_buttons <- function(path, buttons) {
  html <- readChar(path, file.info(path)$size, useBytes = TRUE)
  Encoding(html) <- "UTF-8"
  matches <- gregexpr("__FGCZ_BUTTONS__", html, fixed = TRUE)[[1]]
  if (identical(matches, -1L) || length(matches) != 1L) {
    stop(
      "The staged toolbar must contain exactly one button placeholder.",
      call. = FALSE
    )
  }
  html <- sub(
    "__FGCZ_BUTTONS__",
    paste(buttons, collapse = " "),
    html,
    fixed = TRUE
  )
  writeLines(html, path, sep = "", useBytes = TRUE)
  invisible(path)
}
