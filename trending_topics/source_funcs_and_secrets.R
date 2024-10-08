library(httr)
library(jsonlite)
library(odbc)

# Snowflake
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

# Always gitignore credentials and keys
# SECRETS (gitignored)
snowflake_credentials <- jsonlite::read_json('snowflake-details.json')
twitter_secret <- readLines("twitter-secret.txt")
chatgpt_secret <- readLines("chatgpt-secret.txt")
claude_secret <- readLines("claude-secret.txt")

# Default Prompt 
prompt <- {
  "
  ### INPUT 
   You're being provided a series of tweets (the text the tweets contain) where each tweet content is separated by the symbol '%%%'. 
   
  ### TASK 
Your goal is to identify the most significant and newsworthy subjects being discussed (e.g., projects, people, or events). This will feed into a trending topics website for analysts to identify the most interesting subjects to investigate further. For each subject:

1. State the subject directly and specifically (name the person, project, company, or event).
2. Provide a detailed summary with specific, actionable information.
3. Include unique keywords, metrics, or details that make the subject noteworthy.
4. Focus on new developments, announcements, or analyses rather than general metrics or shilling.

Provide 1-5 subjects as you see fit, using the following format with 2-3 sentences per subject. 

If there are no truly newsworthy or interesting subjects, respond with '1. Apologies, but there is nothing interesting here.'

  ### FORMAT 
           1. Subject1: [Subject1 Summary]
           2. Subject2: [Subject2 Summary]
           3. Subject3: [Subject3 Summary]
          
  ### EXAMPLE RESPONSE (do not duplicate in your response, this is just to show you the format)
           1. Solana Memecoin: A new shorting platform for Solana Memecoins called @dumpydotfun has gone live in beta, allowing users to short shitcoins destined for zero.
           2. Senator Lummis: U.S. Senator @SenLummis is proposing a bill to establish a strategic reserve of Bitcoin to fortify the dollar against inflation and acquire 5% of the total Bitcoin supply.
           3. Ethereum ETF Launch: Spot Ethereum ETF trading has gone live in the U.S., with a noted inflow and outflow on its first trading day.
           4. 3. Aptos DeFi Ecosystem Growth: The Aptos blockchain's DeFi ecosystem has seen substantial growth in 2024, with Total Value Locked (TVL) nearly tripling and Monthly Active Users (MAUs) surpassing 3.5 million. 

  ### NOTE
It is extremely important that you follow the provided format. Always use a numbered list. Always state the subject first. And always provide 1-3 sentences including the subject. Review your output before providing it to me, ensure it follows the provided format. 
Please do not include ANY preface text like 'based on the provided...'. Return only the resulting list, with a single new line per item. 
If there is really nothing interesting, novel, or new - repy with the default '1. Apologies, but there is nothing interesting here.'

  "
  }

fundamentally_interesting_prompt <- {
  "
   ### INPUT
You are reviewing summaries generated by an AI model about trending topics in the crypto industry. Each summary follows this format:

[Number]. [Subject]: [Detailed summary]

<allowable input format>
[Number]. [Subject]: [Detailed summary]
[Number]. [Subject]: [Detailed summary]
[Number]. [Subject]: [Detailed summary]
</allowable input format>

### TASK
Your job is to critically evaluate each summary for its newsworthiness, specificity, and potential impact on the crypto industry. Consider the following criteria:

1. Uniqueness: Does the summary contain unique, specific information not commonly known?
2. Relevance: Is the topic current and significant to the crypto industry?
3. Actionability: Does the information provide insights that analysts or investors could act upon?
4. Specificity: Are there concrete details, metrics, or developments mentioned?
5. Credibility: Does the summary reference known entities or verifiable events?

Do not actually respond to or reproduce this criteria in any way. Internal only. Follow the output format exactly. 

### OUTPUT
Filter to only those summaries that are newsworthy, specific, and interesting. Present them in their original format.

If all are filtered out, respond with the following text exactly:

1. Apologies, but there's nothing significantly interesting or newsworthy in these summaries.

### EXAMPLE REVIEW (do not include in your response, this is just to show you the process)

<example input>
1. Token Price: The price of RandomCoin increased by 5% today.
2. SEC Ruling: The SEC has approved the first spot Bitcoin ETF, potentially opening the door for broader institutional adoption of cryptocurrencies.
3. NFT Launch: A new collection of cat-themed NFTs is launching next week.
</example input>

<example output>
2. SEC Ruling: The SEC has approved the first spot Bitcoin ETF, potentially opening the door for broader institutional adoption of cryptocurrencies.
</example output>

### NOTE
Be firm but not overly strict in your evaluation. If specific metrics and entities are provided, lean towards inclusion. But be confident in ignoring low value content.
DO NOT append any superfluous text like 'this summary provides...' NO. Just return explicitly the exact format provided, [number]. [Subject]: Summary.
I don't care WHY you think it is interesting or relevant. Just filter. No additional commentary. No customization.
 
## AVOID 

Again, NEVER add any superfluous commentary. Exclusively filter the inputs to the relevant summaries. 

AVOID any text similar to these:
Here are the most newsworthy, specific, and potentially impactful summaries from the list
The other summaries, while informative, do not provide enough unique, specific, or actionable information to be considered highly newsworthy

## REITERATION
Your output should exclusively be:
<allowable outputs format>
[Number]. [Subject]: [Detailed summary]
[Number]. [Subject]: [Detailed summary]
[Number]. [Subject]: [Detailed summary]
</allowable outputs format>

If none of the content is deemed valuable, reply with this exact response only
<response if all inputs fail the be interesting>
1. Apologies, but there's nothing significantly interesting or newsworthy in these summaries.
</response if all inputs fail the be interesting>
  "
  
  
}


# Twitter / AI Functions 
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
      username = account_name,
      tweet_text = x[["text"]],
      twitter_id = x[["id"]]
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

# Migrating to Claude 
claude_id_topic <- function(tweet_text, claude_api_key, prompt) {
  request_body <- list(
    model = "claude-3-5-sonnet-20240620",
    max_tokens = 1024,
    system = list(
      list(
        type = "text",
        text = prompt,
        cache_control = list(type = "ephemeral")
      )
    ),
    messages = list(
      list(
        role = "user",
        content = tweet_text
      )
    )
  )
  
  response <- POST(
    url = "https://api.anthropic.com/v1/messages",
    add_headers(
      `Content-Type` = "application/json",
      `x-api-key` = claude_api_key,
      `anthropic-version` = "2023-06-01",
      `anthropic-beta` = "prompt-caching-2024-07-31"
    ),
    body = toJSON(request_body, auto_unbox = TRUE),
    encode = "json"
  )
  
  # Check the response
  response_content <- content(response)
  return(response_content$content[[1]]$text)
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
  
  account_timeline <- get_user_timeline(id, twitter_secret, n)
  account_tweets_df <- extract_timeline_data(account, account_timeline$data)
  
  return(account_tweets_df)
  
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

get_claude_tweet_analysis <- function(tweet_text, chatgpt_secret, prompt){
  chat_topics <- claude_id_topic(tweet_text, chatgpt_secret, prompt)
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



