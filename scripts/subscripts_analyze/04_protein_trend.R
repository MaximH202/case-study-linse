protein_trend <- menus_classified |>
  mutate(year = lubridate::year(date)) |>
  filter(!code_main_protein %in% c("samen", "nuesse", "keine_eindeutige_proteinquelle", "ei", "gemuese")) |>
  group_by(year, code_main_protein) |>
  summarise(n = n(), .groups = "drop") |>
  group_by(year) |>
  mutate(share = n / sum(n)) |>
  ungroup()

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
    code_main_protein = factor(code_main_protein, levels = c(
      "fisch",
      "huelsenfruechte",
      "getreide",
      "milchprodukte",
      "gefluegel",
      "rotes_fleisch"
    ))
  ) |>
  ggplot(aes(x = factor(year), y = code_main_protein, fill = share)) +
  geom_tile(color = "white", linewidth = 0.5) +
  scale_fill_distiller(
    palette = "YlOrRd",
    direction = 1,
    labels = function(x) paste0(round(x * 100, 0), "%")
  ) +
  scale_x_discrete(breaks = as.character(seq(2014, 2026))) +
  labs(
    title = "Entwicklung der Hauptprotein-Quellen über die Zeit",
    subtitle = "Anteil aller klassifizierten Gerichte pro Jahr",
    x = "Jahr",
    y = "Hauptprotein",
    fill = "Anteil"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    panel.grid = element_blank(),
    axis.ticks = element_blank(),
    legend.position = "right",
    legend.title = element_text(face = "bold")
  )

p_protein_trend

ggsave(
  "communications/visualizations/04_main_proteins.svg",
  p_protein_trend,
  width = 9,
  height = 6
)