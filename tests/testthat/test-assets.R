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
    c("search", "download")
  )

  patched <- paste(readLines(tmp, warn = FALSE), collapse = "\n")
  expect_equal(grepl("__FGCZ_BUTTONS__", patched, fixed = TRUE), FALSE)
  expect_equal(grepl('"search download"', patched, fixed = TRUE), TRUE)
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
  expect_match(toolbar, '<span class="lbl">Find</span>', fixed = TRUE)
  expect_match(toolbar, '<span class="lbl">Download</span>', fixed = TRUE)
  expect_match(toolbar, "button:hover .lbl", fixed = TRUE)
  expect_match(toolbar, "button:focus-visible .lbl", fixed = TRUE)
  expect_match(toolbar, "positionToolbar", fixed = TRUE)
  expect_match(toolbar, "fgcz-report-metadata", fixed = TRUE)
  expect_match(toolbar, "'order_' + orderId", fixed = TRUE)
  expect_match(toolbar, "'workunit_' + workunitId", fixed = TRUE)
  expect_match(toolbar, "timestampForFilename(new Date())", fixed = TRUE)
  expect_match(toolbar, "zipDosDateTime", fixed = TRUE)
  expect_match(toolbar, "u16(stamp.time), u16(stamp.date)", fixed = TRUE)
})
