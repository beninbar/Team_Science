library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)

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
a_mean_dist <- ggplot(df, aes(x=A_MEAN)) + geom_histogram(bins=25) + geom_vline(xintercept=ds_mean_salary) + geom_text(aes(x = ds_mean_salary + 50, label = "Data Science Salary", y=500), angle=90) + ggtitle("Annual Mean Salary: all occupations") + xlab("Annual Mean Salary ($)")
a_mean_dist

a_median_dist <- ggplot(df, aes(x=A_MEDIAN)) + 
  geom_histogram(bins=25) + geom_vline(aes(xintercept=ds_median_salary), show_guide=TRUE) + ggtitle("Annual Median Salary: all occupations") + xlab("Annual Median Salary ($)")
a_median_dist

a_mean_box <- ggplot(df, aes(x=A_MEAN)) + geom_boxplot() + ggtitle("Annual Mean Salary: all occupations") + xlab("Annual Mean Salary ($)")
a_mean_box

a_median_box <- ggplot(df, aes(x=A_MEDIAN)) + geom_boxplot() + ggtitle("Annual Median Salary: all occupations") + xlab("Annual Median Salary ($)")
a_median_box

# Comparing to other occupations that are data-specific
data_salaries <- df %>% filter(str_detect(OCC_TITLE, "(Data)|(Analytics)"))
data_salaries

# Making a box plot of 
# Since these salary distributions aren't symmetric, we'll use median as our measure of center
ggplot(data_salaries, aes(x = OCC_TITLE, y = A_MEDIAN)) + geom_bar(stat='identity') + theme(axis.text  = element_text(angle=90))# + coord_flip()





