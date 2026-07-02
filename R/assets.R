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
#'   \item{`template.qmd`}{A generic starter report demonstrating the tabset,
#'     figure-with-callout, and nesting patterns.}
#' }
#'
#' Because `_metadata.yml` is applied by directory, a `.qmd` rendered with a
#' plain `quarto render` picks up the FGCZ styling with **no package involved
#' and no front-matter reference** -- as long as these three files sit in the
#' same directory. The `_metadata.yml` references `fgcz.scss` and
#' `fgcz_header_quarto.html` by bare filename, which Quarto resolves relative to
#' the input `.qmd`, so all three must travel together; see [fgcz_copy_assets()]
#' and [fgcz_render()].
#'
#' @name fgczquartotemplate-assets
NULL

#' The names of the shared styling assets
#'
#' The three files that every FGCZ report needs alongside it: the directory
#' metadata (`_metadata.yml`), the SCSS theme, and the HTML header.
#' `template.qmd` is deliberately excluded -- it is a starter you copy once, not
#' an asset staged on every render.
#'
#' @keywords internal
.fgcz_style_assets <- c(
  "_metadata.yml",
  "fgcz.scss",
  "fgcz_header_quarto.html"
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
  system.file("quarto", ..., package = "fgczquartotemplate", mustWork = TRUE)
}

#' Copy the shared report assets next to a `.qmd`
#'
#' Copies `_metadata.yml`, `fgcz.scss` and `fgcz_header_quarto.html` from the
#' installed package into `dir`. Because `_metadata.yml` is directory metadata,
#' any `.qmd` in `dir` then renders with the FGCZ styling automatically. Call
#' this before rendering, or use [fgcz_render()], which calls it for you.
#'
#' @param dir Directory that contains (or will contain) the `.qmd` to render.
#' @param overwrite Overwrite existing copies in `dir`. Defaults to `TRUE` so
#'   the packaged assets stay the single source of truth.
#'
#' @return Character vector of the copied file paths, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' fgcz_copy_assets("path/to/report/dir")
#' }
fgcz_copy_assets <- function(dir, overwrite = TRUE) {
  stopifnot(dir.exists(dir))
  src <- fgcz_quarto_dir(.fgcz_style_assets)
  ok <- file.copy(src, dir, overwrite = overwrite)
  if (!all(ok)) {
    stop("Failed to copy assets: ",
         paste(.fgcz_style_assets[!ok], collapse = ", "))
  }
  invisible(file.path(dir, .fgcz_style_assets))
}

#' Copy the starter template into a directory
#'
#' Copies `template.qmd` (a generic FGCZ report skeleton) into `dir`, together
#' with the styling assets it needs. Use this to bootstrap a new report.
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
  if (!file.copy(fgcz_quarto_dir("template.qmd"), dest, overwrite = overwrite)) {
    stop("Failed to copy template to '", dest, "'.")
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
#' @param ... Passed on to [quarto::quarto_render()] (e.g. `execute_params`,
#'   `output_file`, `quarto_args`).
#'
#' @return The value of [quarto::quarto_render()], invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' fgcz_render("CountQC.qmd", execute_params = list(reportTitle = "CountQC"))
#' }
fgcz_render <- function(input, ...) {
  if (!requireNamespace("quarto", quietly = TRUE)) {
    stop("Package 'quarto' is required to render reports.")
  }
  stopifnot(file.exists(input))
  fgcz_copy_assets(dirname(normalizePath(input)))
  invisible(quarto::quarto_render(input = input, ...))
}
