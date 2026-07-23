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
  validate <- fgczquartotemplate:::.fgcz_validate_buttons

  expect_identical(validate(NULL), character(0))
  expect_identical(validate(FALSE), character(0))
  expect_identical(validate(TRUE), c("search", "download"))
  expect_identical(validate(character(0)), character(0))
  expect_identical(validate("search"), "search")
  expect_identical(validate("download"), "download")
  expect_identical(
    validate(c("download", "search", "search")),
    c("search", "download")
  )
})

test_that("toolbar button selections reject invalid values", {
  validate <- fgczquartotemplate:::.fgcz_validate_buttons

  expect_snapshot(error = TRUE, validate(NA))
  expect_snapshot(error = TRUE, validate(c(TRUE, FALSE)))
  expect_snapshot(error = TRUE, validate(1L))
  expect_snapshot(error = TRUE, validate("bogus"))
  expect_snapshot(error = TRUE, validate(c("search", "bogus")))
})

test_that("staged toolbar receives the selected button names", {
  tmp <- tempfile(fileext = ".html")
  writeLines('var buttons = "__FGCZ_BUTTONS__";', tmp)

  fgczquartotemplate:::.fgcz_set_toolbar_buttons(
    tmp,
    c("search", "download")
  )

  patched <- paste(readLines(tmp, warn = FALSE), collapse = "\n")
  expect_equal(grepl("__FGCZ_BUTTONS__", patched, fixed = TRUE), FALSE)
  expect_equal(grepl('"search download"', patched, fixed = TRUE), TRUE)
})

test_that("feature flags map to the classes they add, in canonical order", {
  validate <- fgczquartotemplate:::.fgcz_validate_flags

  expect_identical(validate(colour = FALSE, number = FALSE), character(0))
  expect_identical(validate(colour = TRUE, number = FALSE), "fgcz-colour")
  expect_identical(validate(colour = FALSE, number = TRUE), "fgcz-number")
  # Canonical order, not argument order.
  expect_identical(
    validate(number = TRUE, colour = TRUE),
    c("fgcz-colour", "fgcz-number")
  )
})

test_that("feature flags reject non-logical values", {
  validate <- fgczquartotemplate:::.fgcz_validate_flags

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

  fgczquartotemplate:::.fgcz_set_header_flags(
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
    c("---", 'title: "Flag test"', "---", "", "::: {.panel-tabset}", "",
      "# One", "", "a", "", "# Two", "", "b", "", ":::"),
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
    c("---", 'title: "No flags"', "format: html", "filters: [fgcz-buttons.lua]",
      "---", "", "Report body."),
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
    grepl('FGCZ_BUTTONS = "search download"', html, fixed = TRUE),
    TRUE
  )

  fgcz_render(qmd, buttons = "search", quiet = TRUE)
  html <- paste(readLines(output, warn = FALSE), collapse = "\n")
  expect_equal(grepl('FGCZ_BUTTONS = "search"', html, fixed = TRUE), TRUE)
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
    "Unknown fgcz-buttons value(s): bogus. Valid values are: search, download.",
    fixed = TRUE
  )
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
  expect_false(grepl(".fgcz-pf-toolbar .lbl", toolbar, fixed = TRUE))
  # The icons must still announce themselves to tooltips and screen readers,
  # which is the whole reason dropping the visible label is acceptable.
  expect_match(toolbar, 'aria-label="Find figures and tables"', fixed = TRUE)
  expect_match(toolbar, 'aria-label="Download plots"', fixed = TRUE)
  expect_match(toolbar, "positionToolbar", fixed = TRUE)
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
