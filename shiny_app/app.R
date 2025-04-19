library(shiny)
library(tidytext)
library(dplyr)
library(ggplot2)
library(wordcloud)
library(readr)
library(syuzhet)
library(stopwords)

read_comments <- function() {
  req(file.exists("../comments.csv"))
  # read_csv("../comments.csv")
  read_csv("../comments.csv", show_col_types = FALSE)

}

ui <- fluidPage(
  titlePanel("YouTube Comment Sentiment Analysis"),
  sidebarLayout(
    sidebarPanel(
      helpText("Click Refresh after fetching comments using Python."),
      actionButton("refresh", "🔁 Refresh Data")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Sentiment Plot", plotOutput("sentimentPlot")),
        tabPanel("Word Cloud", plotOutput("wordcloudPlot")),
        tabPanel("Raw Comments", tableOutput("commentTable"))
      )
    )
  )
)

server <- function(input, output) {
  comment_data <- reactiveVal()

  observeEvent(input$refresh, {
    comments <- read_comments()
    comment_data(comments)
  })

  output$sentimentPlot <- renderPlot({
    req(comment_data())
    comments <- comment_data()

    # ✅ Ensure it's a character vector
    sentiments <- get_nrc_sentiment(as.character(comments$`Comment Text`))
    sentiment_summary <- colSums(sentiments[, 1:8])
    barplot(sentiment_summary, las = 2, col = rainbow(8),
            main = "Emotional Sentiment Distribution")
  })

  output$wordcloudPlot <- renderPlot({
    req(comment_data())
    comments <- comment_data()

    # ✅ Tokenize and remove stopwords
    words <- comments %>%
      unnest_tokens(word, `Comment Text`) %>%
      anti_join(stop_words, by = "word") %>%  # From tidytext
      count(word, sort = TRUE)

    if (nrow(words) == 0) {
      showNotification("⚠️ No words found for word cloud", type = "warning")
      return(NULL)
    }

    wordcloud(words = words$word,
              freq = words$n,
              max.words = 100,
              colors = brewer.pal(8, "Dark2"))
  })

  output$commentTable <- renderTable({
    req(comment_data())
    head(comment_data(), 20)
  })
}

shinyApp(ui = ui, server = server)
