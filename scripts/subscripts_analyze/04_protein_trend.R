# 4. Entwicklung der Hauptproteinquellen im Zeitverlauf (Heatmap)
# Hier schauen wir uns an, wie sich die sechs wichtigsten Proteinquellen
# (Rotes Fleisch, Geflügel, Fisch, Milchprodukte, Hülsenfrüchte, Getreide)
# anteilig am Angebot über die Jahre verändert haben.
# Eine Heatmap eignet sich hier gut: Man sieht auf einen Blick, welche Kategorie
# in welchem Jahr besonders stark oder schwach vertreten war.
#
# Hinweis: Kategorieen wie "ei", "samen", "nuesse", "gemuese" und 
# "keine_eindeutige_proteinquelle" werden ausgeschlossen, weil sie entweder 
# zu selten sind oder keine klare Aussage über Proteingehalt erlauben.

# Aggregation: Anteile pro Jahr und Proteinquelle berechnen ---------------
protein_trend <- menus_classified |>
  mutate(year = lubridate::year(date)) |>
  filter(!code_main_protein %in% c("samen", "nuesse", "keine_eindeutige_proteinquelle", "ei", "gemuese")) |>
  group_by(year, code_main_protein) |>
  summarise(n = n(), .groups = "drop") |>
  group_by(year) |>
  # Der Anteil wird innerhalb jedes Jahres berechnet, damit Jahre mit
  # unterschiedlich vielen Daten trotzdem vergleichbar sind.
  mutate(share = n / sum(n)) |>
  ungroup()

# Visualisierung: Heatmap -------------------------------------------------
p_protein_trend <- protein_trend |>
  filter(code_main_protein %in% c(
    "rotes_fleisch",
    "gefluegel",
    "milchprodukte",
    "getreide",
    "huelsenfruechte",
    "fisch"
  )) |>
  mutate(
    # Reihenfolge der y-Achse festlegen: von "fleischlastig" unten zu "pflanzlich" oben
    code_main_protein = factor(code_main_protein, levels = c(
      "fisch",
      "huelsenfruechte",
      "getreide",
      "milchprodukte",
      "gefluegel",
      "rotes_fleisch"
    ),
      labels = c(
        "Fisch",
        "Hülsenfrüchte",
        "Getreide",
        "Milchprodukte",
        "Geflügel",
        "Rotes Fleisch"
      )
  )) |>
  ggplot(aes(x = factor(year), y = code_main_protein, fill = share)) +
  geom_tile(color = "white", linewidth = 0.5) +
  scale_fill_viridis_c(
    option = "mako",
    direction = -1,
    labels = scales::percent_format(accuracy = 1)
  ) +
  scale_x_discrete(breaks = as.character(seq(2014, 2026))) +
  labs(
    title = "Entwicklung der Hauptprotein-Quellen über die Zeit",
    subtitle = "Anteil aller klassifizierten Gerichte pro Jahr",
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

p_protein_trend

ggsave(
  "communications/visualizations/04_main_proteins.svg",
  p_protein_trend,
  width = 9,
  height = 6
)