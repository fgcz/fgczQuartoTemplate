## Render the starter template with the Quarto extension into a self-contained,
## full-fidelity FGCZ-styled HTML, and place it where pkgdown will publish it.
##
## Why not a vignette? pkgdown re-themes articles (theme: none + its own
## template, extracting only <main>), so a vignette cannot show the real FGCZ
## layout. A standalone render served as a pkgdown asset shows it unmodified.
##
##   Rscript data-raw/render_example.R
##
## Output: pkgdown/assets/example-report.html  (pkgdown copies assets/ into the
## built site, so it is served at <site>/example-report.html).

stopifnot(nzchar(Sys.which("quarto")))

ext <- normalizePath(
  file.path("_extensions", "fgczquartotemplate"),
  mustWork = TRUE
)
qmd <- normalizePath(
  file.path("inst", "quarto", "template.qmd"),
  mustWork = TRUE
)
dir.create(
  file.path("pkgdown", "assets"),
  recursive = TRUE,
  showWarnings = FALSE
)
outfile <- normalizePath(
  file.path("pkgdown", "assets", "example-report.html"),
  mustWork = FALSE
)

# Single-file renders resolve _extensions in the input file's OWN directory and
# assemble self-contained output relative to the working directory, so render
# from inside a temp dir that carries its own copy of the extension.
tmp <- tempfile("fgcz_example_")
dir.create(file.path(tmp, "_extensions"), recursive = TRUE)
file.copy(ext, file.path(tmp, "_extensions"), recursive = TRUE)
file.copy(qmd, file.path(tmp, "example.qmd"), overwrite = TRUE)
# The toolbar is opt-in (off by default), but the live demo showcases it, so
# stage it next to the report and wire it in via include-after-body below.
file.copy(
  file.path(ext, "fgcz-plot-finder.html"),
  file.path(tmp, "fgcz-plot-finder.html"),
  overwrite = TRUE
)

oldwd <- setwd(tmp)
on.exit(setwd(oldwd), add = TRUE)
# lightbox:false — with embed-resources the lightbox "enlarge" <a href> points at
# the figure _files dir that Quarto then deletes, leaving dangling links. The
# demo is a single self-contained file, so disable lightbox for it (the layout,
# not click-to-zoom, is what this showcases). File-based reports keep lightbox.
#
# shQuote every arg: system2 passes them through a shell, so the space in the
# param value would otherwise be word-split.
status <- system2(
  "quarto",
  shQuote(c(
    "render",
    "example.qmd",
    "--to",
    "fgczquartotemplate-html",
    "--output",
    "example-report.html",
    "-M",
    "lightbox:false",
    "-M",
    "include-after-body:fgcz-plot-finder.html",
    "-P",
    "reportTitle:FGCZ live layout example"
  ))
)
setwd(oldwd)
if (status != 0L) {
  stop("quarto render failed (status ", status, ")")
}

file.copy(file.path(tmp, "example-report.html"), outfile, overwrite = TRUE)
message("Wrote ", outfile)
