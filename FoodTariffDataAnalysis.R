#Step 1
# Install packages (run only once)
install.packages(c("readxl", "dplyr", "ggplot2", "lubridate", "tidyr", "zoo", "writexl", "readr", "corrplot"))

# Load libraries (run every session)
library(readxl)
library(dplyr)
library(ggplot2)
library(lubridate)
library(tidyr)
library(zoo)
library(writexl)
library(readr)
library(corrplot)
library(purrr)

# Step 2
# Set working directory
setwd("C:/Users/renzo/Documents/GitHub/ISBUSAN-CaseStudy")

# Load raw data
raw_data <- read_excel("ISBUSANFoodStockPrices.xlsx", sheet = "JFC", skip = 3)

# Clean and structure data correctly
stock_data <- raw_data %>%
  select(
    # JFC data (columns 2-6)
    JFC_Date = Date...2, JFC_Close = Close...3, JFC_Open = Open...4, JFC_High = High...5, JFC_Low = Low...6,
    # URC data (columns 8-12) 
    URC_Date = Date...8, URC_Close = Close...9, URC_Open = Open...10, URC_High = High...11, URC_Low = Low...12,
    # CNPF data (columns 14-18)
    CNPF_Date = Date...14, CNPF_Close = Close...15, CNPF_Open = Open...16, CNPF_High = High...17, CNPF_Low = Low...18,
    # GSMI data (columns 20-24)
    GSMI_Date = Date...20, GSMI_Close = Close...21, GSMI_Open = Open...22, GSMI_High = High...23, GSMI_Low = Low...24,
    # MONDE data (columns 26-30)
    MONDE_Date = Date...26, MONDE_Close = Close...27, MONDE_Open = Open...28, MONDE_High = High...29, MONDE_Low = Low...30
  )

# Convert Excel dates to proper dates
date_cols <- c("JFC_Date", "URC_Date", "CNPF_Date", "GSMI_Date", "MONDE_Date")
for(col in date_cols) {
  stock_data[[col]] <- as.Date(stock_data[[col]], origin = "1899-12-30")
}

# Add main Date column
stock_data$Date <- stock_data$JFC_Date

# Verify data
head(stock_data)
summary(stock_data$Date)

# Step 3
# Define companies
companies <- c("JFC", "URC", "CNPF", "GSMI", "MONDE")

# Define key tariff dates (CORRECTED based on fact-check)
tariff_inauguration <- as.Date("2025-01-20")  # Trump inauguration
tariff_announcement <- as.Date("2025-04-02")  # 17% tariff announcement ("Liberation Day")
tariff_escalation <- as.Date("2025-07-09")    # 20% tariff letter posted
tariff_negotiation <- as.Date("2025-07-22")   # Reduced to 19% after Marcos-Trump meeting

# Create before/after periods (using inauguration as the main dividing line)
before_tariff <- stock_data[stock_data$Date < tariff_inauguration, ]
after_tariff <- stock_data[stock_data$Date >= tariff_inauguration, ]

cat("Before period:", nrow(before_tariff), "days\n")
cat("After period:", nrow(after_tariff), "days\n")

#Step 4
#Calculate Daily Returns and Volatility
for(company in companies) {
  close_col <- paste0(company, "_Close")
  returns_col <- paste0(company, "_Returns")
  
  # Calculate log returns
  stock_data[[returns_col]] <- c(NA, diff(log(stock_data[[close_col]])))
}

# Recreate before/after datasets with returns included
before_tariff <- stock_data[stock_data$Date < tariff_inauguration, ]
after_tariff <- stock_data[stock_data$Date >= tariff_inauguration, ]

# Calculate volatility (standard deviation) before and after
volatility_before <- sapply(companies, function(x) {
  returns_col <- paste0(x, "_Returns")
  sd(before_tariff[[returns_col]], na.rm = TRUE)
})

volatility_after <- sapply(companies, function(x) {
  returns_col <- paste0(x, "_Returns")
  sd(after_tariff[[returns_col]], na.rm = TRUE)
})

# Create volatility comparison
volatility_comparison <- data.frame(
  Company = companies,
  Before_Tariff = round(volatility_before, 4),
  After_Tariff = round(volatility_after, 4),
  Change = round(volatility_after - volatility_before, 4),
  Pct_Change = round(((volatility_after - volatility_before) / volatility_before) * 100, 2)
)

print("VOLATILITY ANALYSIS:")
print(volatility_comparison)

# Step 5: 
# Calculate Moving Averages  
for(company in companies) {
  close_col <- paste0(company, "_Close")
  ma7_col <- paste0(company, "_MA7")
  ma30_col <- paste0(company, "_MA30")
  
  stock_data[[ma7_col]] <- rollmean(stock_data[[close_col]], 7, fill = NA, align = "right")
  stock_data[[ma30_col]] <- rollmean(stock_data[[close_col]], 30, fill = NA, align = "right")
}

# Recreate datasets with MA columns included
before_tariff <- stock_data[stock_data$Date < tariff_inauguration, ]
after_tariff <- stock_data[stock_data$Date >= tariff_inauguration, ]

# Calculate moving average changes
ma_changes <- data.frame(
  Company = companies,
  MA7_Before = sapply(companies, function(x) {
    ma_col <- paste0(x, "_MA7")
    mean(before_tariff[[ma_col]], na.rm = TRUE)
  }),
  MA7_After = sapply(companies, function(x) {
    ma_col <- paste0(x, "_MA7")
    mean(after_tariff[[ma_col]], na.rm = TRUE)
  })
)

ma_changes$MA7_Change_Pct <- round(((ma_changes$MA7_After - ma_changes$MA7_Before) / ma_changes$MA7_Before) * 100, 2)

print("MOVING AVERAGE ANALYSIS:")
print(ma_changes)

# Step 6: 
# Statistical Significance Testing
t_test_results <- data.frame(
  Company = companies,
  p_value = NA,
  significant = NA,
  mean_before = NA,
  mean_after = NA
)

for(i in 1:length(companies)) {
  company <- companies[i]
  returns_col <- paste0(company, "_Returns")
  
  before_returns <- before_tariff[[returns_col]][!is.na(before_tariff[[returns_col]])]
  after_returns <- after_tariff[[returns_col]][!is.na(after_tariff[[returns_col]])]
  
  if(length(before_returns) > 1 && length(after_returns) > 1) {
    t_result <- t.test(before_returns, after_returns)
    t_test_results$p_value[i] <- round(t_result$p.value, 4)
    t_test_results$significant[i] <- t_result$p.value < 0.05
    t_test_results$mean_before[i] <- round(mean(before_returns), 6)
    t_test_results$mean_after[i] <- round(mean(after_returns), 6)
  }
}

print("STATISTICAL SIGNIFICANCE:")
print(t_test_results)

# Step 7: 
#Create Visualizations
stock_long <- stock_data %>%
  select(Date, ends_with("_Close")) %>%
  pivot_longer(cols = -Date, names_to = "Company", values_to = "Price") %>%
  mutate(Company = gsub("_Close", "", Company))

ggplot(stock_long, aes(x = Date, y = Price, color = Company)) +
  geom_line(size = 1) +
  geom_vline(xintercept = tariff_inauguration, linetype = "dashed", color = "red", size = 1) +
  geom_vline(xintercept = tariff_announcement, linetype = "dashed", color = "orange", size = 0.8) +
  geom_vline(xintercept = tariff_escalation, linetype = "dashed", color = "darkred", size = 0.8) +
  geom_vline(xintercept = tariff_negotiation, linetype = "dashed", color = "green", size = 0.8) +
  annotate("text", x = tariff_inauguration, y = max(stock_long$Price, na.rm = TRUE), 
           label = "Trump Inauguration", angle = 90, vjust = 1.2) +
  annotate("text", x = tariff_announcement, y = max(stock_long$Price, na.rm = TRUE) * 0.95, 
           label = "17% Tariff", angle = 90, vjust = 1.2) +
  annotate("text", x = tariff_escalation, y = max(stock_long$Price, na.rm = TRUE) * 0.9, 
           label = "20% Tariff", angle = 90, vjust = 1.2) +
  annotate("text", x = tariff_negotiation, y = max(stock_long$Price, na.rm = TRUE) * 0.85, 
           label = "19% Deal", angle = 90, vjust = 1.2) +
  labs(title = "Philippine Food Company Stock Prices - Tariff Impact",
       subtitle = "Key events: Inauguration (Jan 20), 17% announcement (Apr 2), 20% escalation (Jul 9), 19% deal (Jul 22)",
       x = "Date", y = "Stock Price (PHP)") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("stock_prices_tariff_impact.png", width = 12, height = 8, dpi = 300)

# Step 8: SENTIMENT CORRELATION ANALYSIS
cat("\n=== STARTING SENTIMENT CORRELATION ANALYSIS ===\n")

# Load sentiment data
sentiment_data <- tryCatch({
  read_csv("reddit_sentiment_detailed.csv")
}, error = function(e) {
  cat("Warning: reddit_sentiment_detailed.csv not found. Skipping sentiment analysis.\n")
  return(NULL)
})

if (!is.null(sentiment_data)) {
  # Define key tariff dates for event analysis (CORRECTED)
  key_dates <- as.Date(c("2025-04-02", "2025-07-09"))  # 17% and 20% tariff announcements
  
  # Aggregate daily sentiment scores
  daily_sentiment <- sentiment_data %>%
    mutate(date = as.Date(date)) %>%
    group_by(date) %>%
    summarise(
      avg_sentiment = mean(combined_score, na.rm = TRUE),
      sentiment_count = n(),
      avg_vader = mean(vader_compound, na.rm = TRUE),
      .groups = 'drop'
    )
  
  cat("Daily Sentiment Summary:\n")
  print(daily_sentiment)
  
  # Calculate daily stock returns for correlation analysis
  stock_returns <- stock_data %>%
    select(Date, ends_with("_Close"), ends_with("_Returns")) %>%
    pivot_longer(cols = ends_with("_Close"), names_to = "Company", values_to = "Close") %>%
    mutate(Company = gsub("_Close", "", Company)) %>%
    arrange(Date, Company) %>%
    group_by(Company) %>%
    mutate(daily_return = (Close - lag(Close)) / lag(Close) * 100) %>%
    ungroup() %>%
    filter(!is.na(daily_return))
  
  # Combine sentiment and stock data
  correlation_data <- stock_returns %>%
    left_join(daily_sentiment, by = c("Date" = "date")) %>%
    filter(!is.na(avg_sentiment))
  
  cat("Combined dataset observations:", nrow(correlation_data), "\n")
  
  # Overall correlation analysis
  overall_correlations <- correlation_data %>%
    group_by(Company) %>%
    summarise(
      correlation_sentiment = cor(daily_return, avg_sentiment, use = "complete.obs"),
      correlation_vader = cor(daily_return, avg_vader, use = "complete.obs"),
      n_observations = n(),
      .groups = 'drop'
    )
  
  cat("OVERALL CORRELATIONS BY COMPANY:\n")
  print(overall_correlations)
  
  # Event window analysis function
  create_event_window <- function(event_date, window_days = 3) {
    start_date <- event_date - window_days
    end_date <- event_date + window_days
    
    event_data <- correlation_data %>%
      filter(Date >= start_date & Date <= end_date)
    
    if(nrow(event_data) > 0) {
      event_correlations <- event_data %>%
        group_by(Company) %>%
        summarise(
          correlation = cor(daily_return, avg_sentiment, use = "complete.obs"),
          avg_return = mean(daily_return, na.rm = TRUE),
          avg_sentiment = mean(avg_sentiment, na.rm = TRUE),
          n_obs = n(),
          .groups = 'drop'
        ) %>%
        mutate(event_date = event_date)
      
      return(event_correlations)
    }
    return(NULL)
  }
  
  # Analyze each key event
  event_results <- map_dfr(key_dates, create_event_window)
  
  if(nrow(event_results) > 0) {
    cat("EVENT WINDOW CORRELATIONS:\n")
    print(event_results)
  }
  
  # Statistical significance testing for correlations
  perform_correlation_test <- function(data, company_name) {
    company_data <- data %>% filter(Company == company_name, !is.na(avg_sentiment))
    
    if(nrow(company_data) >= 3) {
      test_result <- cor.test(company_data$daily_return, company_data$avg_sentiment)
      
      return(data.frame(
        Company = company_name,
        correlation = test_result$estimate,
        p_value = test_result$p.value,
        significant = test_result$p.value < 0.05,
        n_observations = nrow(company_data)
      ))
    }
    return(NULL)
  }
  
  significance_results <- map_dfr(companies, ~perform_correlation_test(correlation_data, .x))
  
  if(nrow(significance_results) > 0) {
    cat("CORRELATION STATISTICAL SIGNIFICANCE:\n")
    print(significance_results)
    
    # Create correlation visualization
    ggplot(significance_results, aes(x = Company, y = correlation)) +
      geom_col(fill = ifelse(significance_results$correlation > 0, "green", "red"), alpha = 0.7) +
      geom_hline(yintercept = 0, linetype = "dashed") +
      geom_hline(yintercept = c(-0.3, 0.3), linetype = "dashed", color = "blue", alpha = 0.5) +
      labs(title = "Sentiment-Stock Return Correlations by Company",
           subtitle = "Blue lines indicate ±0.3 threshold for meaningful relationship",
           x = "Company", y = "Correlation Coefficient") +
      theme_minimal() +
      coord_cartesian(ylim = c(-1, 1))
    
    ggsave("sentiment_stock_correlations.png", width = 10, height = 6)
  }
  
  # Time series visualization
  if(nrow(correlation_data) > 0) {
    daily_returns_avg <- correlation_data %>%
      group_by(Date) %>%
      summarise(
        avg_return = mean(daily_return, na.rm = TRUE),
        avg_sentiment = mean(avg_sentiment, na.rm = TRUE),
        .groups = 'drop'
      )
    
    ggplot(daily_returns_avg, aes(x = Date)) +
      geom_line(aes(y = avg_return, color = "Stock Returns")) +
      geom_line(aes(y = avg_sentiment * 5, color = "Sentiment (×5)")) +
      geom_vline(xintercept = key_dates, linetype = "dashed", color = "red", alpha = 0.7) +
      scale_color_manual(values = c("Stock Returns" = "blue", "Sentiment (×5)" = "green")) +
      labs(title = "Daily Average Stock Returns vs Sentiment",
           subtitle = "Red lines mark tariff announcement dates (Apr 2, Jul 9)",
           x = "Date", y = "Value", color = "Metric") +
      theme_minimal()
    
    ggsave("sentiment_returns_timeline.png", width = 12, height = 6)
  }
} else {
  # Create empty results for export
  overall_correlations <- data.frame()
  event_results <- data.frame()
  significance_results <- data.frame()
  daily_sentiment <- data.frame()
}

# Step 9: 
#Create Summary for Tableau
tableau_data <- stock_data %>%
  select(Date, ends_with("_Close"), ends_with("_MA7"), ends_with("_MA30")) %>%
  pivot_longer(cols = -Date, names_to = "Metric", values_to = "Value") %>%
  separate(Metric, into = c("Company", "Type"), sep = "_") %>%
  pivot_wider(names_from = Type, values_from = Value)

# Add tariff period indicator
tableau_data$Tariff_Period <- ifelse(tableau_data$Date >= tariff_inauguration, "After", "Before")

# Export for Tableau
write.csv(tableau_data, "Philippine_Food_Stocks_Tableau.csv", row.names = FALSE)

# Step 10: Comprehensive Summary Report
summary_report <- list(
  "Volatility_Analysis" = volatility_comparison,
  "Moving_Average_Changes" = ma_changes,
  "Statistical_Tests" = t_test_results,
  "Overall_Sentiment_Correlations" = overall_correlations,
  "Event_Window_Analysis" = event_results,
  "Correlation_Significance" = significance_results,
  "Daily_Sentiment_Summary" = daily_sentiment,
  "Raw_Stock_Data" = stock_data
)

# Add correlation summary if sentiment analysis was performed
if(!is.null(sentiment_data) && nrow(significance_results) > 0) {
  correlation_summary <- data.frame(
    Metric = c("Companies with |r| > 0.3", "Significant correlations (p < 0.05)", 
               "Average correlation", "Sentiment data points", "Date range"),
    Value = c(
      sum(abs(significance_results$correlation) > 0.3, na.rm = TRUE),
      sum(significance_results$significant, na.rm = TRUE),
      round(mean(significance_results$correlation, na.rm = TRUE), 3),
      nrow(daily_sentiment),
      paste(min(correlation_data$Date), "to", max(correlation_data$Date))
    )
  )
  summary_report$Correlation_Summary <- correlation_summary
}

write_xlsx(summary_report, "Tariff_Impact_Analysis_Complete.xlsx")

cat("\n=== ANALYSIS COMPLETE! ===\n")
cat("Files generated:\n")
cat("- Philippine_Food_Stocks_Tableau.csv\n")
cat("- Tariff_Impact_Analysis_Complete.xlsx\n")
cat("- stock_prices_tariff_impact.png\n")
if(!is.null(sentiment_data)) {
  cat("- sentiment_stock_correlations.png\n")
  cat("- sentiment_returns_timeline.png\n")
}

# Print final summary
cat("\n=== FINAL KPI SUMMARY ===\n")
cat("KPI 1 - Volatility Analysis: COMPLETE\n")
cat("KPI 2 - Moving Average Analysis: COMPLETE\n")
cat("KPI 3 - Sentiment-Stock Correlation:", ifelse(!is.null(sentiment_data), "COMPLETE", "SKIPPED (no sentiment data)"), "\n")
cat("KPI 4 - Public Sentiment Analysis:", ifelse(!is.null(sentiment_data), "COMPLETE", "SKIPPED (no sentiment data)"), "\n")