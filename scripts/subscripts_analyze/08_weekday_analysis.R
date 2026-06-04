# 8. Wochentags-Analyse: Veggie-Tag Effekt ---------------------------------

library(dplyr)
library(readr)
library(lubridate)
library(ggplot2)

menus_classified <- read_csv("data/menus_classified.csv", show_col_types = FALSE)

# Wochentag aus Datum extrahieren
weekday_data <- menus_classified |>
  filter(!is.na(group_level_1), !is.na(actual_output), actual_output > 0) |>
  filter(!is.na(date)) |>
  mutate(
    weekday = wday(date, label = TRUE, abbr = FALSE, week_start = 1),
    # Wir fassen vegan und vegetarisch als "Pflanzlich" zusammen
    diet_category = case_when(
      group_level_1 %in% c("vegan", "vegetarisch") ~ "Pflanzlich (Vegan/Vegetarisch)",
      group_level_1 == "omnivor" ~ "Fleischhaltig (Omnivor)",
      TRUE ~ "Andere (Pescetarisch)"
    )
  ) |>
  # Wir beschränken uns auf Montag bis Freitag (typische Mensa-Tage)
  filter(weekday %in% c("Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag")) |>
  filter(diet_category != "Andere (Pescetarisch)")

# Berechne durchschnittliche ausgegebene Portionen pro Gericht pro Wochentag
# und den Gesamtabsatzanteil
plot_weekday_data <- weekday_data |>
  group_by(weekday, diet_category) |>
  summarise(
    total_output = sum(actual_output, na.rm = TRUE),
    n_items = n(),
    avg_output_per_dish = total_output / n_items,
    .groups = "drop"
  )

plot_weekday <- ggplot(
  plot_weekday_data,
  aes(x = weekday, y = avg_output_per_dish, fill = diet_category)
) +
  geom_col(position = "dodge", width = 0.7, color = "white", linewidth = 0.2) +
  scale_fill_manual(
    values = c(
      "Pflanzlich (Vegan/Vegetarisch)" = "#009E73",
      "Fleischhaltig (Omnivor)" = "#D55E00"
    )
  ) +
  labs(
    title = "Beliebtheit nach Wochentag (Veggie-Tag Effekt?)",
    subtitle = "Durchschnittlich verkaufte Portionen pro angebotenem Gericht",
    x = "Wochentag",
    y = "Ø Verkaufte Portionen pro Gericht",
    fill = "Kategorie",
    caption = "Beschränkt auf Mo-Fr"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, margin = margin(b = 5)),
    plot.subtitle = element_text(color = "grey40", size = 12, margin = margin(b = 15)),
    plot.caption = element_text(hjust = 0, color = "grey50", size = 10, margin = margin(t = 10)),
    axis.title.x = element_text(margin = margin(t = 10), face = "bold", color = "grey30"),
    axis.title.y = element_text(margin = margin(r = 10), face = "bold", color = "grey30"),
    axis.text = element_text(color = "grey50"),
    legend.position = "bottom",
    legend.title = element_text(face = "bold"),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

ggsave(
  "communications/visualizations/08_weekday_analysis.svg",
  plot_weekday,
  width = 9,
  height = 6
)
