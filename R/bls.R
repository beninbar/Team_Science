library(dplyr)
library(tidyr)
library(ggplot2)


github_url <- "https://raw.githubusercontent.com/Anthogonyst/Team_Science/andrew-dev/data/bls_occupational_wage_data.csv"

df <- read.csv(github_url)

head(df)

#df %>% filter(OCC_TITLE=="Data Scientists")
df$A_MEAN <- as.double(df$A_MEAN)
df$A_MEDIAN <- as.double(df$A_MEDIAN)

ds_data <- df %>% filter(OCC_TITLE=="Data Scientists")
ds_mean_salary <- ds_data$A_MEAN[[1]][1]
ds_median_salary <- ds_data$A_MEDIAN[[1]][1]

# Taking a quick look at the distributon of mean and median annual salaries across all occupations
a_mean_dist <- ggplot(df, aes(x=A_MEAN)) + geom_histogram() + geom_vline(xintercept=ds_mean_salary) + annotate(label="Average DS salary")
a_mean_dist

a_median_dist <- ggplot(df, aes(x=A_MEDIAN)) + geom_histogram() + geom_vline(aes(xintercept=ds_median_salary))
a_median_dist

a_mean_box <- ggplot(df, aes(x=A_MEAN)) + geom_boxplot()
a_mean_box

a_median_box <- ggplot(df, aes(x=A_MEDIAN)) + geom_boxplot()
a_median_box
  