top6_protein <- c(
  "rotes_fleisch",
  "gefluegel",
  "milchprodukte",
  "getreide",
  "huelsenfruechte",
  "fisch"
)

heatmap_data_relative <- menus_classified |>
  filter(!is.na(actual_output) & actual_output > 0) |>
  filter(!is.na(code_main_protein)) |>
  mutate(year = year(date)) |>
  
  # A) Gesamtverkäufe für JEDES Jahr berechnen (für alle Gerichte)
  group_by(year) |>
  mutate(yearly_total = sum(actual_output)) |>
  
  # B) Verkäufe pro Protein und Jahr berechnen
  group_by(year, code_main_protein, yearly_total) |>
  summarise(protein_sold = sum(actual_output), .groups = "drop") |>
  
  # C) Den prozentualen Anteil berechnen
  mutate(share = protein_sold / yearly_total) |>
  
  # D) Nur die Top 6 behalten und für den Plot sortieren
  filter(code_main_protein %in% top6_protein) |>
  mutate(
    code_main_protein = factor(code_main_protein,
      levels = rev(top6_protein),
      labels = rev(c(
        "Rotes Fleisch",
        "Geflügel",
        "Milchprodukte",
        "Getreide",
        "Hülsenfrüchte",
        "Fisch"
      ))
    )
  )

plot_heatmap_relative <- ggplot(heatmap_data_relative, aes(x = factor(year), y = code_main_protein, fill = share)) +
  geom_tile(color = "white", linewidth = 0.5) +
  scale_fill_viridis_c(
    option = "mako",
    direction = -1,
    labels = scales::percent_format(accuracy = 1)
  ) +
  labs(
    title = "Heatmap: Beliebtheit der Top 6 Hauptproteinquellen",
    subtitle = "Prozentualer Anteil an den Gesamtverkäufen des jeweiligen Jahres",
    x = "Jahr",
    y = "Hauptprotein",
    fill = "Anteil",
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
    panel.grid = element_blank(),
    axis.ticks = element_blank(),
    legend.position = "right",
    legend.title = element_text(face = "bold"),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

plot_heatmap_relative

ggsave(
  "communications/visualizations/05_beliebtheit.svg",
  plot = plot_heatmap_relative,
  width = 9,
  height = 6
)