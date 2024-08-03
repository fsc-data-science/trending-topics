source("global.R")
library(shiny)
library(odbc)
library(jsonlite)

ui <- fluidPage(
  
  # Headers ----
  tags$head(
    title = "Flipside Crypto's Trending Topics",
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$link(rel = "icon", href = "fliptrans.png")
  ),
  
  # top row ----
  fluidRow(class = "titlerow",
           column(width = 3, div(id = "applogo", 
                                 a(href = "https://flipsidecrypto.xyz",
                                   img(src = "Flipside_black_logo_wordmark.svg", height = "24px"),
                                   onclick = paste0("rudderanalytics.track('", 'ai_submit', "_flipside')"),
                                   target = "_blank"))
            ),
           column(width = 6,
                  fluidRow(div(id = "appname", "What's trending in crypto?"))
                  ),
           
           column(width = 3,
                  div(id = "sidelinks",
                      a(href = "https://flipsidecrypto.xyz/pricing", 
                        class = "data-shares-link", 
                        img(src = "Flipside_icon_white.svg", height = "14px"), 
                        "Flipside Pro",
                        onclick = paste0("rudderanalytics.track('",  'ai_submit', "_enterprise')"),
                        target = "_blank"),
                      a(href = "https://twitter.com/flipsidecrypto", 
                        img(src = "twitter.svg", height = "14px"),
                        style = "margin-left: 15px",
                        onclick = paste0("rudderanalytics.track('",  'ai_submit', "_twitter')"),
                        target = "_blank"),
                      a(href = "https://discord.com/invite/ZmU3jQuu6W", 
                        img(src = "discord.svg", height = "14px"),
                        style = "margin-left: 15px",
                        onclick = paste0("rudderanalytics.track('",  'ai_submit', "_discord')"),
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
        actionButton(inputId = 'all', label = "All", class = "btn-category"),
        actionButton(inputId = 'bitcoin', label = "Bitcoin", class = "btn-category"),
        actionButton(inputId = 'ethereum', label = "Ethereum", class = "btn-category"),
        actionButton(inputId = 'l2s', label = "EVM/L2s", class = "btn-category"),
        actionButton(inputId = 'solana', label = "Solana", class = "btn-category"),
        actionButton(inputId = 'avalanche', label = "Avalanche", class = "btn-category"),
        actionButton(inputId = 'polygon', label = "Polygon", class = "btn-category"),
        actionButton(inputId = 'aptos', label = "Aptos", class = "btn-category"),
        actionButton(inputId = 'axelar', label = "Axelar", class = "btn-category"),
        actionButton(inputId = 'sei', label = "Sei", class = "btn-category")
      )
      ),
  fluidRow(
    column(12, align = "center",
           textInput("custom_search", "", value = "", width = "50%", 
                     placeholder = "Put your own keywords here to filter top 20 summaries")
    )
  )
  ,
  div(class = "content-area", 
      conditionalPanel(
        condition = "output.view == 'overall'",
            uiOutput("cards")
      )
  )
  )
  
)

server <- function(input, output, session) {

  observeEvent(input$all, { updateTextInput(session, inputId = "custom_search", value = "") })
  observeEvent(input$bitcoin, { updateTextInput(session, inputId = "custom_search", value = "btc bitcoin proof of work satoshi") })
  observeEvent(input$ethereum, { updateTextInput(session, inputId = "custom_search", value = "eth ether ethereum evm mainnet defi nfts") })
  observeEvent(input$l2s, { updateTextInput(session, inputId = "custom_search", value = "arb arbitrum op optimism base blast layer-2 L2") })
  observeEvent(input$solana, { updateTextInput(session, inputId = "custom_search", value = "sol solana raydium jupiter jup") })
  observeEvent(input$avalanche, { updateTextInput(session, inputId = "custom_search", value = "avax avalanche subnets") })
  observeEvent(input$polygon, { updateTextInput(session, inputId = "custom_search", value = "matic pol polygon") })
  observeEvent(input$aptos, { updateTextInput(session, inputId = "custom_search", value = "aptos apt thala aries") })
  observeEvent(input$axelar, { updateTextInput(session, inputId = "custom_search", value = "squid axlusdc axl axelar") })
  observeEvent(input$sei, { updateTextInput(session, inputId = "custom_search", value = "sei seiv2 seiEVM seiyans") })
  
  selected_subject <- reactiveVal(NULL)
  view <- reactiveVal("overall")
  
  output$view <- reactive({
    view()
  })
  outputOptions(output, "view", suspendWhenHidden = FALSE)
  
  output$cards <- renderUI({
    
    if(nchar(input$custom_search) > 3){
      
      summary_rank <- rank_corpus(input$custom_search, corpus_ = latest_ai_summaries$SUMMARY, top_n = 20)
      filter_ai_summaries <- latest_ai_summaries[summary_rank, ]
      
    } else {
      filter_ai_summaries <- latest_ai_summaries
    }
    
    apply(X = filter_ai_summaries, MARGIN = 1, function(x){
      generateCard(x["DAY_"], x["SUBJECT"], x["SUMMARY"])
     })
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
