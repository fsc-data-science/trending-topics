library(httr)
library(jsonlite)
library(odbc)
library(dplyr)

# Always gitignore credentials and keys
snowflake_credentials <- jsonlite::read_json('snowflake-details.json')

submitSnowflake <- function(query, creds){
  
  connection <- dbConnect(
    odbc::odbc(),
    .connection_string = paste0("Driver={",creds$driver,"}",
                                ";Server={",creds$server_url,
                                "};uid=",creds$username,
                                ";role=",creds$role,
                                ";pwd=",creds$password,
                                ";warehouse=", creds$warehouse,
                                ";database=", creds$database)
  )
  
  output <- dbGetQuery(connection, query)
  dbDisconnect(connection)
  return(output)
  
}

last_update <- readRDS('last_run.rds')

# LOCAL DATA COPY FOR SPEED ----
# If it's been 4 hours, re-pull the lastest summaries & tweets for local 
# filtering & comparison 

if(difftime(Sys.time(), last_update, units = "hours") > 4){
  
  
latest_ai_summaries <- submitSnowflake(query = {
  "
  select * from datascience_dev.trending_topics.ai_summary
where day_ >= current_date - 7
order by day_ DESC;
  "
  }, creds = snowflake_credentials)

saveRDS(latest_ai_summaries, "latest_ai.rds")

latest_tweets <- submitSnowflake(query = {
  "
select * from datascience_dev.trending_topics.processed_tweets
where day_ >= current_date - 7
order by day_ DESC;
  "
}, creds = snowflake_credentials)

saveRDS(latest_tweets, "latest_tweets.rds")
  
saveRDS(Sys.time(), 'last_run.rds')  

} else {
  latest_ai_summaries <- readRDS("latest_ai.rds")
  latest_tweets <- readRDS("latest_tweets.rds")
}


# NLP FUNCTION FOR SEARCH INTERSECTIONS ----
stopwords <- c("a", "the", "and", "of", "in", "on", "at", "for", "with", "about", "is", "to", "this", "that", "it", "by", "as", "an", "be", "are")

preprocess_text <- function(text) {
  words <- tolower(text) %>%
    strsplit(split = " ") %>%
    unlist() %>%
    setdiff(stopwords)
  return(words)
}

# Define the function
rank_corpus <- function(search_text, corpus_, top_n = 10) {
  # Helper function to preprocess text
  
  # Preprocess the search text
  search_words <- preprocess_text(search_text)
  
  # Create a data frame to store the corpus and their word counts
  corpus_df <- data.frame(
    id_ = 1:length(corpus_),                      
    text = corpus_,
    stringsAsFactors = FALSE
  )
  
  # Calculate the overlap score for each corpus entry
  corpus_df <- corpus_df %>%
    rowwise() %>%
    mutate(
      words = list(preprocess_text(text)),
      overlap_count = length(intersect(search_words, words))
    ) %>%
    ungroup() %>%
    arrange(desc(overlap_count))
  
  # Return index of top N corpus entries based on the overlap count
  top_corpus <- head(corpus_df$id_, n = top_n)
  return(top_corpus)
}





# Relevant UI Functions ----
generateCard <- function(day, subject, summary) {
  div(class = "card",
      div(class = "card-header",
          span(class = "subject", subject),
          span(class = "date", day)
      ),
      div(class = "card-body",
          p(summary)
      )
  )
}
