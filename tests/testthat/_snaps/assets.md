# fgcz_copy_assets rejects non-qmd file paths

    Code
      fgcz_copy_assets(txt)
    Condition
      Error:
      ! `path` must be a single directory or a path to a .qmd file.

# toolbar button selections reject invalid values

    Code
      validate(NA)
    Condition
      Error:
      ! `buttons` must be a single TRUE or FALSE, NULL, or a character vector containing only "search", "download", and/or "source".

---

    Code
      validate(c(TRUE, FALSE))
    Condition
      Error:
      ! `buttons` must be a single TRUE or FALSE, NULL, or a character vector containing only "search", "download", and/or "source".

---

    Code
      validate(1L)
    Condition
      Error:
      ! `buttons` must be a single TRUE or FALSE, NULL, or a character vector containing only "search", "download", and/or "source".

---

    Code
      validate("bogus")
    Condition
      Error:
      ! Unknown toolbar button name(s): bogus. Valid names are: search, download, source.

---

    Code
      validate(c("search", "bogus"))
    Condition
      Error:
      ! Unknown toolbar button name(s): bogus. Valid names are: search, download, source.

