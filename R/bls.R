library(dplyr)
library(tidyr)
library(ggplot2)

# Reading converted csv file
# original data link: https://www.bls.gov/oes/current/oes_nat.htm
github_url <- "https://raw.githubusercontent.com/Anthogonyst/Team_Science/master/data/bls_occupational_wage_data.csv"

df <- read.csv(github_url)

head(df)

# casting to numeric types for aggregation
df$A_MEAN <- as.numeric(df$A_MEAN)
df$A_MEDIAN <- as.numeric(df$A_MEDIAN)


ds_data <- df %>% filter(OCC_TITLE=="Data Scientists")
ds_mean_salary <- ds_data$A_MEAN[[1]][1]
ds_median_salary <- ds_data$A_MEDIAN[[1]][1]

# Quick summary 
df %>% summarise(annual_mean_salary = mean(A_MEAN, na.rm = TRUE),
                 annual_median_salary = median(A_MEDIAN, na.rm = TRUE),
                 ds_annual_mean = ds_mean_salary,
                 ds_annual_median = ds_median_salary)

# Taking a quick look at the distributon of mean and median annual salaries across all occupations
a_mean_dist <- ggplot(df, aes(x=A_MEAN)) + geom_histogram(bins=25) + geom_vline(xintercept=ds_mean_salary)  + ggtitle("Annual Mean Salary: all occupations")
a_mean_dist

a_median_dist <- ggplot(df, aes(x=A_MEDIAN)) + 
  geom_histogram(bins=25) + geom_vline(aes(xintercept=ds_median_salary)) + ggtitle("Annual Median Salary: all occupations")
a_median_dist

a_mean_box <- ggplot(df, aes(x=A_MEAN)) + geom_boxplot() + ggtitle("Annual Mean Salary: all occupations")
a_mean_box

a_median_box <- ggplot(df, aes(x=A_MEDIAN)) + geom_boxplot() + ggtitle("Annual Median Salary: all occupations")
a_median_box








