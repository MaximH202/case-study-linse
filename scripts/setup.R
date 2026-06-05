# Use this script for all boilerplate code 
# that you typically load at the beginning of any work

# Ensure renv is present and packages are in sync
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
if (file.exists("renv.lock")) renv::restore() else renv::init()
if (!requireNamespace("furrr", quietly = TRUE)) {
  install.packages("furrr")
}
if (!requireNamespace("scales", quietly = TRUE)) {
  install.packages("scales")
}



# Load all required libraries
pacman::p_load(tidyverse, janitor, skimr, jsonlite, reticulate, furrr, scales)

# Ensure Python virtual environment exists, then activate it
venv_path <- normalizePath(".python-env", mustWork = FALSE)
if (!dir.exists(venv_path)) {
  virtualenv_create(venv_path)
}
use_virtualenv(venv_path, required = TRUE)

# Define a log function to get feedback in R from a Python function
log_to_r <- function(msg) {
  cat("[py]", msg, "\n")
}

# Add more steps here if necessary...