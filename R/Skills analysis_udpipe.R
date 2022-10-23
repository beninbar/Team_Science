# Use the udpipe library to tokenize/tag our words.
# install.packages("udpipe")
library(udpipe)
library(jsonlite)
library(tidyverse)
library(ggplot2)

# Read in scraped LinkedIn json.
linkedin <- read_json("https://raw.githubusercontent.com/Anthogonyst/Team_Science/master/data/job_description_data.json", simplifyVector=TRUE)

# We want to target 'job_bullets' since this is the field most likely to have skills. With 'job_paragraphs' in case that field is missing.
head(linkedin$job_bullets)

# Download "english" for the udpipe and load.
# english <- udpipe_download_model(language = "english")
# str(english)
model <- udpipe_load_model(file = "english-ewt-ud-2.5-191206.udpipe")

# Annotate job_bullets and pull word counts into dataframe. Target only "NOUNS" and "ADJECTIVES."
# If job_bullets empty, use job_paragraphs as alternative. Add all data to a list.
count = 1
dflist <- list()
for (vec in linkedin$job_bullets) {
  if (length(vec) != 0) {
    annotated <- udpipe_annotate(model, vec)
    df_annotated <- data.frame(annotated)
    df_annotated <- df_annotated[(df_annotated$upos=='NOUN' | df_annotated$upos=='ADJ'),]
    freqs <- txt_freq(df_annotated$token)
    dflist[[count]] <- freqs[-c(3)]
  }
  else {
    annotated <- udpipe_annotate(model, linkedin$job_paragraphs[[count]])
    df_annotated <- data.frame(annotated)
    df_annotated <- df_annotated[(df_annotated$upos=='NOUN' | df_annotated$upos=='ADJ'),]
    freqs <- txt_freq(df_annotated$token)
    dflist[[count]] <- freqs[-c(3)]
  }
  count = count + 1
}

# Join lists into one big dataframe. Get row sums and delete extraneous columns.
bigdata <- dflist |> reduce(full_join, by='key')
bigdata <- bigdata |> mutate(count=rowSums(bigdata[,2:24], na.rm=TRUE))
bigdata <- bigdata[-c(2:24)]

# Remove non-words, reset index.
wordsonly <- grep("\\w|\\D)", bigdata$key, value=TRUE)
bigdata <- bigdata[bigdata$key %in% wordsonly,] |> arrange(desc(count))
rownames(bigdata) = seq(length=nrow(bigdata))
bigdata[1:300,]

# Combine duplicate words by capitalizing all, finding duplicates (group_by didn't work), and re-joining.
bigdata$key <- toupper(bigdata$key)
find_duplicates <- subset(bigdata, duplicated(key))
dups_joined <- full_join(bigdata[!duplicated(bigdata$key), ], find_duplicates, by="key")
dups_joined[is.na(dups_joined)] <- 0
dups_joined <- dups_joined |> mutate(count=count.x + count.y) |> select(c("key", "count"))
dups_joined[1:100,]

# Combine 'machine' and 'learning'
machinelearn <- filter(dups_joined, key=="MACHINE" | key=="LEARNING") |> summarize(count = sum(count))
final <- dups_joined |> add_row(key="MACHINE LEARNING", count=111) |> arrange(desc(count))
final <- final[!(final$key=="MACHINE" | final$key=="LEARNING"), ]
final[1:100,]

# Filter out to graph data in ggplot.
filtered <- final |> filter(count>10)
ggplot(data=filtered, aes(x=count, y=key)) +
  geom_bar(stat="identity", position="dodge", fill='#3590ae') +
  ggtitle("Top skills on LinkedIn - Nouns + Adjectives") +
  theme(axis.title.y=element_blank())


# That looks ok, but let's try with just nouns. A little better.
nouns <- subset(df_annotated, upos %in% c("NOUN"))
stats <- txt_freq(nouns$token)

filtered_nouns <- stats |> filter(freq>1)
ggplot(data=filtered_nouns, aes(x=freq, y=key)) +
  geom_bar(stat="identity", position="dodge", fill='#3590ae') +
  ggtitle("Top skills on LinkedIn - Nouns only") +
  theme(axis.title.y=element_blank())

# Let's try and see what the RAKE "Rapid Automated Keyword Extraction" protocol of the algorithm gives us, for both nouns and adjectives.
# Reurn df_annotation to get all terms (not just nouns and adjectives).
count = 1
dflist <- list()
for (vec in linkedin$job_bullets) {
  if (length(vec) != 0) {
    annotated <- udpipe_annotate(model, vec)
    df_annotated2 <- data.frame(annotated)
    freqs <- txt_freq(df_annotated2$token)
    dflist[[count]] <- freqs[-c(3)]
  }
  else {
    annotated <- udpipe_annotate(model, linkedin$job_paragraphs[[count]])
    df_annotated2 <- data.frame(annotated)
    freqs <- txt_freq(df_annotated2$token)
    dflist[[count]] <- freqs[-c(3)]
  }
  count = count + 1
}

# Plug the tagged words into RAKE.
# rake definition: the ratio of the degree to the frequency as explained in the description, summed up for all words from the keyword
keywords <- keywords_rake(x = df_annotated2, term = "lemma", group = "doc_id", 
                       relevant = df_annotated2$upos %in% c("NOUN", "ADJ")) |> arrange(desc(rake))
keywords

# Plot
ggplot(data=keywords, aes(reorder(keyword, rake), rake)) +
  geom_bar(stat="identity", position="dodge", fill='#3590ae') +
  ggtitle("Top skills on LinkedIn - RAKE algorithm") +
  theme(axis.title.y=element_blank()) +
  coord_flip()

# Not too impressive, in our case.
