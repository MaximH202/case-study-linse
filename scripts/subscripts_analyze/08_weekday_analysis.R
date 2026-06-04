# 8. Wochentags-Analyse: Gibt es einen Veggie-Tag-Effekt?
# Viele Mensen haben einen festen "Veggie-Tag" (meistens Donnerstag), an dem
# bewusst mehr pflanzliche Gerichte angeboten werden. Hier schauen wir, ob sich
# das auch in den tatsächlichen Verkaufszahlen niederschlägt.
# Dafür vergleichen wir die durchschnittlich verkauften Portionen pro Gericht
# (nicht den Gesamtabsatz) getrennt nach fleischhaltig und pflanzlich.
# Durch die Normalisierung auf "pro angebotenem Gericht" werden Tage mit
# mehr oder weniger Auswahl vergleichbar.

library(dplyr)
library(readr)
library(lubridate)
library(ggplot2)

menus_classified <- read_csv("data/menus_classified.csv", show_col_types = FALSE)

# Wochentag extrahieren und Kategorien zusammenfassen ---------------------
weekday_data <- menus_classified |>
  filter(!is.na(group_level_1), !is.na(actual_output), actual_output > 0) |>
  filter(!is.na(date)) |>
  mutate(
    weekday = wday(date, label = TRUE, abbr = FALSE, week_start = 1),
    # Wir fassen vegan und vegetarisch als "Pflanzlich" zusammen,
    # um die Analyse übersichtlich zu halten. Pescetarisch wird separat behandelt,
    # da es eine Mischkategorie ist.
    diet_category = case_when(
      group_level_1 %in% c("vegan", "vegetarisch") ~ "Pflanzlich (Vegan/Vegetarisch)",
      group_level_1 == "omnivor" ~ "Fleischhaltig (Omnivor)",
      TRUE ~ "Andere (Pescetarisch)"
    )
  ) |>
  # Wir beschränken uns auf Montag bis Freitag (typische Mensa-Öffnungstage)
  filter(weekday %in% c("Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag")) |>
  # Pescetarisch wird ausgeschlossen, damit der Vergleich klar zwischen
  # pflanzlich und fleischhaltig bleibt.
  filter(diet_category != "Andere (Pescetarisch)")

# Aggregation: Durchschnittlicher Absatz pro Gericht und Wochentag --------
plot_weekday_data <- weekday_data |>
  group_by(weekday, diet_category) |>
  summarise(
    total_output = sum(actual_output, na.rm = TRUE),
    n_items = n(),
    # "Pro angebotenem Gericht" normalisiert den Wochentags-Vergleich:
    # Ein Donnerstag mit mehr veganen Optionen würde sonst höhere Gesamtverkäufe zeigen,
    # auch wenn die einzelnen Gerichte nicht beliebter sind.
    avg_output_per_dish = total_output / n_items,
    .groups = "drop"
  )

# Visualisierung: Gruppiertes Balkendiagramm nach Wochentag ---------------
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
