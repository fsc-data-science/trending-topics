# trending-topics
 Pipelines & NLP for identification of trending topics in crypto, by ecosystem, over the last 24-48 hours.
 
# How to reproduce 

1. clone repo and open `trending-topics.Rproj`
2. You'll need a twitter api key `twitter-secret.txt` and chatGPT api key `chatgpt-secret.txt` these are gitignored and placed in the `trending_topics/` directory where the scheduled Rmarkdown lives (`update_topics_pipeline.Rmd`).
3. You'll also need `snowflake-details.json` for the submitSnowflake function in the form:
```json
{ "driver": "YOUR-LOCAL-SNOWFLAKE-DRIVER-HERE",
  "server_url": "YOUR-URL-HERE.snowflakecomputing.com",
  "username": "PUT-USERNAME-HERE",
  "password": "PUT-PASSWORD-HERE",
  "role": "INTERNAL_DEV",
  "warehouse": "DATA_SCIENCE",
  "database": ""
}
```
4. The `reprex-for-pulltweets-ai-summarize.R` contains the internal functions & example accounts for the broader pipeline. It sources from `trending_topics/source_funcs_and_secrets.R` which will load the required libraries, functions, and secrets to run the pipeline. 

 
# Pipeline 

 Full pipeline diagram included as an image + pdf. 
 
 1. Pulls `target_twitter_accounts` and calls `pull_account_tweets`.
 2. Dump dataframe form in `raw_tweet_dump`, call `add_new_tweets()` proc to clean & append to `processed_tweets`.
 3. Ingest unused tweets to call `chatgpt_id_topic` at the day-ecosystem level and get the `subjects` and `summaries`. 
 4. Update used tweets to `used_in_summary = TRUE` and insert into `ai_summary`.
 
 Website (in-dev) offers a UI over the summaries that uses term frequency to link back to 
 relevant tweets at the day-ecosystem level.
 
 ![Trending Topics Pipeline](trending-topics-pipeline.png)
