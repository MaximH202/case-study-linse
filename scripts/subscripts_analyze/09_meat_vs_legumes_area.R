# 9. Direkter Vergleich: Fleisch vs. Hülsenfrüchte (Area Chart)
# Dieser Plot stellt die zentrale Forschungsfrage direkt dar:
# Hat der Anteil an Hülsenfrüchten im Angebot über die Zeit zugenommen,
# während Fleisch zurückgegangen ist? Das Area Chart eignet sich hier gut,
# weil es zeigt, wie sich die Anteile der Gruppen gegenseitig verdrängen.
#
# Wir fassen rotes Fleisch und Geflügel als "Fleisch" zusammen und setzen
# sie Hülsenfrüchten als der relevantesten pflanzlichen Proteinquelle gegenüber.
# Alle anderen Proteinquellen (Fisch, Milch, Getreide usw.) landen in "Andere".

library(dplyr)
library(readr)
library(ggplot2)

menus_classified <- read_csv("data/menus_classified.csv", show_col_types = FALSE)

# Aggregation: Jahres-Anteile der drei Proteingruppen ---------------------
area_data <- menus_classified |>
  mutate(year = lubridate::year(date)) |>
  filter(!is.na(code_main_protein)) |>
  mutate(
    # Wir gruppieren in drei Kategorien, die die Kernaussage tragen:
    # Fleisch, Hülsenfrüchte und alles andere als Kontext.
    protein_group = case_when(
      code_main_protein %in% c("rotes_fleisch", "gefluegel") ~ "Fleisch (Rotes Fleisch & Geflügel)",
      code_main_protein == "huelsenfruechte" ~ "Hülsenfrüchte",
      TRUE ~ "Andere Proteinquellen"
    )
  ) |>
  group_by(year, protein_group) |>
  summarise(n = n(), .groups = "drop") |>
  group_by(year) |>
  # Jahres-Normalisierung, damit auch Jahre mit unterschiedlicher Datendichte vergleichbar sind
  mutate(share = n / sum(n)) |>
  ungroup() |>
  mutate(
    # Die Reihenfolge der Flächen im Plot: Fleisch unten, Andere in der Mitte, Hülsenfrüchte oben.
    # So ist die Hülsenfrüchte-Fläche immer oben und ihre Wachstumstendenz direkt sichtbar.
    protein_group = factor(
      protein_group,
      levels = c("Fleisch (Rotes Fleisch & Geflügel)", "Andere Proteinquellen", "Hülsenfrüchte")
    )
  )

# Visualisierung: Gestapeltes Area Chart ----------------------------------
plot_area <- ggplot(area_data, aes(x = year, y = share, fill = protein_group)) +
  geom_area(alpha = 0.85, color = "white", linewidth = 0.5) +
  scale_y_continuous(labels = scales::percent) +
  scale_x_continuous(breaks = min(area_data$year):max(area_data$year)) +
  scale_fill_manual(
    values = c(
      "Fleisch (Rotes Fleisch & Geflügel)" = "#D55E00",
      "Andere Proteinquellen" = "#E69F00",
      "Hülsenfrüchte" = "#009E73"
    )
  ) +
  labs(
    title = "Substitutionseffekte: Fleisch vs. Hülsenfrüchte",
    subtitle = "Entwicklung der Hauptproteinquellen im Gesamtangebot",
    x = "Jahr",
    y = "Anteil am Angebot",
    fill = "Proteingruppe",
    caption = "Anzahl Gerichte = 521915"
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
  "communications/visualizations/09_meat_vs_legumes_area.svg",
  plot_area,
  width = 9,
  height = 6
)
