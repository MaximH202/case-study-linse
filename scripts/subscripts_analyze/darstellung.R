# 2. Daten laden -----------------------------------------------------------

menus_classified <- read_csv("data/menus_classified.csv")

components <- read_csv("data/menu_components.csv")


# 3. Daten vorbereiten -----------------------------------------------------

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

legume_ids <- components |> 
  filter(group_level_2 == "huelsenfruechte") |> 
  distinct(id) |> 
  mutate(has_legume = TRUE)

legume_trend <- menus_classified |> 
  mutate(year = lubridate::year(date)) |> 
  left_join(legume_ids, by = "id") |> 
  mutate(
    has_legume = tidyr::replace_na(has_legume, FALSE)
  ) |> 
  group_by(year) |> 
  summarise(
    legume_share = mean(has_legume),
    n = n(),
    .groups = "drop"
  )

p_legume_trend <- legume_trend |> 
  ggplot(aes(x = year, y = legume_share)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 3) +
  geom_smooth(
    se = FALSE,
    method = "lm",
    linewidth = 1.2
  ) +
  scale_y_continuous(
    labels = scales::label_percent()
  ) +
  labs(
    title = "Entwicklung des Anteils von Gerichten mit Hülsenfrüchten",
    subtitle = "Anteil aller Gerichte, die mindestens eine Hülsenfrucht enthalten",
    x = "Jahr",
    y = "Anteil der Gerichte"
  ) +
  theme_minimal(base_size = 14)

p_legume_trend

ggsave(
  "communications/visualizations/02_legumes_share_over_time.svg",
  plot = p_legume_trend,
  width = 9,
  height = 6
)

# unterschiede zwischen mensen
legume_ids <- components |> 
  filter(group_level_2 == "huelsenfruechte") |> 
  distinct(id) |> 
  mutate(has_legume = TRUE)

legume_by_cafeteria <- menus_classified |> 
  left_join(legume_ids, by = "id") |> 
  mutate(
    has_legume = tidyr::replace_na(has_legume, FALSE)
  ) |> 
  group_by(cafeteria) |> 
  summarise(
    legume_share = mean(has_legume),   # logische werte (0;1 werden betrachtet und damit der Prozentwert berechnet)
    n = n(),
    .groups = "drop"
  ) |> 
  #filter(n >= 100) |> 
  arrange(desc(legume_share))

p_legume_by_cafeteria <- legume_by_cafeteria |> 
  ggplot(
    aes(
      x = legume_share,
      y = forcats::fct_reorder(cafeteria, legume_share)
    )
  ) +
  geom_col() +
  scale_x_continuous(
    labels = scales::label_percent()
  ) +
  labs(
    title = "Anteil von Gerichten mit Hülsenfrüchten nach Mensa",
    subtitle = "Nur Mensen mit mindestens 100 klassifizierten Gerichten",
    x = "Anteil der Gerichte mit Hülsenfrüchten",
    y = NULL
  ) +
  theme_minimal(base_size = 14)

ggsave(
  "communications/visualizations/03_legumes_share_by_cafeteria.svg",
  p_legume_by_cafeteria,
  width = 9,
  height = 7
)

# zweiter Absatz Forschungsfragen
protein_share <- menus_classified |>
  count(code_main_protein ) |>
  mutate(
    share = n / sum(n)
  )

p_protein_share <- protein_share |>
  ggplot(
    aes(
      x = share,
      y = forcats::fct_reorder(code_main_protein , share)
    )
  ) +
  geom_col() +
  scale_x_continuous(
    labels = scales::label_percent()
  ) +
  labs(
    title = "Verteilung der Hauptprotein-Quellen",
    subtitle = "Anteil aller klassifizierten Gerichte",
    x = "Anteil der Gerichte",
    y = NULL
  ) +
  theme_minimal(base_size = 14)

ggsave(
  "communications/visualizations/04_main_proteins.svg",
  p_protein_share,
  width = 9,
  height = 6
)

#eventuell Grafik für zeitglichen Vergleich hülsenfrüchte vs top3 über zeit 

# gewichtete Proteinqualität pro Gericht

protein_score <- c(
  very_low = 1,
  low = 2,
  medium = 3,
  high = 4,
  very_high = 5
)
dish_protein_score <- components |>
  mutate(
    protein_score = protein_score[proteincode]
  ) |>
  group_by(id) |>
  summarise(
    avg_protein_score = mean(protein_score, na.rm = TRUE),
    .groups = "drop"
  ) |>
  left_join(
    menus_classified |>
      select(id, date, cafeteria, student_service, product_name),
    by = "id"
  ) |>
  mutate(
    year = lubridate::year(date)
  )

protein_score_year <- dish_protein_score |>
  group_by(year) |>
  summarise(
    avg_protein_score = mean(avg_protein_score, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

p_protein_score_year <- protein_score_year |>
  ggplot(
    aes(
      x = year,
      y = avg_protein_score
    )
  ) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 3) +
  geom_smooth(
    method = "lm",
    se = FALSE,
    linewidth = 1
  ) +
  scale_y_continuous(
    limits = c(1, 5),
    breaks = 1:5,
    labels = c("very_low", "low", "medium", "high", "very_high")
  ) +
  labs(
    title = "Durchschnittliche Proteinqualität der Gerichte über die Zeit",
    subtitle = "Score von 1 = very_low bis 5 = very_high",
    x = "Jahr",
    y = "Durchschnittlicher Protein-Score"
  ) +
  theme_minimal(base_size = 14)

p_protein_score_year

ggsave(
  "communications/visualizations/06_weighted_protein_quality_over_time.svg",
  plot = p_protein_score_year,
  width = 9,
  height = 6
)

# 1. Die Top 6 Hauptproteinquellen ermitteln (über alle Jahre)
top6_protein <- menus_short |>
  filter(!is.na(actual_output) & actual_output > 0) |>
  filter(!is.na(code_main_protein)) |>
  group_by(code_main_protein) |>
  summarise(gesamt_verkaeufe = sum(actual_output), .groups = "drop") |>
  arrange(desc(gesamt_verkaeufe)) |>
  slice_head(n = 6) |>
  pull(code_main_protein)

# 2. Daten für die relative Heatmap vorbereiten
heatmap_data_relative <- menus_short |>
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
  mutate(code_main_protein = factor(code_main_protein, levels = rev(top6_protein)))

# 3. Die Heatmap erstellen
plot_heatmap_relative <- ggplot(heatmap_data_relative, aes(x = factor(year), y = code_main_protein, fill = share)) +
  # Kacheln zeichnen (mit weißem Rand für bessere Trennung)
  geom_tile(color = "white", linewidth = 0.5) +
  
  # Farbpalette wählen und Legende als Prozent formatieren
  scale_fill_distiller(
    palette = "YlOrRd", 
    direction = 1, 
    labels = function(x) paste0(round(x * 100, 0), "%") # Macht aus 0.25 -> "25%"
  ) +
  
  labs(
    title = "Heatmap: Beliebtheit der Top 6 Hauptproteinquellen",
    subtitle = "Prozentualer Anteil an den Gesamtverkäufen des jeweiligen Jahres",
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
ggsave(
  "communications/visualizations/05_beliebtheit.svg",
  plot = plot_heatmap_relative,
  width = 9,
  height = 6
)
