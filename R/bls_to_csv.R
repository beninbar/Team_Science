library(httr)
library(jsonlite)
library(glue)
library(rvest)
library(readxl)


# Downloaded from here: https://www.bls.gov/oes/current/oes_nat.htm
# Uploaded to GitHub for reproducability
data_url <- '~/andrewbowen/Team_Science/data/bls_occupational_wage_data.xlsx'

df <- readxl::read_excel(path=data_url)

df
