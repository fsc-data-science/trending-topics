library(shiny)
library(shinyjs)

# Define UI
ui <- fluidPage(
  titlePanel("Flipside Trending"),
  
  # Main page
  div(id = "main-page",
      # Date Navigation
      fluidRow(
        column(4, actionButton("date_1", "July 30")),
        column(4, actionButton("date_2", "July 31")),
        column(4, actionButton("date_3", "Aug 1"))
      ),
      
      # Categories
      fluidRow(
        column(12, 
               actionButton("cat_ethereum", "Ethereum"),
               actionButton("cat_evm", "EVM/L2s"),
               actionButton("cat_solana", "Solana"),
               actionButton("cat_aptos", "Aptos"),
               actionButton("cat_sei", "Sei"),
               actionButton("cat_axelar", "Axelar")
        )
      ),
      
      # Summaries
      fluidRow(
        column(12, 
               uiOutput("summaries")
        )
      )
  ),
  
  # Detail page (initially hidden)
  div(id = "detail-page", style = "display: none;",
      fluidRow(
        column(12, 
               actionButton("back", "Back"),
               actionButton("cat_ethereum_2", "Ethereum"),
               actionButton("cat_evm_2", "EVM/L2s"),
               actionButton("cat_solana_2", "Solana"),
               actionButton("cat_aptos_2", "Aptos"),
               actionButton("cat_sei_2", "Sei"),
               actionButton("cat_axelar_2", "Axelar")
        )
      ),
      fluidRow(
        column(12, 
               h3("Top Ranked Tweets"),
               uiOutput("top_tweets")
        )
      )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  # Reactive value to store current page
  current_page <- reactiveVal("main")
  
  # Generate dummy summaries
  output$summaries <- renderUI({
    summaries <- lapply(1:10, function(i) {
      actionLink(paste0("summary_", i), paste("Subject:", i, "Summary"))
    })
    tagList(summaries)
  })
  
  # Handle summary clicks
  observeEvent(input[["summary_1"]], {
    current_page("detail")
    shinyjs::hide("main-page")
    shinyjs::show("detail-page")
  })
  
  # Handle back button
  observeEvent(input$back, {
    current_page("main")
    shinyjs::show("main-page")
    shinyjs::hide("detail-page")
  })
  
  # Generate dummy top tweets
  output$top_tweets <- renderUI({
    tweets <- lapply(1:5, function(i) {
      div(paste("Tweet", i, ": This is a sample tweet text."))
    })
    tagList(tweets)
  })
}

# Run the application
shinyApp(ui = ui, server = server)