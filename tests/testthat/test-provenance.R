test_that("fgcz_qmd_source_link is empty outside a knitr render", {
  expect_identical(fgcz_qmd_source_link(), "")
})

test_that("fgcz_qmd_source_link links the .qmd when it renders alongside its output", {
  testthat::skip_if_not(quarto::quarto_available())
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  qmd <- file.path(dir, "report.qmd")
  writeLines(
    c(
      "---", 'title: "Qmd link test"', "---", "",
      "```{r}", "#| echo: false", "#| results: asis",
      'cat(fgczQuartoTemplate::fgcz_qmd_source_link())', "```"
    ),
    qmd
  )

  quarto::quarto_render(qmd, quiet = TRUE)
  html <- paste(
    readLines(file.path(dir, "report.html"), warn = FALSE),
    collapse = "\n"
  )

  expect_match(html, '<a href="report.qmd">report.qmd</a>', fixed = TRUE)
})
