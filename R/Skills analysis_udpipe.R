# Use the udpipe library to tokenize/tag our words.
# install.packages("udpipe")
library(udpipe)
library(jsonlite)
library(tidyverse)
library(ggplot2)

# Read in scraped LinkedIn json.
linkedin <- read_json("https://raw.githubusercontent.com/Anthogonyst/Team_Science/master/data/job_description_data.json", simplifyVector=TRUE)

# We want to target 'job_bullets' since this is the field most likely to have skills.
bullets <- linkedin["job_bullets"]

# Download "english" for the udpipe and load.
english <- udpipe_download_model(language = "english")
str(english)
model <- udpipe_load_model(file = "english-ewt-ud-2.5-191206.udpipe")

linkedin$job_bullets

# Annotate job_bullets and pull word counts into dataframe. If job_bullets empty, use job_paragraphs as alternative. Add all data to a list.
count = 1
dflist <- list()
for (vec in linkedin$job_bullets) {
  if (length(vec) != 0) {
    annotated <- udpipe_annotate(model, vec)
    df_annotated <- data.frame(annotated)
    freqs <- txt_freq(df_annotated$token)
    dflist[[count]] <- freqs[-c(3)]
  }
  else {
    annotated <- udpipe_annotate(model, linkedin$job_paragraphs[[count]])
    df_annotated <- data.frame(annotated)
    freqs <- txt_freq(df_annotated$token)
    dflist[[count]] <- freqs[-c(3)]
  }
  count = count + 1
}

# Join lists into one big dataframe. Get row sums and delete extraneous columns.
#dflist
bigdata <- dflist |> reduce(full_join, by='key')
bigdata <- bigdata |> mutate(count=rowSums(bigdata[,2:24], na.rm=TRUE))
bigdata <- bigdata[-c(2:24)]

# Filter out to graph data in ggplot.
filtered <- bigdata |> arrange(desc(count)) |> filter(count>4) |> filter(count<50) |> slice(1:40)
ggplot(data=filtered, aes(x=count, y=key)) +
  geom_bar(stat="identity", position="dodge", fill='#3590ae') +
  ggtitle("Top skills on LinkedIn") +
  theme(axis.title.y=element_blank())
