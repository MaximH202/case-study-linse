# 2. Daten laden -----------------------------------------------------------

menus <- read_csv("data/menus_classified.csv")

components <- read_csv("data/menu_components.csv")


# 3. Daten vorbereiten -----------------------------------------------------

menus_prepared <- menus |>
  mutate(
    # Aus dem genauen Datum wird das Jahr extrahiert,
    # weil die Forschungsfrage nach Entwicklungen über die Zeit fragt.
    year = year(date),

    # Der Monat wird vorbereitet, falls später feinere Zeitverläufe
    # statt Jahresvergleichen analysiert werden sollen.
    month = floor_date(date, "month"),

    # Die Ernährungsform (aus ernaehrungsform-Spalte der klassifizierten Daten)
    # wird als Faktor mit konsistenter Reihenfolge festgelegt.
    ernaehrungsform = factor(
      ernaehrungsform,
      levels = c("vegan", "vegetarisch", "pescetarisch", "omnivor")
    ),

    # Schönerer Name für die Proteinquellen in den Visualisierungen
    hauptprotein_de = case_when(
      hauptprotein == "rotes_fleisch" ~ "Rotes Fleisch",
      hauptprotein == "gefluegel" ~ "Geflügel",
      hauptprotein == "fisch" ~ "Fisch",
      hauptprotein == "milchprodukte" ~ "Milchprodukte",
      hauptprotein == "ei" ~ "Ei",
      hauptprotein == "huelsenfruechte" ~ "Hülsenfrüchte",
      hauptprotein == "nuesse" ~ "Nüsse",
      hauptprotein == "samen" ~ "Samen",
      hauptprotein == "keine_eindeutige_proteinquelle" ~ "Gemüse/Kohlenhydrate (Keine eindeutige)",
      TRUE ~ "Andere / Unbekannt"
    )
  )


plot_diet_yearly_data <- menus_prepared |>
  filter(!is.na(ernaehrungsform)) |>
  group_by(year, ernaehrungsform) |>
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
  aes(x = year, y = share_items, fill = ernaehrungsform)
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

legume_ids <- llm_classified_long |> 
  filter(klasse == "huelsenfruechte") |> 
  distinct(id) |> 
  mutate(has_legume = TRUE)

legume_trend <- llm_classified_short |> 
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
legume_ids <- llm_classified_long |> 
  filter(klasse == "huelsenfruechte") |> 
  distinct(id) |> 
  mutate(has_legume = TRUE)

legume_by_cafeteria <- llm_classified_short |> 
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
protein_share <- llm_classified_short |>
  count(hauptprotein) |>
  mutate(
    share = n / sum(n)
  )

p_protein_share <- protein_share |>
  ggplot(
    aes(
      x = share,
      y = forcats::fct_reorder(hauptprotein, share)
    )
  ) +
  geom_col() +
  scale_x_continuous(
    labels = scales::label_percent()
  ) +
  labs(
    title = "Verteilung der Hauptproteinquellen",
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


#proteincode heatmap

protein_code_year <- llm_classified_long |>
  left_join(
    llm_classified_short |>
      select(id, date),
    by = "id"
  ) |>
  mutate(
    year = lubridate::year(date),
    proteincode = factor(
      proteincode,
      levels = c("very_low", "low", "medium", "high", "very_high")
    )
  ) |>
  filter(
    !is.na(year),
    !is.na(proteincode)
  ) |>
  count(year, proteincode) |>
  group_by(year) |>
  mutate(
    share = n / sum(n)
  ) |>
  ungroup()

p_protein_code_heatmap <- protein_code_year |>
  ggplot(
    aes(
      x = year,
      y = proteincode,
      fill = share
    )
  ) +
  geom_tile(color = "white", linewidth = 0.4) +
 #scale_fill_viridis_c(
  #option = "C",
  #labels = scales::label_percent()
  scale_fill_gradientn(
  colours = c(
    "#ffffcc",
    "#fed976",
    "#fd8d3c",
    "#e31a1c"
  ),
  labels = scales::label_percent()


  ) +
  labs(
    title = "Entwicklung der Proteinqualität über die Zeit",
    subtitle = "Anteil der klassifizierten Lebensmittelkomponenten nach Protein-Code",
    x = "Jahr",
    y = "Protein-Code",
    fill = "Anteil"
  ) +
  theme_minimal(base_size = 14)

p_protein_code_heatmap

ggsave(
  "communications/visualizations/05_protein_code_heatmap.svg",
  plot = p_protein_code_heatmap,
  width = 9,
  height = 6
)

# gewichtete Proteinqualität pro Gericht

protein_score <- c(
  very_low = 1,
  low = 2,
  medium = 3,
  high = 4,
  very_high = 5
)
dish_protein_score <- llm_classified_long |>
  mutate(
    protein_score = protein_score[proteincode]
  ) |>
  group_by(id) |>
  summarise(
    avg_protein_score = mean(protein_score, na.rm = TRUE),
    .groups = "drop"
  ) |>
  left_join(
    llm_classified_short |>
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