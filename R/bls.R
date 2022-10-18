library(httr)
library(jsonlite)

api_url <- "https://api.bls.gov/publicAPI/v2/timeseries/popular?survey=OE"

response <- httr:GET(api_url)

print(response)


