

testthat::test_that("Check database loads keywords correctly", {
  
  job = jsonlite::read_json("data/job_description_data.json")
  jobIdVector = paste0("linkedin_", 1:length(job))
  writeFiles = rep("data/test/", length(jobIdVector))
  captureGroups = c("n.", "a.", "v.")
  dictionary = "data/dictionary.json" %>%
    readLines(.) %>%
      jsonlite::fromJSON(.)
  
  dir.create("data/test/")
  lhs = GenerateKeywords(jobs = job, jobIds = jobIdVector, writeCsv = writeFiles, 
                         webster = dictionary, captures = captureGroups, FUN = GrabLinkedin)
  
  rhs = LoadKeywordDatabase("data/test/")
  
  list.files("data/test", no.. = TRUE, all.files = TRUE, full.names = TRUE) %>%
    sapply(file.remove)
  file.remove("data/test/")
  
  testthat::expect_equivalent(SumFreq(lhs), SumFreq(rhs))
})

testthat::test_that("Check dictionary is correctly saved", {
  lhs = "data/dictionary.json" %>%
    readLines(.) %>%
      jsonlite::fromJSON(.)
  
  rhs = "https://github.com/ssvivian/WebstersDictionary/raw/master/dictionary.json" %>%
    readLines(.) %>%
      jsonlite::fromJSON(.)
  
  testthat::expect_equal(lhs, rhs)
})

testthat::test_that("Check code salinity for nested keyword function", {
  sampleData = list(list("Clifford is The big"), list("red dog"))
  expectedData = list(c("CLIFFORD", "IS", "THE", "BIG"), c("RED", "DOG"))
  
  sampleFunction <- function(x) {
    unlist(strsplit(toupper(x), "\\s"))
  }
  
  RunnerMulti <- function(inputData, testFUN = sampleFunction) {
    value = mapply(inputData, 1:length(inputData), USE.NAMES = FALSE, FUN = function(x, y) {
      actual = testFUN(x)
      actual
    })
    value
  }
  
  testthat::expect_equal(expectedData, RunnerMulti(sampleData, sampleFunction))
})

testthat::test_that("Check code salinity for single-vector keyword function", {
  sampleData = "Clifford is The big red dog"
  expectedData = list(c("CLIFFORD", "IS","THE", "BIG", "RED", "DOG"))
  
  sampleFunction <- function(x) {
    strsplit(toupper(x), "\\s")
  }
  
  RunnerSingle <- function(inputData, testFUN = sampleFunction) {
    value = mapply(inputData, 1:length(inputData), USE.NAMES = FALSE, FUN = function(x, y) {
      actual = testFUN(x)
      actual
    })
    value
  }
  
  testthat::expect_equal(expectedData, RunnerSingle(sampleData, sampleFunction))
  testthat::expect_equal(expectedData, RunnerSingle(list(sampleData), sampleFunction))
})
