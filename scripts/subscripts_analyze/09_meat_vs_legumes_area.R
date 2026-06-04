# 9. Direkter Vergleich: Fleisch vs. Hülsenfrüchte (Area Chart) ------------

library(dplyr)
library(readr)
library(ggplot2)

menus_classified <- read_csv("data/menus_classified.csv", show_col_types = FALSE)

area_data <- menus_classified |>
  mutate(year = lubridate::year(date)) |>
  filter(!is.na(code_main_protein)) |>
  mutate(
    protein_group = case_when(
      code_main_protein %in% c("rotes_fleisch", "gefluegel") ~ "Fleisch (Rotes Fleisch & Geflügel)",
      code_main_protein == "huelsenfruechte" ~ "Hülsenfrüchte",
      TRUE ~ "Andere Proteinquellen"
    )
  ) |>
  group_by(year, protein_group) |>
  summarise(n = n(), .groups = "drop") |>
  group_by(year) |>
  mutate(share = n / sum(n)) |>
  ungroup() |>
  mutate(
    protein_group = factor(
      protein_group,
      levels = c("Fleisch (Rotes Fleisch & Geflügel)", "Andere Proteinquellen", "Hülsenfrüchte")
    )
  )

plot_area <- ggplot(area_data, aes(x = year, y = share, fill = protein_group)) +
  geom_area(alpha = 0.85, color = "white", linewidth = 0.5) +
  scale_y_continuous(labels = scales::percent) +
  scale_x_continuous(breaks = min(area_data$year):max(area_data$year)) +
  scale_fill_manual(
    values = c(
      "Fleisch (Rotes Fleisch & Geflügel)" = "#D55E00",
      "Andere Proteinquellen" = "#E69F00",  # Or some neutral color like #999999 if we wanted to deemphasize, but E69F00 works
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
