# Use the udpipe library to tokenize/tag our words.
# install.packages("udpipe")
library(udpipe)
library(jsonlite)
library(tidyverse)
library(ggplot2)

# Read in scraped Indeed json from Josh.
indeed <- read_json("https://raw.githubusercontent.com/beninbar/Team_Science/master/data/indeed_job_description_data.json", simplifyVector=TRUE)

# We want to target 'job_bullets' since this is the field most likely to have skills. Pulled in 25 job posts.
head(indeed$job_bullets)
length(indeed$job_bullets)

# Download "english" for the udpipe and load.
# english <- udpipe_download_model(language = "english")
# str(english)
model <- udpipe_load_model(file = "english-ewt-ud-2.5-191206.udpipe")

# Annotate job_bullets and pull word counts into dataframe. Target only "NOUNS" and "ADJECTIVES."
# If job_bullets empty, use job_paragraphs as alternative. Add all data to a list.
union_df <- data.frame()
indeed$jobdesc_id <- 1:nrow(indeed)
for(i in 1:nrow(indeed)) {
  if (indeed[i, 'job_bullets'] != 'character(0)') {
    annotated <- udpipe_annotate(model, toupper(indeed[i, 'job_bullets']))
    df_annotated <- data.frame(annotated)
    df_annotated$jobdesc_id <- indeed[i, 'jobdesc_id']
    df_annotated$source <- "Indeed"
    union_df <- union_all(union_df, df_annotated)
  }
  else {
    annotated <- udpipe_annotate(model, toupper(indeed[i, 'job_paragraphs']))
    df_annotated <- data.frame(annotated)
    df_annotated$jobdesc_id <- indeed[i, 'jobdesc_id']
    df_annotated$source <- "Indeed"
    union_df <- union_all(union_df, df_annotated)
  }
}

# Target only "NOUNS", "ADJECTIVES", and "PNOUNS" (proper). Write to csv for downstream relational database.
forSQLdb <- union_df[(union_df$upos=='NOUN' | union_df$upos=='ADJ' | union_df$upos=='PROPN'),]
#write.csv(union_df, "Indeed_tagged.csv")

# Graph data in bar chart. Frequency > 10 is arbitrary but helps us visualize the top.
freqs <- txt_freq(forSQLdb$token)
filtered <- freqs |> filter(freq>10)
ggplot(data=filtered, aes(reorder(key, freq), freq)) +
  geom_bar(stat="identity", position="dodge", fill='#3590ae') +
  ggtitle("Top skills on Indeed - nouns, adjectives") +
  theme(axis.title.y=element_blank()) +
  coord_flip()

# Let's try and see what the RAKE "Rapid Automated Keyword Extraction" protocol of the algorithm gives us. Note this has to be done on the
# full tagged dataframe, not the subsetted. Additionally, we must group by sentence to pull phrases and compare across all phrases.
# RAKE definition: the ratio of the degree to the frequency as explained in the description, summed up for all words from the keyword
keywords <- keywords_rake(x = union_df, term = "token", group = "sentence",
                          relevant = union_df$upos %in% c("NOUN", "ADJ", "PROPN")) |> arrange(desc(rake))
keywords

# Rerun barchart with RAKE algorithm.
filtered <- keywords |> filter(rake>2.2)
ggplot(data=filtered, aes(reorder(keyword, rake), rake)) +
  geom_bar(stat="identity", position="dodge", fill='#3590ae') +
  ggtitle("Top skills on Indeed - RAKE algorithm") +
  theme(axis.title.y=element_blank()) +
  coord_flip()

# install.packages("ggwordcloud")
library(ggwordcloud)

ggplot(keywords, aes(label = keyword, size = rake)) +
  ggtitle("Top skills on Indeed - RAKE algorithm") +
  geom_text_wordcloud() +
  theme_minimal()
