## Keep the two distribution channels consistent.
##
## Single source of truth: inst/quarto/
##   - Model A (R): fgcz_copy_assets() stages inst/quarto/{_metadata.yml, scss, header}
##   - Model B (Quarto extension): _extensions/fgczquartotemplate/ ships scss + header
##                                 and _extension.yml (same options, nested)
##
## This script (1) copies fgcz.scss + fgcz_header_quarto.html from inst/quarto/
## into the extension, and (2) asserts the FORMAT OPTIONS in inst/quarto/_metadata.yml
## match those under contributes.formats.html in the extension's _extension.yml.
## Run it after editing any of those files, then commit. CI re-runs it and fails
## on any git change or option mismatch.
##
##   Rscript data-raw/sync_assets.R

dest_dir <- file.path("_extensions", "fgczquartotemplate")
stopifnot(dir.exists(dest_dir), dir.exists(file.path("inst", "quarto")))

## (1) Sync the byte-identical shared files ----------------------------------
shared <- c("fgcz.scss", "fgcz_header_quarto.html")
src <- file.path("inst", "quarto", shared)
stopifnot(all(file.exists(src)))
ok <- file.copy(src, dest_dir, overwrite = TRUE)
if (!all(ok)) stop("Failed to sync: ", paste(shared[!ok], collapse = ", "))
for (f in shared) {
  a <- readBin(file.path("inst", "quarto", f), "raw", n = 1e7)
  b <- readBin(file.path(dest_dir, f), "raw", n = 1e7)
  if (!identical(a, b)) stop("Out of sync after copy: ", f)
}

## (2) Assert the format options agree between the two channels ----------------
if (!requireNamespace("yaml", quietly = TRUE)) {
  stop("Package 'yaml' is required to check _metadata.yml vs _extension.yml.")
}
meta <- yaml::read_yaml(file.path("inst", "quarto", "_metadata.yml"))
ext  <- yaml::read_yaml(file.path(dest_dir, "_extension.yml"))

# _metadata.yml keeps execute/knitr/crossref/lightbox at the top level (applied
# document-wide); the extension nests them inside the contributed html format.
meta_html <- meta$format$html
for (k in c("execute", "knitr", "crossref", "lightbox")) meta_html[[k]] <- meta[[k]]
ext_html <- ext$contributes$formats$html

# Order-independent deep comparison of the two option trees.
norm <- function(x) {
  if (is.list(x)) {
    nm <- names(x)
    if (!is.null(nm)) x <- x[order(nm)]
    lapply(x, norm)
  } else {
    x
  }
}
if (!identical(norm(meta_html), norm(ext_html))) {
  only_meta <- setdiff(names(meta_html), names(ext_html))
  only_ext  <- setdiff(names(ext_html), names(meta_html))
  common <- intersect(names(meta_html), names(ext_html))
  diffkeys <- common[!vapply(common,
    function(k) identical(norm(meta_html[[k]]), norm(ext_html[[k]])), logical(1))]
  stop("Format options differ between inst/quarto/_metadata.yml and ",
       dest_dir, "/_extension.yml.\n",
       if (length(only_meta)) paste0("  only in _metadata.yml: ", paste(only_meta, collapse = ", "), "\n"),
       if (length(only_ext))  paste0("  only in _extension.yml: ", paste(only_ext, collapse = ", "), "\n"),
       if (length(diffkeys))  paste0("  differing values for: ", paste(diffkeys, collapse = ", "), "\n"),
       "Reconcile them by hand so both channels render identically.")
}

message("OK: synced ", paste(shared, collapse = ", "),
        " and verified _metadata.yml <-> _extension.yml format options match.")
