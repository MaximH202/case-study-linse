source("scripts/setup.R")

# Read the consolidated menus
menus <- read_csv("data/menus_consolidated.csv") |> 
  mutate(
    student_service = as_factor(student_service),
    cafeteria = as_factor(cafeteria)
  )

# Run a subscript
source("scripts/subscripts_analyze/analyze_step_1.R")

# Create a visualization (example)
p <- menus |> 
  filter(year(date) > 2014) |>
  filter(year(date) < 2025) |> 
  mutate(year = lubridate::floor_date(date, unit = "years")) |> 
  ggplot() +
  aes(x = year) +
  geom_bar() +
  theme_bw()

# Save a plot to file (example)
ggsave("communications/visualizations/scatter_plot.svg", plot = p)
