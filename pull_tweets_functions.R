library(httr)
library(jsonlite)
library(dplyr)

twitter_secret <- readLines("twitter-secret.txt")
chatgpt_secret <- readLines("chatgpt-secret.txt")

# reprex using DegenerateNews
account = 'DegenerateNews'
account2 = 'punk6529'

get_twitter_user_info <- function(username, access_token) {
  url <- paste0("https://api.twitter.com/2/users/by/username/", username)
  response <- GET(url, add_headers(Authorization = paste("Bearer", access_token)))
  
  if (status_code(response) == 200) {
    content(response, "parsed")
  } else {
    stop("Failed to fetch user info: ", status_code(response))
  }
}

account_info <- get_twitter_user_info(account, twitter_secret)
account_id <- account_info$data$id

account_info2 <- get_twitter_user_info(account2, twitter_secret)
account_id2 <- account_info2$data$id

get_user_timeline <- function(user_id, access_token, max_results = 100) {
  url <- paste0("https://api.twitter.com/2/users/", user_id, "/tweets?max_results=", 
                max_results, "&tweet.fields=created_at")
  response <- GET(url, add_headers(Authorization = paste("Bearer", access_token)))
  
  if (status_code(response) == 200) {
    content(response, "parsed")
  } else {
    stop("Failed to fetch user timeline: ", status_code(response))
  }
}

account_timeline <- get_user_timeline(account_id, twitter_secret, 100)
account_timeline2 <- get_user_timeline(account_id2, twitter_secret, 100)

extract_timeline_data <- function(account_name, timeline_data){

 lst_ <- lapply(timeline_data, function(x){
    data.frame(
      created_at = x[["created_at"]],
      text = x[["text"]],
      id = x[["id"]],
      url = paste0("https://x.com/",account_name,"/status/",x[["id"]])
    )
  })
 
 return(
   do.call(rbind, lst_ )
 )
}

account_tweets_df <- extract_timeline_data(account, account_timeline$data)
account_tweets_df2 <- extract_timeline_data(account2, account_timeline2$data)

tweet_text <- paste0(account_tweets_df$text, collapse = " %%% ")
tweet_text2 <- paste0(account_tweets_df2$text, collapse = " %%% ")

chatgpt_id_topic <- function(tweet_text, chatgpt_secret){
 
  request_body <- list(
    model = "gpt-3.5-turbo",
    messages = list(
      list(role = "user", 
           content = paste0("You're being provided a series of tweets (the text they contain) split by the %%%. 
           Your goal is to identify the key subjects being discussed (for example the most unique word(s) or 
           key projects and people being noted. This is going to feed into a trending-panel on an app website. The goal
           is to help analyst identify the most interesting subjects/protocols/ideas to investigate further.
           For each subject, state the subject directly and specifically (name the person or project or company), then 
           Return the subject and the key piece of information to know about the subject (why are they being mentioned?).
           in the following form with 1-2 sentences per subject (please provide 3-5 subjects as you see fit): 
           1. Subject1: [Subject1 Summary]...
           2. Subject2: [Subject2 Summary]...
           3. Subject3: [Subject3 Summary]...
          
                          ", tweet_text))
    )
  )
  
  response <- POST(
    url = "https://api.openai.com/v1/chat/completions",
    add_headers(
      `Content-Type` = "application/json",
      `Authorization` = paste("Bearer", chatgpt_secret)
    ),
    body = toJSON(request_body, auto_unbox = TRUE),
    encode = "json"
  )
  
  # Check the response
  response_content <- content(response)
 return(response_content$choices[[1]]$message$content)
}

chat_topics <- chatgpt_id_topic(tweet_text, chatgpt_secret)
chat_topics2 <- chatgpt_id_topic(tweet_text2, chatgpt_secret)

get_subject <- function(chat_topics){
  
}
get_summaries <- function(chat_topics){
  
}
