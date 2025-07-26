# Impact of US Tariffs on Philippine Food Company Stocks

## Project Overview
This Business Intelligence case study analyzes how Trump administration tariffs affected publicly listed Philippine food companies' stock prices. We combine financial market data with Reddit sentiment analysis to understand both market and public reaction to the tariff announcements.

## Key Questions
1. How did stock volatility change after tariff announcements?
2. What were the moving average trends before/after key dates?
3. Is there correlation between public sentiment and stock performance?
4. What was the public sentiment regarding Philippine food exports?

## Key Findings


## Technologies Used
- **R Studio**: Stock price analysis, volatility calculations
- **Python**: Sentiment analysis (VADER, TextBlob), Reddit scraping
- **Tableau**: Data visualization dashboard
- **Excel**: Data storage and summary reports

## Repository Structure
```
ISBUSAN-CaseStudy/
├── FoodTariffDataAnalysis.R          # Main R analysis script
├── SentimentAnalysis.py               # Python sentiment analysis
├── ISBUSANFoodStockPrices.xlsx       # Raw stock price data
├── Philippine_Food_Stocks_Tableau.csv # Tableau-ready data
├── Tariff_Impact_Analysis_Complete.xlsx # Comprehensive results
├── reddit_sentiment_detailed.csv      # Reddit sentiment results
├── reddit_daily_summary.csv          # Aggregated daily sentiment
├── stock_prices_tariff_impact.png    # Stock price visualization
├── sentiment_stock_correlations.png   # Correlation chart
└── sentiment_returns_timeline.png     # Timeline visualization
```

## Getting Started

### Prerequisites
- R (v4.0+) with packages: `readxl`, `dplyr`, `ggplot2`, `zoo`, `corrplot`
- Python (v3.8+) with packages: `pandas`, `nltk`, `textblob`, `requests`
- Tableau Desktop (for dashboard creation)

### Running the Analysis

1. **Stock Analysis (R)**:
```r
# Set working directory
setwd("path/to/ISBUSAN-CaseStudy")
# Run analysis
source("FoodTariffDataAnalysis.R")
```

2. **Sentiment Analysis (Python)**:
```bash
python SentimentAnalysis.py
```

## Data Sources
- **Stock Data**: Philippine Stock Exchange (PSE) - JFC, URC, CNPF, GSMI, MONDE
- **Sentiment Data**: Reddit discussions from r/Philippines and related subreddits
- **Period**: January 1 - July 23, 2025

## Companies Analyzed
| Ticker | Company |
|--------|---------|
| JFC | Jollibee Foods Corp |
| URC | Universal Robina Corp |
| CNPF | Century Pacific Food |
| GSMI | Ginebra San Miguel |
| MONDE | Monde Nissin |

## Key Tariff Events
- **January 20, 2025**: Trump inauguration, initial tariff threats
- **April 2, 2025**: 17% tariff announcement ("Liberation Day")
- **July 9, 2025**: 20% tariff letter posted
- **July 22, 2025**: Reduced to 19% after Marcos-Trump meeting

## Team Members
- **Stephanie Anne Basco**: Data Collection, R Analysis
- **Justin Patrick Buatis**: Tableau Dashboard
- **Trisha Isabella Padilla**: Research, Presentation
- **Jose Lorenzo Santos**: R/Python Analysis, Sentiment Analysis

## License
Academic project for ISBUSAN course at De La Salle University
