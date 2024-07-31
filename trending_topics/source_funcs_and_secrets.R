
expected_token <- readLines("plumber_secret.txt")
twitter_secret <- readLines("twitter-secret.txt")
chatgpt_secret <- readLines("chatgpt-secret.txt")
prompt <- {
  "
  ### INPUT 
   You're being provided a series of tweets (the text the tweets contain) where each tweet content is separated by the symbol '%%%'. 
   
  ### TASK 
Your goal is to identify the key subjects being discussed (e.g., the projects or people being noted). This is going to feed into a trending tropics website. The goal is to help analysts identify the most interesting trending subjects/protocols/ideas to investigate further. For each subject, state the subject directly and specifically (name the person or project or company) and return the subject alongside the key piece of information to know about the subject in the following format with 1-2 sentences per subject (please provide 3 to 5 subjects as you see fit):
           
  ### FORMAT 
           1. Subject1: [Subject1 Summary]
           2. Subject2: [Subject2 Summary]
           3. Subject3: [Subject3 Summary]
          
  ### EXAMPLE 
           1. Solana Memecoin: A new shorting platform for Solana Memecoins called @dumpydotfun has gone live in beta, allowing users to short shitcoins destined for zero.
           2. Senator Lummis: U.S. Senator @SenLummis is proposing a bill to establish a strategic reserve of Bitcoin to fortify the dollar against inflation and acquire 5% of the total Bitcoin supply.
           3. Ethereum ETF Launch: Spot Ethereum ETF trading has gone live in the U.S., with a noted inflow and outflow on its first trading day.

  ### NOTE
It is extremely important that you follow the provided format. Always use a numbered list. Always state the subject first. And always provide 1-2 sentences including the subject. Review your output before providing it to me, ensure it follows the provided format. 
  "}


get_twitter_user_id <- function(username, access_token) {
  url <- paste0("https://api.twitter.com/2/users/by/username/", username)
  response <- GET(url, add_headers(Authorization = paste("Bearer", access_token)))
  
  if (status_code(response) == 200) {
    content(response, "parsed")
  } else {
    stop("Failed to fetch user info: ", status_code(response))
  }
}

get_twitter_user_name <- function(id, access_token){
  url <- paste0("https://api.twitter.com/2/users/", id)
  response <- GET(url, add_headers(Authorization = paste("Bearer", access_token)))
  
  if (status_code(response) == 200) {
    content(response, "parsed")
  } else {
    stop("Failed to fetch user info: ", status_code(response))
  }
}


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


chatgpt_id_topic <- function(tweet_text, chatgpt_secret, prompt){
  
  request_body <- list(
    model = "gpt-3.5-turbo",
    messages = list(
      list(role = "user", 
           content = paste0(prompt, tweet_text))
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


get_subject <- function(chat_topics){
  gsub("[0-9]+\\. |:.*","",  unlist(strsplit(chat_topics, "\n")))
}

get_summaries <- function(chat_topics){
  gsub("[0-9]+.*: ","",  unlist(strsplit(chat_topics, "\n")))
}

# Master functions for account aggregation & summarization ----

pull_account_tweets <- function(account = NULL, id = NULL, twitter_secret, n = 100){
  if(is.null(account) & is.null(id)){
    stop("need account or twitter id")
  }
  
  if(is.null(account) & !is.null(id)){
    account = get_twitter_user_name(id = id, twitter_secret)$data$username
  }
  
  # you'll need id
  if(!is.null(account) & is.null(id)){
    id = get_twitter_user_id(account, twitter_secret)$data$id
  }
  
  account_timeline <- get_user_timeline(account_id, twitter_secret, n)
  account_tweets_df <- extract_timeline_data(account, account_timeline$data)
  tweet_text <- paste0(account_tweets_df$text, collapse = " %%% ")
  
  return(
    list(
      raw_timeline = account_timeline,
      tweets_tbl = account_tweets_df,
      tweets_collapsed_text = tweet_text
    )
  )
  
}

get_chatgpt_tweet_analysis <- function(tweet_text, chatgpt_secret, prompt){
  chat_topics <- chatgpt_id_topic(tweet_text, chatgpt_secret, prompt)
  subjects <- get_subject(chat_topics)
  summaries <- get_summaries(chat_topics)
  
  return(
    list(
      raw_chat_response = chat_topics,
      subjects = subjects,
      summaries = summaries
    )
  )
  
}

