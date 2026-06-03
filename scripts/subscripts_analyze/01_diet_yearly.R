# 2. Daten laden -----------------------------------------------------------

menus_classified <- read_csv("data/menus_classified.csv")

components <- read_csv("data/menu_components.csv")


menus_prepared <- menus_classified |>
  mutate(
    # Aus dem genauen Datum wird das Jahr extrahiert,
    # weil die Forschungsfrage nach Entwicklungen über die Zeit fragt.
    year = year(date),

    # Der Monat wird vorbereitet, falls später feinere Zeitverläufe
    # statt Jahresvergleichen analysiert werden sollen.
    month = floor_date(date, "month"),

    # Die Ernährungsform (aus group_level_1-Spalte der klassifizierten Daten)
    # wird als Faktor mit konsistenter Reihenfolge festgelegt.
    group_level_1 = factor(
      group_level_1,
      levels = c("vegan", "vegetarisch", "pescetarisch", "omnivor")
    ),

    # Schönerer Name für die Proteinquellen in den Visualisierungen
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


plot_diet_yearly_data <- menus_prepared |>
  filter(!is.na(group_level_1)) |>
  group_by(year, group_level_1) |>
  summarise(
    # Zählt, wie viele Speisen pro Jahr und Ernährungsform angeboten wurden.
    # Damit lässt sich beantworten, ob z. B. vegane Gerichte häufiger werden.
    n_items = n(),

    # Summiert die tatsächlichen Ausgabemengen.
    # Dadurch kann man zusätzlich sehen, ob diese Gerichte auch nachgefragt wurden.
    total_output = sum(actual_output, na.rm = TRUE),
    .groups = "drop"
  ) |>
  group_by(year) |>
  mutate(
    # Berechnet den Anteil an allen angebotenen Speisen des jeweiligen Jahres.
    # Dadurch werden Jahre vergleichbar, auch wenn unterschiedlich viele Daten vorliegen.
    share_items = n_items / sum(n_items),

    # Berechnet den Anteil an allen ausgegebenen Portionen des jeweiligen Jahres.
    # Das ist wichtig für die Beliebtheit bzw. tatsächliche Nutzung.
    share_output = total_output / sum(total_output)
  ) |>
  ungroup()

plot_diet_yearly <- ggplot(
  plot_diet_yearly_data,
  aes(x = year, y = share_items, fill = group_level_1)
) +
  geom_col(position = "fill", width = 0.75, color = "white", linewidth = 0.2) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(
    values = c(
      "vegan" = "#2e7d32", # Frisches Grün
      "vegetarisch" = "#ffca28", # Warmes Gelb
      "pescetarisch" = "#00acc1", # Softes Cyan
      "omnivor" = "#ef5350" # Sanftes Rot
    )
  ) +
  labs(
    title = "Entwicklung der Ernährungsformen über die Zeit",
    subtitle = "Anteil der angebotenen Gerichte auf den Speisekarten",
    x = "Jahr",
    y = "Anteil der angebotenen Speisen",
    fill = "Ernährungsform"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "dimgrey", size = 11),
    legend.position = "bottom"
  )

ggsave(
  "communications/visualizations/01_diet_yearly.svg",
  plot_diet_yearly,
  width = 9,
  height = 6
)