library(httr)
library(jsonlite)
library(dplyr)

# all functions & secrets inside API
source("trending_topics/source_funcs_and_secrets.R")

# reprex using DegenerateNews
account = 'DegenerateNews'
account2 = 'punk6529'

account_info <- get_twitter_user_id(account, twitter_secret)
account_id <- account_info$data$id

account_info2 <- get_twitter_user_id(account2, twitter_secret)
account_id2 <- account_info2$data$id

account_timeline <- get_user_timeline(account_id, twitter_secret, 100)
account_timeline2 <- get_user_timeline(account_id2, twitter_secret, 100)


account_tweets_df <- extract_timeline_data(account, account_timeline$data)
account_tweets_df2 <- extract_timeline_data(account2, account_timeline2$data)

tweet_text <- paste0(account_tweets_df$text, collapse = " %%% ")
tweet_text2 <- paste0(account_tweets_df2$text, collapse = " %%% ")


chat_topics <- chatgpt_id_topic(tweet_text, chatgpt_secret, prompt)
chat_topics2 <- chatgpt_id_topic(tweet_text2, chatgpt_secret, prompt)





