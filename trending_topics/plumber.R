library(plumber)
source("source_funcs_and_secrets.R")

#* @apiTitle Trending Topics Pipeline AI
#* @apiDescription Handles updates & interactions between the trending topics tables including APIs for pulling tweets and automated summaries.

#* Echo back the input
#* @param msg The message to echo
#* @get /echo
function(msg = "") {
    list(msg = paste0("The message is: '", msg, "'"))
}

#* Return the sum of two numbers
#* @param a The first number to add
#* @param b The second number to add
#* @post /sum
function(a, b) {
    as.numeric(a) + as.numeric(b)
}


#* Pull tweets of `target_twitter_accounts`, append to `raw_tweet_dump`, calls `add_new_tweets()` to append to `processed_tweets`.
#* @post /pull_tweets 
function(req){
  
  target_accounts <- submitSnowflake(
    query = "select * from datascience_dev.trending_topics.target_twitter_accounts",
    creds = snowflake_credentials
    )
  
  
  # pulls latest 100 tweets for simplicity
  pull_list <- lapply(1:nrow(target_accounts), function(x){
    pull_account_tweets(account = target_accounts$USERNAME[x], 
                        id = target_accounts$TWITTER_ID[x],
                        twitter_secret = twitter_secret,
                        n = 100)
    
  })
  
  df <- do.call(rbind, pull_list)
  
  # prepare in case of single quote to escape them
  df$tweet_text <- gsub("'", "''", df$tweet_text)
  
  values <- apply(df, 1, function(row) {
    sprintf("('%s', '%s', '%s', '%s')",
            row['created_at'], row['username'], row['tweet_text'], row['twitter_id'])
  })
  
  insert_query <- sprintf(
    "INSERT INTO datascience_dev.trending_topics.raw_tweet_dump (created_at, username, tweet_text, tweet_id) VALUES %s",
    paste(values, collapse = ",")
  )
  
  submitSnowflake(insert_query, creds = snowflake_credentials)
  
  res_ <- submitSnowflake("call datascience_dev.trending_topics.add_new_tweets()", creds = snowflake_credentials)
  
  return(res_)
}

#* Pulls tweets not yet summarized, groups by day, summarizes across them at the daily level, appends to `ai_summary`.
#*@post /ai_summarize
function(req){
  
  unused_ <- submitSnowflake(query = {
    " 
    select 
    t.CREATED_AT, t.DAY_, t.USERNAME,
    t.TWEET_TEXT, t.TWEET_ID, 
    t.USED_IN_SUMMARY, 
    a.ECOSYSTEM
    from 
    datascience_dev.trending_topics.processed_tweets t left join datascience_dev.trending_topics.target_twitter_accounts a 
    USING (USERNAME)
    where used_in_summary = FALSE
    "
  }, creds = snowflake_credentials)
  
  # for each ecosystem, each day - get a summary of tweets across accounts 
  
  unique_eco_days <- unique(unused_[, c("DAY_","ECOSYSTEM")] )
  
  for(i in 1:nrow(unique_eco_days)){
    
    temp_day <- unique_eco_days$DAY_[i]
    temp_ecosystem <- unique_eco_days$ECOSYSTEM[i]
    
    temp_tweets <- unused_[
      unused_$DAY_ == temp_day & 
      unused_$ECOSYSTEM == temp_ecosystem, ]
    
    temp_ids_used <- temp_tweets$TWEET_ID
    
    tweet_text <- paste0(temp_tweets$TWEET_TEXT, collapse = " %%% ")
    chat_topics <- chatgpt_id_topic(tweet_text, chatgpt_secret, prompt)
    subjects <- get_subject(chat_topics)
    subjects <- subjects[nchar(subjects)  > 0]
    summaries <- get_summaries(chat_topics)
    summaries <- summaries[nchar(summaries)  > 0]
    
    # update the IDs used as used
    
    update_query <- sprintf(
      "UPDATE datascience_dev.trending_topics.processed_tweets 
       SET used_in_summary = TRUE 
       WHERE tweet_id IN (%s)",
      paste0("'", temp_ids_used, "'", collapse = ",")
    )
    
    submitSnowflake(update_query, creds = snowflake_credentials)
    
    # insert the ai summaries into their table 
    
    current_date <- format(Sys.Date(), "%Y%m%d")
    summary_id <- paste(temp_day, temp_ecosystem, current_date, sep = "_")
    
    # Escape single quotes in text fields
    subjects <- gsub("'", "''", subjects)
    summaries <- gsub("'", "''", summaries)
    
    insert_query <- sprintf(
      "INSERT INTO datascience_dev.trending_topics.ai_summary (day_, subject, summary, summary_id) 
       VALUES ('%s', '%s', '%s', '%s')",
      temp_day, subjects, summaries, summary_id
    )
    
    for(j in insert_query){
    submitSnowflake(j, creds = snowflake_credentials)
    }
    
  }
  
}

# Programmatically alter your API
#* @plumber
function(pr) {
    pr %>%
        # Overwrite the default serializer to return unboxed JSON
        pr_set_serializer(serializer_unboxed_json())
}
