library(request)
library(jsonlite)
library(tidyverse)

# API BCRA ####
# ESTA NUEVA VERSIÓN ES SIN TOKEN
prueba <- api('https://api.bcra.gob.ar/estadisticas/v3.0/monetarias/') %>%
  http()

prueba[2]

# API FRED ####
# CONSEGUIR TOKEN PERSONAL Y GUARDARLA EN UN ARCHIVO EN ESTE DIRECTORIO:
api_key_path <- "keys/fred_api_key.txt"

# Chequeamos primero si existe
if (file.exists(api_key_path)) {
  api_key <- readLines(api_key_path, warn = FALSE) %>% 
    trimws()
} else {
  stop("API key file not found!")
}

endpoint <- "https://api.stlouisfed.org/fred/series/observations"

params <- list(
  series_id = "DEXCHUS",
  api_key = api_key,
  file_type = "json"  # Ensure JSON output
)

response <- GET(url = endpoint, query = params)

if (http_status(response)$category == "Success") {
  data <- content(response, "text", encoding = "UTF-8") %>% 
    fromJSON()

  df <- data$observations %>% 
    select(date, value) %>% 
    mutate(
      value = ifelse(value == ".", NA, value),
      value = as.numeric(value),
      # Explicitly define the date format
      date = as.Date(date, format = "%Y-%m-%d")  # Format: Year-Month-Day
    )
  
  # Para ver el último TCN CNY/USD
  latest_rate <- df %>% 
    filter(!is.na(value)) %>% 
    tail(1)

  cat("Último TCN CNY/USD (FRED):", latest_rate$value, "on", format(latest_rate$date, "%Y-%m-%d"))
} else {
  cat("Error:", http_status(response)$message)
}