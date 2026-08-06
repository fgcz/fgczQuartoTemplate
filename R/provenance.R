#' Link to this report's `.qmd` source, if it's alongside the output
#'
#' For use inside a report's own Report Provenance table (see `template.qmd`).
#' FGCZ reports are typically rendered in place on gStore/pStore, where the
#' input `.qmd` ends up sitting right beside the rendered `.html` -- this
#' returns a relative hyperlink to it in that case, so a reader can jump
#' straight to the report's source without going through the toolbar's
#' Download panel or needing `code-tools: true`. Returns `""` when no such
#' file can be found (e.g. an interactive session, a render outside Quarto, or
#' a `.qmd` later moved away from its rendered output), so it can be dropped
#' with the same "drop empty values" idiom a provenance table already uses
#' for other rows.
#'
#' Deliberately does not use [knitr::current_input()]: Quarto knits an
#' intermediate `.rmarkdown` file, not the original `.qmd`, so
#' `current_input()` reports the wrong name. `QUARTO_DOCUMENT_FILE` is the
#' environment variable Quarto itself sets to the true source filename for the
#' executing document. `QUARTO_DOCUMENT_PATH` (its directory) is deliberately
#' NOT used to build the existence check or the link -- it is reported
#' relative to the directory Quarto was invoked *from*, not relative to
#' `getwd()` during chunk execution (which knitr always sets to the
#' document's own directory), so joining the two points at the wrong place. A
#' bare filename is correct for both.
#'
#' @return A single string: an HTML `<a>` tag linking to the `.qmd` by its
#'   relative filename, or `""` if the source cannot be located.
#' @export
#'
#' @examples
#' \dontrun{
#' # Inside a report's report-provenance chunk:
#' .prov <- c("Qmd source" = fgcz_qmd_source_link(), ...)
#' .prov <- .prov[nzchar(.prov)]
#' knitr::kable(data.frame(Field = names(.prov), Value = unname(.prov)), escape = FALSE)
#' }
fgcz_qmd_source_link <- function() {
  qmd <- Sys.getenv("QUARTO_DOCUMENT_FILE", unset = "")
  if (!nzchar(qmd) || !file.exists(qmd)) {
    return("")
  }
  sprintf('<a href="%s">%s</a>', qmd, qmd)
}
