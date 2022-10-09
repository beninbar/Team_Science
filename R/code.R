#' This function reads the data files within the data repository.
#'
#' @param name The name of the file from the data/ folder
#' @examples
#' \dontrun{
#'
#' testData = ReadFile("data.csv")
#' }
#' @author Anthogonyst
#' @export
ReadFile <- function(name) {
  read.csv(paste0("data/", name), row.names = FALSE)
}
