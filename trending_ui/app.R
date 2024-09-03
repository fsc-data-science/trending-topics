source("global.R")
library(shiny)
library(shinyjs)

ui <- fluidPage(
  useShinyjs(),
  # pass clicks to general app
  
  # Headers ----
  tags$head(
    title = "Flipside Crypto's Trending Topics",
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$link(rel = "icon", href = "fliptrans.png"),
    tags$script(src = "rudderstack.js"),
    tags$script("rudderanalytics.page('trending')")
  ),
  
  # top row ----
  fluidRow(class = "titlerow",
           column(width = 3, div(id = "applogo", 
                                 a(href = "https://flipsidecrypto.xyz",
                                   img(src = "Flipside_black_logo_wordmark.svg", height = "24px"),
                                   onclick = paste0("rudderanalytics.track('", "trending", "_flipside')"),
                                   target = "_blank"))
            ),
           column(width = 6,
                  fluidRow(div(id = "appname", "What's trending in crypto?"))
                  ),
           
           column(width = 3,
                  div(id = "sidelinks",
                      a(href = "https://flipsidecrypto.xyz/pricing", 
                        class = "pro-link", 
                        img(src = "Flipside_icon_white.svg", height = "14px"), 
                        "Flipside Pro",
                        onclick = paste0("rudderanalytics.track('",  'trending', "_enterprise')"),
                        target = "_blank"),
                      a(href = "https://twitter.com/flipsidecrypto", 
                        img(src = "twitter.svg", height = "14px"),
                        style = "margin-left: 15px",
                        onclick = paste0("rudderanalytics.track('",  'trending', "_twitter')"),
                        target = "_blank"),
                      a(href = "https://discord.com/invite/ZmU3jQuu6W", 
                        img(src = "discord.svg", height = "14px"),
                        style = "margin-left: 15px",
                        onclick = paste0("rudderanalytics.track('",  'trending', "_discord')"),
                        target = "_blank")
                  )
           )
  ), # End title row

  # App ----
  hr(),
  div(class = "appbody",

  br(),
  div(class = "context-submit",
      fluidRow(
        actionButton(
          onclick = "rudderanalytics.track('trending_all')",
          inputId = 'all', label = "All", class = "btn-category"),
        actionButton(
          onclick = "rudderanalytics.track('trending_bitcoin')",
          inputId = 'bitcoin', label = "Bitcoin", class = "btn-category"),
        actionButton(
          onclick = "rudderanalytics.track('trending_ethereum')",
          inputId = 'ethereum', label = "Ethereum", class = "btn-category"),
        actionButton(
          onclick = "rudderanalytics.track('trending_evml2s')",
          inputId = 'l2s', label = "EVM/L2s", class = "btn-category"),
        actionButton(
          onclick = "rudderanalytics.track('trending_solana')",
          inputId = 'solana', label = "Solana", class = "btn-category"),
        actionButton(
          onclick = "rudderanalytics.track('trending_avalanche')",
          inputId = 'avalanche', label = "Avalanche", class = "btn-category"),
        actionButton(
          onclick = "rudderanalytics.track('trending_polygon')",
          inputId = 'polygon', label = "Polygon", class = "btn-category"),
        actionButton(
          onclick = "rudderanalytics.track('trending_aptos')",
          inputId = 'aptos', label = "Aptos", class = "btn-category"),
        actionButton(
          onclick = "rudderanalytics.track('trending_near')",
          inputId = 'near', label = "Near", class = "btn-category"),
        actionButton(
          onclick = "rudderanalytics.track('trending_axelar')",
          inputId = 'axelar', label = "Axelar", class = "btn-category"),
        actionButton(
          onclick = "rudderanalytics.track('trending_sei)",
          inputId = 'sei', label = "Sei", class = "btn-category"),
        actionButton(
            onclick = "rudderanalytics.track('trending_kaia)",
            inputId = 'kaia', label = "Kaia", class = "btn-category"),
      actionButton(
        onclick = "rudderanalytics.track('trending_bera)",
        inputId = 'bera', label = "Berachain", class = "btn-category"),
      actionButton(
        onclick = "rudderanalytics.track('trending_flow)",
        inputId = 'flow', label = "Flow", class = "btn-category")
        )
      ),
  fluidRow(
    column(12, align = "center",
           textInput("custom_search", "", value = "", width = "50%", 
                     placeholder = "Put your own keywords here to filter top 20 summaries")
    )
  ),
  conditionalPanel(
    condition = "output.view == 'subject'",
    div(class = "content-area-no-scroll", 
        p("Click to open tweet in new window. Tweets identified by fuzzy keyword matching may not be a perfect match. Select a chain or All to go back.")
    )
  ),
  conditionalPanel(
    condition = "output.view == 'overall'",
    div(class = "content-area-no-scroll", 
        p("AI generated summaries aggregated across twitter at the day-ecosystem level. Select to view correlated tweets.")
    )
  ),
  
  div(class = "content-area", 
      conditionalPanel(
        condition = "output.view == 'overall'",
            uiOutput("cards")
      ),
      conditionalPanel(
        condition = "output.view == 'subject'",
        uiOutput("tweets")
      )
      
  )
  )
  
)

server <- function(input, output, session) {

  clicked_card <- reactiveVal(NULL)
  # 2nd copy so users can go back and then reclick same card as before 
  card_clicked <- reactiveVal(NULL)
  
  initial_search <- reactive({
    query <- parseQueryString(session$clientData$url_search)
    if (!is.null(query[['search']])) {
      return(query[['search']])
    }
    return("")
  })
  
  # Set initial value
  observe({
    updateTextInput(session, "custom_search", value = initial_search())
  })
  
  # Update URL when search changes (optional, for two-way functionality)
  observeEvent(input$custom_search, {
    search_term <- input$custom_search
    if (search_term != initial_search()) {
      updateQueryString(paste0("?search=", URLencode(search_term)), mode = "replace")
    }
  }, ignoreInit = TRUE)
  
  observeEvent(input$card_clicked, {
    clicked_card(input$card_clicked)
    card_clicked(input$card_clicked)
    x <<- card_clicked()
    view("subject")
    clicked_card(NULL)
    updateTextInput(session, inputId = "custom_search", value = "")
  })
  
  # all buttons bring back overall view ----
  observeEvent(input$all, { 
    updateTextInput(session, inputId = "custom_search", value = "")
    
    view("overall")
    })
  observeEvent(input$bitcoin, { 
    updateTextInput(session, inputId = "custom_search", value = "btc bitcoin proof of work satoshi")
    view("overall") 
    })
  observeEvent(input$ethereum, { 
    updateTextInput(session, inputId = "custom_search", value = "eth ether ethereum evm mainnet defi nfts")
    view("overall")
    })
  observeEvent(input$l2s, { 
    updateTextInput(session, inputId = "custom_search", value = "arb arbitrum op optimism base blast layer-2 L2")
    view("overall")
    })
  observeEvent(input$solana, { 
    updateTextInput(session, inputId = "custom_search", value = "sol solana raydium jupiter jup")
    view("overall")
    })
  observeEvent(input$avalanche, { 
    updateTextInput(session, inputId = "custom_search", value = "avax avalanche subnets")
    view("overall")
    })
  observeEvent(input$polygon, { 
    updateTextInput(session, inputId = "custom_search", value = "matic pol polygon")
    view("overall")
    })
  observeEvent(input$aptos, { 
    updateTextInput(session, inputId = "custom_search", value = "aptos apt thala aries")
    view("overall")
    })
  observeEvent(input$near, { 
  updateTextInput(session, inputId = "custom_search", value = "near aurora sweat near.ai horizon")
  view("overall")
  })
  observeEvent(input$axelar, { 
    updateTextInput(session, inputId = "custom_search", value = "squid axlusdc axl axelar")
    view("overall")
    })
  observeEvent(input$sei, { 
    updateTextInput(session, inputId = "custom_search", value = "sei seiv2 seiEVM seiyans")
    view("overall")
    })
  observeEvent(input$kaia, { 
    updateTextInput(session, inputId = "custom_search", value = "kaia klaytn")
    view("overall")
  })
  observeEvent(input$bera, { 
    updateTextInput(session, inputId = "custom_search", value = "bera berabaddies bex thoon bgt honey")
    view("overall")
  })
  observeEvent(input$flow, { 
    updateTextInput(session, inputId = "custom_search", value = "flow dapper topshot nba nfl disney pins")
    view("overall")
  })
  
  selected_subject <- reactiveVal(NULL)
  view <- reactiveVal("overall")
  
  output$view <- reactive({
    view()
  })
  outputOptions(output, "view", suspendWhenHidden = FALSE)
  # /all ----
  # Cards ----
  
  output$cards <- renderUI({
    
    if(nchar(input$custom_search) > 3){
      
      summary_rank <- rank_corpus(input$custom_search, corpus_ = latest_ai_summaries$SUMMARY, top_n = 20)
      filter_ai_summaries <- latest_ai_summaries[summary_rank, ]
      
    } else {
      filter_ai_summaries <- latest_ai_summaries
    }
   tagList(
     br(),
    apply(X = filter_ai_summaries, MARGIN = 1, function(x){
      generateCard(x["DAY_"], x["SUBJECT"], x["SUMMARY"])
     })
   )
  })
  
  output$tweets <- renderUI({
    card_search <- card_clicked()
    subj <- card_search$subject
    summ <- card_search$summary
    
    card_search <- paste0( c(card_search$subject, card_search$summary), collapse = " ")
    
    # require at least 1 word in subject
    filter_latest_tweets <- latest_tweets[grepl(pattern = paste0(unlist(strsplit(subj, split = " ")), collapse = "|"), latest_tweets$TWEET_TEXT, ignore.case = TRUE), ]
    
    if(nchar(input$custom_search) > 3){
      
      summary_rank <- rank_corpus(input$custom_search, corpus_ = filter_latest_tweets$TWEET_TEXT, top_n = 40)
      filter_latest_tweets <- filter_latest_tweets[summary_rank, ]
        
    } 
    
    if(nrow(filter_latest_tweets) == 0){
      filter_latest_tweets <- latest_tweets
    }
    
    tweet_rank <- rank_corpus(card_search, corpus_ = filter_latest_tweets$TWEET_TEXT, top_n = 20)
  
    tagList(
      h3(subj),
      h4(summ),
      hr(),
    apply(X = filter_latest_tweets[tweet_rank, ], 1, function(x){
    generateTweetCard(x["USERNAME"], x["DAY_"], x["TWEET_TEXT"], x["TWEET_ID"])
    })
    
    )
  })
  
  
}

# Run the application 
shinyApp(ui = ui, server = server)
