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


# 4. Grafik 1: Entwicklung der Ernährungsformen über die Zeit --------------

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


# 5. Grafik 2: Proteinquellen über die Zeit --------------------------------

plot_protein_yearly_data <- menus_prepared |>
  filter(!is.na(hauptprotein_de)) |>
  group_by(year, hauptprotein_de) |>
  summarise(
    # Zählt, wie oft jede Hauptproteinquelle pro Jahr angeboten wurde.
    # Damit wird sichtbar, ob z. B. Fleisch abnimmt oder Hülsenfrüchte zunehmen.
    n_items = n(),

    # Summiert die ausgegebenen Portionen pro Proteinquelle und Jahr.
    # Das ergänzt die Angebotsanalyse um eine Nachfrageperspektive.
    total_output = sum(actual_output, na.rm = TRUE),
    .groups = "drop"
  ) |>
  group_by(year) |>
  mutate(
    # Anteil der jeweiligen Proteinquelle am gesamten Angebot des Jahres.
    share_items = n_items / sum(n_items),

    # Anteil der jeweiligen Proteinquelle an allen ausgegebenen Portionen des Jahres.
    share_output = total_output / sum(total_output)
  ) |>
  ungroup()

plot_protein_yearly <- ggplot(
  plot_protein_yearly_data,
  aes(x = year, y = share_items, fill = reorder(hauptprotein_de, share_items))
) +
  geom_area(position = "fill", alpha = 0.85, color = "white", linewidth = 0.1) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(
    values = c(
      "Hülsenfrüchte" = "#2e7d32",
      "Samen" = "#a1887f",
      "Nüsse" = "#8d6e63",
      "Gemüse/Kohlenhydrate (Keine eindeutige)" = "#78909c",
      "Ei" = "#fff176",
      "Milchprodukte" = "#ffca28",
      "Fisch" = "#1565c0",
      "Geflügel" = "#ff7043",
      "Rotes Fleisch" = "#c62828",
      "Andere / Unbekannt" = "#bdbdbd"
    )
  ) +
  labs(
    title = "Entwicklung der Hauptproteinquellen",
    subtitle = "Anteil der angebotenen Proteinquellen auf den Speisekarten im Zeitverlauf",
    x = "Jahr",
    y = "Anteil der angebotenen Speisen",
    fill = "Proteinquelle"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "dimgrey", size = 11),
    legend.position = "right"
  )

ggsave(
  "communications/visualizations/02_protein_yearly.svg",
  plot_protein_yearly,
  width = 10,
  height = 6
)


# 6. Grafik 3: Hülsenfrüchte-Anteil nach Jahr ------------------------------

legume_yearly_data <- components |>
  # Es werden nur die Komponenten behalten, die als Hülsenfrüchte klassifiziert wurden.
  # So kann gezielt die Linse-Forschungsfrage zum Anteil von Hülsenfrüchten beantwortet werden.
  filter(klasse == "huelsenfruechte") |>
  # Wir mappen die textuellen Anteile ("dominant", "mittel", "gering")
  # auf numerische Gewichtungsfaktoren.
  mutate(
    share_numeric = case_when(
      anteil == "dominant" ~ 0.6,
      anteil == "mittel" ~ 0.3,
      anteil == "gering" ~ 0.1,
      TRUE ~ 0
    )
  ) |>
  # Über die ID werden die Komponenten wieder mit Datum, Mensa und Ausgabemenge verbunden.
  # Diese Informationen liegen in der Haupttabelle, nicht in der Komponententabelle.
  left_join(menus_prepared, by = "id") |>
  group_by(year) |>
  summarise(
    # Zählt, wie viele unterschiedliche Speisen pro Jahr Hülsenfrüchte enthalten.
    n_legume_items = n_distinct(id),

    # Schätzt die ausgegebene Hülsenfruchtmenge gewichtet mit dem Anteil am Gericht.
    # Beispiel: 100 Portionen Gericht mit 0.5 Hülsenfruchtanteil zählen als 50.
    total_legume_output = sum(actual_output * share_numeric, na.rm = TRUE),
    .groups = "drop"
  ) |>
  # Fügt die Gesamtzahl aller Speisen und Portionen pro Jahr hinzu.
  # Diese Gesamtwerte werden gebraucht, um echte Jahresanteile zu berechnen.
  left_join(
    menus_prepared |>
      group_by(year) |>
      summarise(
        n_all_items = n(),
        total_output = sum(actual_output, na.rm = TRUE),
        .groups = "drop"
      ),
    by = "year"
  ) |>
  mutate(
    # Anteil der Speisen, in denen Hülsenfrüchte vorkommen.
    share_legume_items = n_legume_items / n_all_items,

    # Anteil der geschätzten Hülsenfrucht-Portionen an allen ausgegebenen Portionen.
    share_legume_output = total_legume_output / total_output
  )

# Wir stellen Angebot (Menüs) und Nachfrage (Portionen) in einer Grafik dar
legume_yearly_long <- legume_yearly_data |>
  pivot_longer(
    cols = c(share_legume_items, share_legume_output),
    names_to = "metric",
    values_to = "value"
  ) |>
  mutate(
    metric = recode(
      metric,
      share_legume_items = "Anteil am Speisenangebot (Menus)",
      share_legume_output = "Anteil an ausgegebenen Portionen (Nachfrage)"
    )
  )

plot_legume_yearly <- ggplot(
  legume_yearly_long,
  aes(x = year, y = value, color = metric, linetype = metric)
) +
  geom_line(linewidth = 1.3) +
  geom_point(size = 3) +
  scale_y_continuous(labels = scales::percent) +
  scale_color_manual(values = c(
    "Anteil am Speisenangebot (Menus)" = "#1976d2",
    "Anteil an ausgegebenen Portionen (Nachfrage)" = "#2e7d32"
  )) +
  labs(
    title = "Bedeutung von Hülsenfrüchten im Zeitverlauf",
    subtitle = "Gegenüberstellung von Angebot und tatsächlicher Nachfrage (gewichtete Portionen)",
    x = "Jahr",
    y = "Anteil",
    color = "Metrik",
    linetype = "Metrik"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "dimgrey", size = 11),
    legend.position = "bottom"
  )

ggsave(
  "communications/visualizations/03_legume_yearly.svg",
  plot_legume_yearly,
  width = 9,
  height = 6
)


# 7. Grafik 4: Vergleich zwischen Mensen -----------------------------------

cafeteria_protein_data <- menus_prepared |>
  filter(!is.na(hauptprotein)) |>
  group_by(student_service, cafeteria, hauptprotein) |>
  summarise(
    # Summiert die ausgegebenen Portionen je Mensa und Proteinquelle.
    # Dadurch wird nicht nur gezählt, was angeboten wurde, sondern was tatsächlich ausgegeben wurde.
    total_output = sum(actual_output, na.rm = TRUE),

    # Zählt zusätzlich die Anzahl der angebotenen Speisen je Proteinquelle.
    n_items = n(),
    .groups = "drop"
  ) |>
  group_by(student_service, cafeteria) |>
  mutate(
    # Berechnet innerhalb jeder Mensa den Anteil jeder Proteinquelle
    # an allen dort ausgegebenen Portionen.
    share_output = total_output / sum(total_output)
  ) |>
  ungroup()

plot_cafeteria_protein_data <- cafeteria_protein_data |>
  # Hier wird beispielhaft nur eine Proteinquelle ausgewählt (Hülsenfrüchte).
  # Damit kann verglichen werden, welche Mensen besonders viele Hülsenfruchtgerichte ausgeben.
  filter(hauptprotein == "huelsenfruechte") |>
  mutate(cafeteria_label = reorder(cafeteria, share_output))

plot_cafeteria_protein <- ggplot(
  plot_cafeteria_protein_data,
  aes(x = share_output, y = cafeteria_label, fill = student_service)
) +
  geom_col(width = 0.75) +
  geom_text(
    aes(label = scales::percent(share_output, accuracy = 0.1)),
    hjust = -0.1,
    size = 3.5,
    fontface = "bold"
  ) +
  scale_x_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Anteil von Hülsenfrüchten an ausgegebenen Portionen",
    subtitle = "Vergleich der Mensen (Sortiert nach Beliebtheit von Hülsenfrüchten)",
    x = "Anteil an allen ausgegebenen Portionen der Mensa",
    y = "Mensa",
    fill = "Studentenwerk"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "dimgrey", size = 11),
    legend.position = "bottom"
  )

ggsave(
  "communications/visualizations/04_cafeteria_legumes.svg",
  plot_cafeteria_protein,
  width = 10,
  height = 8
)


# 8. Grafik 5: Beliebtheit nach Proteinquelle ------------------------------

protein_popularity_data <- menus_prepared |>
  # Speisen ohne Ausgabemenge werden entfernt,
  # weil sie für eine Beliebtheitsanalyse nicht ausgewertet werden können.
  filter(!is.na(actual_output)) |>
  filter(!is.na(hauptprotein_de)) |>
  group_by(hauptprotein_de) |>
  summarise(
    # Der Median ist robuster als der Mittelwert,
    # falls einzelne Gerichte extrem hohe oder niedrige Ausgabemengen haben.
    median_output = median(actual_output, na.rm = TRUE),

    # Der Mittelwert wird zusätzlich berechnet,
    # falls ihr Median und Durchschnitt vergleichen wollt.
    mean_output = mean(actual_output, na.rm = TRUE),

    # Zählt, wie viele Speisen je Proteinquelle in die Berechnung eingehen.
    n_items = n(),
    .groups = "drop"
  ) |>
  # Sehr seltene Proteinquellen werden ausgeschlossen,
  # weil deren Durchschnitt oder Median sonst kaum aussagekräftig wäre.
  # Wir senken die Schwelle auf >= 5 ab, damit es auch mit kleineren Datensätzen stabil läuft.
  filter(n_items >= 5)

plot_protein_popularity <- ggplot(
  protein_popularity_data,
  aes(x = reorder(hauptprotein_de, median_output), y = median_output, fill = hauptprotein_de)
) +
  geom_col(width = 0.7, show.legend = FALSE) +
  geom_text(
    aes(label = round(median_output)),
    hjust = -0.1,
    size = 3.5,
    fontface = "bold"
  ) +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  scale_fill_manual(
    values = c(
      "Hülsenfrüchte" = "#2e7d32",
      "Samen" = "#a1887f",
      "Nüsse" = "#8d6e63",
      "Gemüse/Kohlenhydrate (Keine eindeutige)" = "#78909c",
      "Ei" = "#fff176",
      "Milchprodukte" = "#ffca28",
      "Fisch" = "#1565c0",
      "Geflügel" = "#ff7043",
      "Rotes Fleisch" = "#c62828",
      "Andere / Unbekannt" = "#bdbdbd"
    )
  ) +
  labs(
    title = "Beliebtheit nach Hauptproteinquelle",
    subtitle = "Gemessen über mediane Ausgabemenge pro angebotenem Gericht",
    x = "Hauptproteinquelle",
    y = "Median der ausgegebenen Portionen"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "dimgrey", size = 11)
  )

ggsave(
  "communications/visualizations/05_protein_popularity.svg",
  plot_protein_popularity,
  width = 9,
  height = 6
)
