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
# 
# #* @filter bearer_token_auth
# function(req, res) {
#   auth_header <- req$HTTP_AUTHORIZATION
#   
#   if (is.null(auth_header) || !grepl("^Bearer\\s", auth_header)) {
#     res$status <- 401
#     return(list(error = "Unauthorized: Bearer token required"))
#   }
#   
#   token <- sub("^Bearer\\s", "", auth_header)
#   
#   # Replace 'YOUR_EXPECTED_TOKEN' with your actual bearer token
#   if (token != expected_token) {
#     res$status <- 403
#     return(list(error = "Forbidden: Invalid token"))
#   }
#   
#   # If the token is valid, continue with the request
#   plumber::forward()
# }


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
  
  
}

#* Pulls tweets not yet summarized, groups by day, summarizes across them at the daily level, appends to `ai_summary`.
#*@post /ai_summarize
function(req){
  
}



# Programmatically alter your API
#* @plumber
function(pr) {
    pr %>%
        # Overwrite the default serializer to return unboxed JSON
        pr_set_serializer(serializer_unboxed_json())
}
