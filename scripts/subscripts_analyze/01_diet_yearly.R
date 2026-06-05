# 1. Entwicklung der Ernährungsformen über die Zeit
# Hier schauen wir uns an, wie sich das Angebot nach Ernährungsformen (vegan, vegetarisch,
# pescetarisch, omnivor) über die Jahre verändert hat.
# Dafür laden wir zunächst die klassifizierten Daten und bereiten sie für die Visualisierung vor.

menus_classified <- read_csv("data/menus_classified.csv")

components <- read_csv("data/menu_components.csv")

len_gerichte <- menus_classified |>
  summarise(n())

menus_prepared <- menus_classified |>
  mutate(
    year = year(date),
    month = floor_date(date, "month"),

    # Die Ernährungsform (aus group_level_1-Spalte der klassifizierten Daten)
    # wird als Faktor mit konsistenter Reihenfolge festgelegt.
    # Die Reihenfolge bestimmt später auch die Stapelreihenfolge im Plot.
    group_level_1 = factor(
      group_level_1,
      levels = c("vegan", "vegetarisch", "pescetarisch", "omnivor")
    ),

    # Lesbarere Bezeichnungen für die Proteinquellen in den Visualisierungen.
    code_main_protein_de = case_when(
      code_main_protein == "rotes_fleisch" ~ "Rotes Fleisch",
      code_main_protein == "gefluegel" ~ "Geflügel",
      code_main_protein == "fisch" ~ "Fisch",
      code_main_protein == "milchprodukte" ~ "Milchprodukte",
      code_main_protein == "ei" ~ "Ei",
      code_main_protein == "huelsenfruechte" ~ "Hülsenfrüchte",
      code_main_protein == "nuesse" ~ "Nüsse",
      code_main_protein == "samen" ~ "Samen",
      code_main_protein == "keine_eindeutige_proteinquelle" ~ "Gemüse/Kohlenhydrate (Keine eindeutige)",
      TRUE ~ "Andere / Unbekannt"
    )
  )


# Aggregation: Angebots-Anteile pro Jahr und Ernährungsform ---------------

plot_diet_yearly_data <- menus_prepared |>
  filter(!is.na(group_level_1)) |>
  group_by(year, group_level_1) |>
  summarise(
    # Zählt, wie viele Speisen pro Jahr und Ernährungsform angeboten wurden.
    # Damit lässt sich beantworten, ob z. B. vegane Gerichte häufiger werden.
    n_items = n(),
    .groups = "drop"
  ) |>
  group_by(year) |>
  mutate(
    share_items = n_items / sum(n_items),
  ) |>
  ungroup()

# Visualisierung: gestapeltes Balkendiagramm

plot_diet_yearly <- ggplot(
  plot_diet_yearly_data,
  aes(x = year, y = share_items, fill = group_level_1)
) +
  geom_col(position = "fill", width = 0.75, color = "white", linewidth = 0.2) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(
    values = c(
      "vegan" = "#009E73",
      "vegetarisch" = "#E69F00",
      "pescetarisch" = "#56B4E9",
      "omnivor" = "#D55E00"
    ),
    labels = c(
      "vegan" = "Vegan",
      "vegetarisch" = "Vegetarisch",
      "pescetarisch" = "Pescetarisch",
      "omnivor" = "Omnivor"
    )
  ) +
  labs(
    title = "Entwicklung der Ernährungsformen über die Zeit",
    subtitle = "Anteil der angebotenen Gerichte auf den Speisekarten",
    x = "Jahr",
    y = "Anteil der angebotenen Speisen",
    fill = "Ernährungsform",
    caption = paste("Auf Basis von:", len_gerichte, "Gerichten | 2014-2026")
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
  "communications/visualizations/01_diet_yearly.svg",
  plot_diet_yearly,
  width = 9,
  height = 6
)