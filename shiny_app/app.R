library(shiny)
library(shinydashboard)
library(tidytext)
library(dplyr)
library(ggplot2)
library(wordcloud)
library(readr)
library(syuzhet)
library(stopwords)
library(fmsb)

read_comments <- function() {
  req(file.exists("../comments.csv"))
  read_csv("../comments.csv", show_col_types = FALSE)
}

ui <- dashboardPage(
  dashboardHeader(title = "YouTube Sentiment Analyzer"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Sentiment Summary", tabName = "sentiment", icon = icon("chart-bar")),
      menuItem("Word Cloud", tabName = "wordcloud", icon = icon("cloud")),
      menuItem("Polarity Histogram", tabName = "polarity", icon = icon("balance-scale")),
      menuItem("Length Distribution", tabName = "length", icon = icon("ruler-horizontal")),
      menuItem("Radar Chart", tabName = "radar", icon = icon("chart-pie")),
      menuItem("Top Comments", tabName = "top", icon = icon("star")),
      menuItem("Raw Comments", tabName = "table", icon = icon("table")),
      actionButton("refresh", "🔁 Refresh Data")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "sentiment", plotOutput("sentimentPlot")),
      tabItem(tabName = "wordcloud", plotOutput("wordcloudPlot")),
      tabItem(tabName = "polarity", plotOutput("polarityPlot")),
      tabItem(tabName = "length", plotOutput("lengthPlot")),
      tabItem(tabName = "radar", plotOutput("radarPlot")),
      tabItem(tabName = "top", fluidRow(
        box(title = "Top Positive Comments", tableOutput("topPositive")),
        box(title = "Top Negative Comments", tableOutput("topNegative"))
      )),
      tabItem(tabName = "table", tableOutput("commentTable"))
    )
  )
)

server <- function(input, output) {
  comment_data <- reactiveVal()

  observeEvent(input$refresh, {
    comments <- read_comments()
    comments$polarity <- get_sentiment(as.character(comments$`Comment Text`))
    comments$length <- nchar(as.character(comments$`Comment Text`))
    comment_data(comments)
  })

  output$sentimentPlot <- renderPlot({
    req(comment_data())
    sentiments <- get_nrc_sentiment(as.character(comment_data()$`Comment Text`))
    barplot(colSums(sentiments[, 1:8]), las=2, col=rainbow(8),
            main="Emotional Sentiment Distribution")
  })

  output$wordcloudPlot <- renderPlot({
    req(comment_data())
    words <- comment_data() %>%
      unnest_tokens(word, `Comment Text`) %>%
      anti_join(stop_words, by = "word") %>%
      count(word, sort = TRUE)
    wordcloud(words = words$word, freq = words$n, max.words = 100,
              colors = brewer.pal(8, "Dark2"))
  })

  output$polarityPlot <- renderPlot({
    req(comment_data())
    hist(comment_data()$polarity, col = "steelblue",
         main = "Polarity Distribution", xlab = "Sentiment Score")
  })

  output$lengthPlot <- renderPlot({
    req(comment_data())
    hist(comment_data()$length, col = "darkorange",
         main = "Comment Length Distribution", xlab = "Characters")
  })

  output$radarPlot <- renderPlot({
    req(comment_data())
    sentiments <- get_nrc_sentiment(as.character(comment_data()$`Comment Text`))
    radar_data <- as.data.frame(t(colSums(sentiments[, 1:8])))
    radar_data <- rbind(rep(max(radar_data), 8), rep(0, 8), radar_data)
    radarchart(radar_data, axistype=1, pcol="red", pfcol=rgb(1,0,0,0.4), plwd=2,
               title="Radar Chart of Emotions")
  })

  output$topPositive <- renderTable({
    req(comment_data())
    comment_data() %>%
      arrange(desc(polarity)) %>%
      head(5) %>%
      select(`Comment Author`, `Comment Text`, polarity)
  })

  output$topNegative <- renderTable({
    req(comment_data())
    comment_data() %>%
      arrange(polarity) %>%
      head(5) %>%
      select(`Comment Author`, `Comment Text`, polarity)
  })

  output$commentTable <- renderTable({
    req(comment_data())
    head(comment_data(), 20)
  })
}

shinyApp(ui = ui, server = server)