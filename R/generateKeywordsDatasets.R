
library(magrittr)
library(jsonlite)
library(dplyr)
library(seqinr)

##### Parameters #####

job = jsonlite::read_json("data/job_description_data.json")
jobIdVector = sapply(job, function(x) { x$link }) %>%
  magrittr::set_names(paste0("linkedin_", 1:length(.)), .)

data.frame(job_id = jobIds, job_url = names(jobIds)) %>%
  write.csv(., "data/keyword-posting-crosswalk.csv", row.names = FALSE)

writeFiles = rep("data/keywords_linkedin/", length(jobIds))


##### Function usage #####

captureGroups = c("n.", "a.", "v.")
dictionary = "https://github.com/ssvivian/WebstersDictionary/raw/master/dictionary.json" %>%
  readLines(.) %>%
    jsonlite::fromJSON(.)


##### Sample runner #####

values = GenerateKeywords(job, jobIdVector, writeFiles, dictionary, captureGroups, GrabLinkedin)


##### Functions #####

#' Defines how to look the Indeed json data and convert to a vector of all capital letters
#' @param x Filepath
#' 
#' @author Anthogonyst
#' @export
GrabLinkedin <- function(x) {
  sapply(x$job_bullets, strsplit, "\\s") %>%
    c(., sapply(x$job_paragraphs, strsplit, "\\s")) %>%
      unlist(.) %>%
        gsub("\\W", "", .) %>%
          toupper(.)
}

#' Generates the keywords frequency list by examining nouns and such
#' @param jobs The filepath to a file, as parsed by @{FUN}
#' @param jobIds The name or id of the file in question
#' @param writeCsv Optionally write a csv file by supplying a filepath
#' @param webster A dictionary that contains the word bank with columns "pos" and "word"
#' @param captures The capture groups from @{webster} in the "pos" column
#' @param FUN Data grabbing function to be defined externally; can simply be read.csv
#' @examples
#' \dontrun{
#' sentence = "The big red dog"
#' Read = function(x) { x }
#' 
#' GenerateKeywords(sentence, "clifford", "data/big-red-dog/", Read)
#' 
#' }
#' @author Anthogonyst
#' @export
GenerateKeywords <- function(jobs, jobIds, writeCsv = NULL, webster = dictionary,
                             captures = captureGroups, FUN = GrabIndeed) {

  DataPull = FUN
  mapply(jobs, jobIds, writeCsv, SIMPLIFY = FALSE, FUN = function(x, y, write) {
    ### Grabs the job bullets and descript for cleaning and sets to all uppercase
    strArr = DataPull(x)
    
    ### Parses the webster dictionary to only one row per word
    # TODO: Add additional checking to preferentially choose from captures (cross join)
    cleanWebster = webster$word %>% 
      duplicated(.) %>% 
        { ! . } %>%
          webster[., ]
  
    ### Joins words based on captures (nouns, adjectives, verbs)
    lookups = dplyr::left_join(as.data.frame(strArr), cleanWebster, by = c(strArr = "word"))
    
    ### Stores relevant indices and removes elements 1 and len(x) if present
    consecWordsIndices = which(lookups$pos %in% captures) %>%
      .[. != 1 & . != length(lookups$pos)]
    
    ### Runs a pipeline to convert indices into words and sentences
    allFoundWords = consecWordsIndices %>%
      split(., cumsum(c(1, diff(.) != 1))) %>%
        ### Grabs consecutive values to make sentences
        sapply(., function(x) {
          trueVal = c(x[[1]] - 1, x, x[[length(x)]] + 1)
          
          ### Chunks into all possible pieces with zero/one slice per group
          sapply(1:length(trueVal), function(piece_size) {
            sapply(1:(length(trueVal) - piece_size + 1), function(num_piece) {
              list(trueVal[(num_piece):(num_piece + piece_size - 1)])
            }, simplify = T)
          }, simplify = T) %>%
            unlist(., recursive = FALSE) %>%
              ### Concatenates the string arrays into sentences
              sapply(., function(x) {
                strArr[x] %>% 
                  paste0(., " ") %>% 
                    seqinr::c2s(.) %>% 
                      trimws(.)
              })
        }) %>%
          unlist(., recursive = FALSE)
    
    ### Creates and returns the final data frame with the necessary deduping
    result = data.frame(id = y, keyword = allFoundWords) %>%
      # Yes, the double negative is necessary because capturing NA is intentional here
      dplyr::filter(! keyword %in% cleanWebster[! cleanWebster$pos %in% captures, ]$word) %>%
        dplyr::group_by(keyword) %>%
          dplyr::add_count() %>%
            dplyr::rename(frequency = n) %>%
              .[! duplicated(.),] %>%
                dplyr::arrange(desc(frequency))
    
    if (! is.null(write)) {
      filename = paste0(write, y, ".csv")
      
      if (! file.exists(filename)) {
        write.csv(result, filename, row.names = FALSE, quote = TRUE)
      } else {
        print("Skipping existing file:")
        print(filename)
      }
    }
    
    return(result)
  })
}


#####  #####
