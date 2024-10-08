source("trending_topics/source_funcs_and_secrets.R")


latest_check <- ai_[ai_$DAY_ >= '2024-10-01', ]
x = split(latest_check, latest_check$SUMMARY_ID)

y = lapply(x, function(z){
  temp_ <- paste0(1:length(z$SUBJECT), ".", z$SUBJECT, ": ",z$SUMMARY, collapse = "\n")
   
  claude_id_topic(tweet_text = temp_, claude_api_key = claude_secret, prompt = fundamentally_interesting_prompt  )
})

