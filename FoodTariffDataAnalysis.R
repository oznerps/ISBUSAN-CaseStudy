#Step 1
# Install packages (run only once)
install.packages(c("readxl", "dplyr", "ggplot2", "lubridate", "tidyr", "zoo", "writexl"))

# Load libraries (run every session)
library(readxl)
library(dplyr)
library(ggplot2)
library(lubridate)
library(tidyr)
library(zoo)
library(writexl)

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

# Define key tariff dates (adjust based on your research)
tariff_announcement <- as.Date("2025-01-20")  # Trump inauguration
tariff_implementation <- as.Date("2025-02-01")  # Adjust actual date

# Create before/after periods
before_tariff <- stock_data[stock_data$Date < tariff_announcement, ]
after_tariff <- stock_data[stock_data$Date >= tariff_announcement, ]

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
before_tariff <- stock_data[stock_data$Date < tariff_announcement, ]
after_tariff <- stock_data[stock_data$Date >= tariff_announcement, ]

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
before_tariff <- stock_data[stock_data$Date < tariff_announcement, ]
after_tariff <- stock_data[stock_data$Date >= tariff_announcement, ]

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
  geom_vline(xintercept = tariff_announcement, linetype = "dashed", color = "red", size = 1) +
  annotate("text", x = tariff_announcement, y = max(stock_long$Price, na.rm = TRUE), 
           label = "Tariff Announcement", angle = 90, vjust = 1.2) +
  labs(title = "Philippine Food Company Stock Prices - Tariff Impact",
       x = "Date", y = "Stock Price (PHP)") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("stock_prices_tariff_impact.png", width = 12, height = 8, dpi = 300)

# Step 8: 
#Create Summary for Tableau
tableau_data <- stock_data %>%
  select(Date, ends_with("_Close"), ends_with("_MA7"), ends_with("_MA30")) %>%
  pivot_longer(cols = -Date, names_to = "Metric", values_to = "Value") %>%
  separate(Metric, into = c("Company", "Type"), sep = "_") %>%
  pivot_wider(names_from = Type, values_from = Value)

# Add tariff period indicator
tableau_data$Tariff_Period <- ifelse(tableau_data$Date >= tariff_announcement, "After", "Before")

# Export for Tableau
write.csv(tableau_data, "Philippine_Food_Stocks_Tableau.csv", row.names = FALSE)

# Summary report
summary_report <- list(
  "Volatility_Analysis" = volatility_comparison,
  "Moving_Average_Changes" = ma_changes,
  "Statistical_Tests" = t_test_results,
  "Raw_Data" = stock_data
)

write_xlsx(summary_report, "Tariff_Impact_Analysis_Complete.xlsx")

cat("Analysis complete! Files saved:\n")
cat("- Philippine_Food_Stocks_Tableau.csv\n")
cat("- Tariff_Impact_Analysis_Complete.xlsx\n")
cat("- stock_prices_tariff_impact.png\n")