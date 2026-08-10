test_that("fgcz_copy_assets copies assets into a directory", {
  dir <- tempfile()
  dir.create(dir)
  expected_files <- c(
    "_metadata.yml",
    "fgcz.scss",
    "fgcz_header_quarto.html",
    "fgcz-plot-finder.html"
  )

  paths <- fgcz_copy_assets(dir)

  expect_setequal(basename(paths), expected_files)
  expect_equal(file.exists(paths), rep(TRUE, length(paths)))
  expect_equal(dirname(paths), rep(normalizePath(dir), length(paths)))
})

test_that("fgcz_copy_assets accepts a qmd file path", {
  dir <- tempfile()
  dir.create(dir)
  qmd <- file.path(dir, "report.qmd")
  expect_equal(file.create(qmd), TRUE)

  paths <- fgcz_copy_assets(qmd)

  expect_equal(file.exists(paths), rep(TRUE, length(paths)))
  expect_equal(dirname(paths), rep(normalizePath(dir), length(paths)))
})

test_that("fgcz_use_template copies the report skeleton and visual abstract", {
  dir <- tempfile()

  qmd <- fgcz_use_template(dir, to = "report.qmd")

  expect_equal(qmd, file.path(dir, "report.qmd"))
  expect_equal(
    file.exists(file.path(dir, "fgcz-report-overview.svg")),
    TRUE
  )
})

test_that("the starter follows the required analysis-report layout", {
  qmd <- trimws(readLines(fgcz_quarto_dir("template.qmd"), warn = FALSE))
  top_level <- grep("^# ", qmd, value = TRUE)
  session_info <- match("# Session Info", qmd)
  session_subtabs <- grep(
    "^## ",
    qmd[session_info:length(qmd)],
    value = TRUE
  )

  expect_equal(top_level[[1]], "# Overview")
  expect_equal(tail(top_level, 1), "# Session Info")
  expect_equal(
    session_subtabs,
    c("## Report provenance", "## R session info")
  )
  expect_equal(any(grepl("fgcz-report-overview.svg", qmd, fixed = TRUE)), TRUE)
})

test_that("fgcz_copy_assets rejects non-qmd file paths", {
  dir <- tempfile()
  dir.create(dir)
  txt <- file.path(dir, "report.txt")
  expect_equal(file.create(txt), TRUE)

  expect_snapshot(error = TRUE, fgcz_copy_assets(txt))
})

test_that("toolbar button selections preserve logical compatibility", {
  validate <- fgczQuartoTemplate:::.fgcz_validate_buttons

  expect_identical(validate(NULL), character(0))
  expect_identical(validate(FALSE), character(0))
  expect_identical(validate(TRUE), c("search", "download", "source"))
  expect_identical(validate(character(0)), character(0))
  expect_identical(validate("search"), "search")
  expect_identical(validate("download"), "download")
  expect_identical(validate("source"), "source")
  expect_identical(
    validate(c("download", "search", "search")),
    c("search", "download")
  )
  expect_identical(
    validate(c("source", "search")),
    c("search", "source")
  )
})

test_that("toolbar button selections reject invalid values", {
  validate <- fgczQuartoTemplate:::.fgcz_validate_buttons

  expect_snapshot(error = TRUE, validate(NA))
  expect_snapshot(error = TRUE, validate(c(TRUE, FALSE)))
  expect_snapshot(error = TRUE, validate(1L))
  expect_snapshot(error = TRUE, validate("bogus"))
  expect_snapshot(error = TRUE, validate(c("search", "bogus")))
})

test_that("staged toolbar receives the selected button names", {
  tmp <- tempfile(fileext = ".html")
  writeLines('var buttons = "__FGCZ_BUTTONS__";', tmp)

  fgczQuartoTemplate:::.fgcz_set_toolbar_buttons(
    tmp,
    c("search", "download", "source")
  )

  patched <- paste(readLines(tmp, warn = FALSE), collapse = "\n")
  expect_equal(grepl("__FGCZ_BUTTONS__", patched, fixed = TRUE), FALSE)
  expect_equal(grepl('"search download source"', patched, fixed = TRUE), TRUE)
})

test_that("feature flags map to the classes they add, in canonical order", {
  validate <- fgczQuartoTemplate:::.fgcz_validate_flags

  expect_identical(validate(colour = FALSE, number = FALSE), character(0))
  expect_identical(validate(colour = TRUE, number = FALSE), "fgcz-colour")
  expect_identical(validate(colour = FALSE, number = TRUE), "fgcz-number")
  expect_identical(validate(full_width = TRUE), "fgcz-full-width")
  # Canonical order, not argument order.
  expect_identical(
    validate(number = TRUE, colour = TRUE),
    c("fgcz-colour", "fgcz-number")
  )
  expect_identical(
    validate(full_width = TRUE, number = TRUE, colour = TRUE),
    c("fgcz-colour", "fgcz-number", "fgcz-full-width")
  )
})

test_that("feature flags reject non-logical values", {
  validate <- fgczQuartoTemplate:::.fgcz_validate_flags

  expect_error(validate(colour = NA), "`colour` must be a single TRUE or FALSE")
  expect_error(validate(number = "yes"), "`number` must be a single TRUE or FALSE")
  expect_error(
    validate(colour = c(TRUE, FALSE)),
    "`colour` must be a single TRUE or FALSE"
  )
})

test_that("staged header receives the enabled feature classes", {
  tmp <- tempfile(fileext = ".html")
  writeLines('var flags = "__FGCZ_FLAGS__";', tmp)

  fgczQuartoTemplate:::.fgcz_set_header_flags(
    tmp,
    c("fgcz-colour", "fgcz-number")
  )

  patched <- paste(readLines(tmp, warn = FALSE), collapse = "\n")
  expect_equal(grepl("__FGCZ_FLAGS__", patched, fixed = TRUE), FALSE)
  expect_equal(grepl('"fgcz-colour fgcz-number"', patched, fixed = TRUE), TRUE)
})

test_that("the packaged header carries exactly one flag placeholder", {
  # The self-detection in the header's own JS splits the token across a
  # concatenation on purpose; if someone "tidies" that into a single literal,
  # or repeats the token in prose, patching must fail loudly rather than pick
  # an arbitrary occurrence.
  header <- fgcz_quarto_dir("fgcz_header_quarto.html")
  html <- paste(readLines(header, warn = FALSE), collapse = "\n")
  hits <- gregexpr("__FGCZ_FLAGS__", html, fixed = TRUE)[[1]]

  expect_equal(length(hits), 1L)
  expect_false(identical(hits, -1L))
})

test_that("fgcz_render applies the colour and numbering flags", {
  testthat::skip_if_not(quarto::quarto_available())
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  qmd <- file.path(dir, "report.qmd")
  writeLines(
    c(
      "---",
      'title: "Flag test"',
      "---",
      "",
      "::: {.panel-tabset}",
      "",
      "# One",
      "",
      "a",
      "",
      "# Two",
      "",
      "b",
      "",
      ":::"
    ),
    qmd
  )
  output <- file.path(dir, "report.html")

  # Default: the placeholder is left intact, so the assets stay inert.
  fgcz_render(qmd, quiet = TRUE)
  html <- paste(readLines(output, warn = FALSE), collapse = "\n")
  expect_equal(grepl("__FGCZ_FLAGS__", html, fixed = TRUE), TRUE)

  fgcz_render(qmd, colour = TRUE, number = TRUE, quiet = TRUE)
  html <- paste(readLines(output, warn = FALSE), collapse = "\n")
  expect_equal(
    grepl('var flags = "fgcz-colour fgcz-number"', html, fixed = TRUE),
    TRUE
  )

  # Re-staging restores the placeholder, so a later render is not stuck with an
  # earlier selection.
  fgcz_render(qmd, colour = TRUE, quiet = TRUE)
  html <- paste(readLines(output, warn = FALSE), collapse = "\n")
  expect_equal(grepl('var flags = "fgcz-colour"', html, fixed = TRUE), TRUE)

  # The header must be included exactly once: Quarto merges include-in-header
  # rather than replacing it, so a stray override would duplicate the banner.
  expect_equal(
    length(gregexpr('class="fgcz-banner"', html, fixed = TRUE)[[1]]),
    1L
  )
})

test_that("the Quarto filter reads the colour and numbering keys", {
  testthat::skip_if_not(quarto::quarto_available())
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  file.copy(fgcz_quarto_dir("fgcz-buttons.lua"), dir)
  qmd <- file.path(dir, "flags.qmd")
  writeLines(
    c(
      "---",
      'title: "Flags"',
      "format: html",
      "filters: [fgcz-buttons.lua]",
      "fgcz-colour: true",
      "fgcz-number: true",
      "---",
      "",
      "Report body."
    ),
    qmd
  )

  quarto::quarto_render(qmd, quiet = TRUE)
  html <- paste(
    readLines(file.path(dir, "flags.html"), warn = FALSE),
    collapse = "\n"
  )

  expect_match(
    html,
    'classList.add("fgcz-colour","fgcz-number")',
    fixed = TRUE
  )
})

test_that("the Quarto filter leaves the feature classes alone by default", {
  testthat::skip_if_not(quarto::quarto_available())
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  file.copy(fgcz_quarto_dir("fgcz-buttons.lua"), dir)
  qmd <- file.path(dir, "noflags.qmd")
  writeLines(
    c("---", 'title: "No flags"', "format: html", "filters: [fgcz-buttons.lua]", "---", "", "Report body."),
    qmd
  )

  quarto::quarto_render(qmd, quiet = TRUE)
  html <- paste(
    readLines(file.path(dir, "noflags.html"), warn = FALSE),
    collapse = "\n"
  )

  expect_false(grepl('classList.add("fgcz-', html, fixed = TRUE))
})

test_that("fgcz_render supports logical and named toolbar selections", {
  testthat::skip_if_not(quarto::quarto_available())
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  qmd <- file.path(dir, "report.qmd")
  writeLines(c("---", 'title: "Toolbar test"', "---", "", "Body."), qmd)
  output <- file.path(dir, "report.html")

  fgcz_render(qmd, buttons = FALSE, quiet = TRUE)
  html <- paste(readLines(output, warn = FALSE), collapse = "\n")
  expect_equal(grepl("fgcz-pf-toolbar", html, fixed = TRUE), FALSE)

  fgcz_render(qmd, buttons = TRUE, quiet = TRUE)
  html <- paste(readLines(output, warn = FALSE), collapse = "\n")
  expect_equal(grepl("fgcz-pf-toolbar", html, fixed = TRUE), TRUE)
  expect_equal(
    grepl('FGCZ_BUTTONS = "search download source"', html, fixed = TRUE),
    TRUE
  )

  fgcz_render(qmd, buttons = "search", quiet = TRUE)
  html <- paste(readLines(output, warn = FALSE), collapse = "\n")
  expect_equal(grepl('FGCZ_BUTTONS = "search"', html, fixed = TRUE), TRUE)

  fgcz_render(qmd, buttons = "source", quiet = TRUE)
  html <- paste(readLines(output, warn = FALSE), collapse = "\n")
  expect_equal(grepl('FGCZ_BUTTONS = "source"', html, fixed = TRUE), TRUE)
})

test_that("the Quarto filter rejects unknown button names", {
  testthat::skip_if_not(quarto::quarto_available())
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  file.copy(fgcz_quarto_dir("fgcz-buttons.lua"), dir)
  qmd <- file.path(dir, "invalid-buttons.qmd")
  writeLines(
    c(
      "---",
      'title: "Invalid buttons"',
      "format: html",
      "filters: [fgcz-buttons.lua]",
      "fgcz-buttons: bogus",
      "---",
      "",
      "Report body."
    ),
    qmd
  )

  output <- suppressWarnings(
    system2(
      quarto::quarto_path(),
      c("render", shQuote(qmd)),
      stdout = TRUE,
      stderr = TRUE
    )
  )

  expect_equal(attr(output, "status"), 1L)
  expect_match(
    paste(output, collapse = "\n"),
    "Unknown fgcz-buttons value(s): bogus. Valid values are: search, download, source.",
    fixed = TRUE
  )
})

# Minimal base64 decoder (base R only, no new package dependency): the PNG
# IHDR chunk with width/height always sits in the first 24 bytes, so decoding
# a short prefix of the (possibly huge) embedded image is enough.
.base64_decode_prefix <- function(s, n_bytes) {
  n_chars <- ceiling(n_bytes / 3) * 4L
  s <- substr(s, 1L, min(nchar(s), n_chars))
  alphabet <- c(LETTERS, letters, as.character(0:9), "+", "/")
  lookup <- stats::setNames(0:63, alphabet)
  vals <- lookup[strsplit(s, "")[[1]]]
  bits <- unlist(lapply(vals, function(v) bitwAnd(bitwShiftR(v, 5:0), 1L)))
  nbytes <- length(bits) %/% 8L
  as.raw(vapply(
    seq_len(nbytes),
    function(i) {
      b <- bits[((i - 1) * 8 + 1):(i * 8)]
      sum(b * 2^(7:0))
    },
    numeric(1)
  ))
}

# Read width/height (pixels) from a PNG's IHDR chunk: 8-byte signature, then
# a 4-byte length + 4-byte "IHDR" type, then width/height as big-endian uint32.
.png_dims <- function(raw) {
  con <- rawConnection(raw)
  on.exit(close(con))
  seek(con, 16)
  c(
    width = readBin(con, "integer", n = 1L, size = 4L, endian = "big"),
    height = readBin(con, "integer", n = 1L, size = 4L, endian = "big")
  )
}

# The last base64-embedded PNG in a self-contained render is the plot (the
# FGCZ banner logo, embedded via the header, always comes first).
.last_embedded_png_dims <- function(html_path) {
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  m <- gregexpr("data:image/png;base64,[A-Za-z0-9+/=]+", html)
  all_matches <- regmatches(html, m)[[1]]
  b64 <- sub("^data:image/png;base64,", "", all_matches[length(all_matches)])
  .png_dims(.base64_decode_prefix(b64, 24L))
}

test_that("fgcz_render honors fig_dpi and fig_retina overrides", {
  testthat::skip_if_not(quarto::quarto_available())
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  qmd <- file.path(dir, "report.qmd")
  writeLines(
    c(
      "---",
      'title: "DPI test"',
      "---",
      "",
      "```{r}",
      "#| fig-cap: test",
      "plot(1:10)",
      "```"
    ),
    qmd
  )

  fgcz_render(qmd, output_file = "override.html", quiet = TRUE, fig_dpi = 72, fig_retina = 1)
  dims <- .last_embedded_png_dims(file.path(dir, "override.html"))

  # _metadata.yml sets knitr fig.width/fig.height to 6in x 5in.
  expect_equal(unname(dims["width"]), 6L * 72L)
  expect_equal(unname(dims["height"]), 5L * 72L)
})

test_that("fgcz_render validates fig_dpi and fig_retina", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  qmd <- file.path(dir, "report.qmd")
  writeLines(c("---", 'title: "Invalid"', "---", "", "Body."), qmd)

  expect_error(fgcz_render(qmd, fig_dpi = "150", quiet = TRUE), "`fig_dpi`")
  expect_error(fgcz_render(qmd, fig_dpi = -1, quiet = TRUE), "`fig_dpi`")
  expect_error(fgcz_render(qmd, fig_dpi = c(150, 300), quiet = TRUE), "`fig_dpi`")
  expect_error(fgcz_render(qmd, fig_retina = 0, quiet = TRUE), "`fig_retina`")
})

test_that("the Quarto filter injects and normalizes a valid button list", {
  testthat::skip_if_not(quarto::quarto_available())
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  file.copy(fgcz_quarto_dir("fgcz-buttons.lua"), dir)
  qmd <- file.path(dir, "download-button.qmd")
  writeLines(
    c(
      "---",
      'title: "Download button"',
      "format: html",
      "filters: [fgcz-buttons.lua]",
      "fgcz-buttons: [download, search, search]",
      "---",
      "",
      "Report body."
    ),
    qmd
  )

  quarto::quarto_render(qmd, quiet = TRUE)
  html <- paste(
    readLines(file.path(dir, "download-button.html"), warn = FALSE),
    collapse = "\n"
  )

  expect_match(
    html,
    'window.FGCZ_BUTTONS = ["search","download"]',
    fixed = TRUE
  )
})

test_that("the Quarto filter accepts the source button, canonically ordered", {
  testthat::skip_if_not(quarto::quarto_available())
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  file.copy(fgcz_quarto_dir("fgcz-buttons.lua"), dir)
  qmd <- file.path(dir, "source-button.qmd")
  writeLines(
    c(
      "---",
      'title: "Source button"',
      "format: html",
      "filters: [fgcz-buttons.lua]",
      "fgcz-buttons: [source, search]",
      "---",
      "",
      "Report body."
    ),
    qmd
  )

  quarto::quarto_render(qmd, quiet = TRUE)
  html <- paste(
    readLines(file.path(dir, "source-button.html"), warn = FALSE),
    collapse = "\n"
  )

  expect_match(
    html,
    'window.FGCZ_BUTTONS = ["search","source"]',
    fixed = TRUE
  )
})

test_that("plot finder downloads use report metadata and current timestamps", {
  toolbar <- paste(
    readLines(fgcz_quarto_dir("fgcz-plot-finder.html"), warn = FALSE),
    collapse = "\n"
  )

  expect_match(toolbar, "top: 107px; right: .75rem", fixed = TRUE)
  expect_match(toolbar, "flex-direction: row", fixed = TRUE)
  # Icon-only controls: no visible text label on either button, and no CSS that
  # reveals one on hover or focus.
  expect_false(grepl('class="lbl">Find', toolbar, fixed = TRUE))
  expect_false(grepl('class="lbl">Download', toolbar, fixed = TRUE))
  expect_false(grepl('class="lbl">View source', toolbar, fixed = TRUE))
  expect_false(grepl(".fgcz-pf-toolbar .lbl", toolbar, fixed = TRUE))
  # The icons must still announce themselves to tooltips and screen readers,
  # which is the whole reason dropping the visible label is acceptable.
  expect_match(toolbar, 'aria-label="Find figures and tables"', fixed = TRUE)
  expect_match(toolbar, 'aria-label="Download plots"', fixed = TRUE)
  expect_match(toolbar, 'aria-label="View source"', fixed = TRUE)
  expect_match(toolbar, "positionToolbar", fixed = TRUE)
  # The view-source button drives Quarto's own machinery rather than
  # reimplementing a source viewer, trying each hook Quarto might have emitted
  # in turn, and is dropped when none of them exist.
  expect_match(toolbar, "getElementById('fgcz-src-btn')", fixed = TRUE)
  expect_match(toolbar, "getElementById('quarto-view-source')", fixed = TRUE)
  expect_match(toolbar, "querySelector('.code-tools-button')", fixed = TRUE)
  expect_match(toolbar, "var hasSource", fixed = TRUE)
  # Manual include (no fgcz_render() patching, no Lua filter) falls back to
  # showing all three buttons -- this literal regressed to two when the
  # source button was added and only the R/Lua defaults were updated.
  expect_match(
    toolbar,
    'FGCZ_BUTTONS = ["search", "download", "source"]',
    fixed = TRUE
  )
  # Whole-report extras alongside the per-plot gallery: the qmd source Quarto
  # embeds under code-tools, and a standalone snapshot of the page.
  expect_match(toolbar, 'data-what="qmd"', fixed = TRUE)
  expect_match(toolbar, 'data-what="html"', fixed = TRUE)
  expect_match(toolbar, "quarto-embedded-source-code-modal", fixed = TRUE)
  expect_match(toolbar, "function htmlSnapshot", fixed = TRUE)
  # An unavailable extra is disabled with a reason rather than yielding an
  # empty file.
  expect_match(toolbar, "Source not embedded (needs code-tools: true)", fixed = TRUE)
  # The extras carry a DIFFERENT checkbox class from the gallery. That is what
  # keeps "Select all plots" from silently ticking the qmd and html rows, so if
  # the classes are ever unified this test should fail.
  expect_match(toolbar, 'class="fgcz-dl-extra"', fixed = TRUE)
  expect_match(toolbar, "dlListEl.querySelectorAll('.fgcz-dl-cb')", fixed = TRUE)
  # Plots are foldered only when an extra shares the ZIP, so a plots-only
  # download keeps its historic flat layout.
  expect_match(toolbar, "'plots/' : ''", fixed = TRUE)
  expect_match(toolbar, "fgcz-report-metadata", fixed = TRUE)
  expect_match(toolbar, "'order_' + orderId", fixed = TRUE)
  expect_match(toolbar, "'workunit_' + workunitId", fixed = TRUE)
  expect_match(toolbar, "timestampForFilename(new Date())", fixed = TRUE)
  expect_match(toolbar, "zipDosDateTime", fixed = TRUE)
  expect_match(toolbar, "u16(stamp.time), u16(stamp.date)", fixed = TRUE)
})

test_that("the Find panel can locate a labelled chunk in the embedded source", {
  toolbar <- paste(
    readLines(fgcz_quarto_dir("fgcz-plot-finder.html"), warn = FALSE),
    collapse = "\n"
  )

  expect_match(toolbar, "function crossrefIdFor", fixed = TRUE)
  expect_match(toolbar, "function chunkRangeForId", fixed = TRUE)
  expect_match(toolbar, "function showChunkForId", fixed = TRUE)
  expect_match(toolbar, ".fgcz-toc-code {", fixed = TRUE)
  expect_match(toolbar, "codeBtn.className = 'fgcz-toc-code'", fixed = TRUE)
  expect_match(toolbar, "fgcz-src-hl", fixed = TRUE)
  # Quarto puts the crossref id on an ancestor div, never on the <figure>
  # element itself that buildIndex() indexes -- crossrefIdFor() must look
  # there, not at el.id directly, or every item resolves to no id and the
  # button never appears for anyone.
  expect_match(toolbar, '[id^="fig-"], [id^="tbl-"]', fixed = TRUE)
  # Same action also surfaced inline on the figure/table itself, not just in
  # the Find panel.
  expect_match(toolbar, "function decorateInlineCode", fixed = TRUE)
  expect_match(toolbar, ".fgcz-inline-code {", fixed = TRUE)
  expect_match(toolbar, "badge.className = 'fgcz-inline-code'", fixed = TRUE)
  expect_match(toolbar, "decorateInlineCode();", fixed = TRUE)
})

test_that("a labelled chunk's crossref id and source both resolve as the JS expects", {
  testthat::skip_if_not(quarto::quarto_available())
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  qmd <- file.path(dir, "showcode.qmd")
  writeLines(
    c(
      "---",
      'title: "Show code test"',
      "---",
      "",
      "```{r}",
      "#| label: fig-alpha",
      '#| fig-cap: "Alpha"',
      "plot(1:10)",
      "```",
      "",
      "```{r}",
      '#| fig-cap: "Beta, unlabelled"',
      "plot(10:1)",
      "```"
    ),
    qmd
  )

  fgcz_render(
    qmd,
    buttons = TRUE,
    quiet = TRUE,
    metadata = list(`code-tools` = TRUE)
  )
  html <- paste(
    readLines(file.path(dir, "showcode.html"), warn = FALSE),
    collapse = "\n"
  )

  # The labelled chunk gets exactly this crossref id -- the precondition
  # crossrefIdFor()/chunkRangeForId() rely on to show the button for Alpha
  # and nothing for the unlabelled Beta chunk. (Quarto also stamps a
  # "fig-alpha-caption-<uuid>" id on the figcaption itself, hence matching
  # the exact id rather than counting every "fig-"-prefixed id in the page.)
  expect_equal(length(gregexpr('id="fig-alpha"', html, fixed = TRUE)[[1]]), 1L)
  # That id sits on an ancestor of <figure>, not on <figure> itself.
  expect_false(grepl('<figure[^>]*id="fig-alpha"', html))
  # The label chunk option survives verbatim into the embedded source text
  # chunkRangeForId() searches.
  expect_match(html, "label: fig-alpha", fixed = TRUE)
})
