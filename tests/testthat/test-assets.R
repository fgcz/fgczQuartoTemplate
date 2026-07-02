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

test_that("fgcz_copy_assets rejects non-qmd file paths", {
  dir <- tempfile()
  dir.create(dir)
  txt <- file.path(dir, "report.txt")
  expect_equal(file.create(txt), TRUE)

  expect_snapshot(error = TRUE, fgcz_copy_assets(txt))
})

test_that("fgcz_render rejects a non-scalar-logical buttons", {
  # The buttons check runs before the quarto / file-existence checks, so this
  # needs neither quarto installed nor a real .qmd.
  expect_error(fgcz_render("x.qmd", buttons = "yes"), "single TRUE or FALSE")
  expect_error(
    fgcz_render("x.qmd", buttons = c(TRUE, FALSE)),
    "single TRUE or FALSE"
  )
  expect_error(fgcz_render("x.qmd", buttons = NA), "single TRUE or FALSE")
})
