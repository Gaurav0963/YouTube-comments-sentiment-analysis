#!/bin/bash

CHANNEL_URL="https://www.youtube.com/@veritasium"

echo "🔍 Running Python script to fetch comments..."
python fetch.py "$CHANNEL_URL"

if [ ! -f "comments.csv" ]; then
    echo "❌ Error: comments.csv not found."
    exit 1
fi

echo "📊 Launching R Shiny App..."
Rscript -e "shiny::runApp('shiny_app', launch.browser = TRUE)"