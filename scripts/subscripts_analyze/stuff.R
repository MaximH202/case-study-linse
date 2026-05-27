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

    # Die Reihenfolge wird festgelegt, damit vegane, vegetarische
    # und omnivore Gerichte in Auswertungen konsistent sortiert sind.
    group_level_1 = factor(
      group_level_1,
      levels = c("vegan", "vegetarisch", "omnivor")
    )
  )


# 4. Grafik 1: Entwicklung vegan / vegetarisch / omnivor ------------------

plot_diet_yearly_data <- menus_prepared |>
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
  geom_col(position = "fill") +
  scale_y_continuous(labels = percent) +
  labs(
    title = "Entwicklung der Ernährungsformen über die Zeit",
    x = "Jahr",
    y = "Anteil der angebotenen Speisen",
    fill = "Ernährungsform"
  ) +
  theme_minimal()

ggsave(
  "communications/visualizations/01_diet_yearly.svg",
  plot_diet_yearly,
  width = 9,
  height = 6
)


# 5. Grafik 2: Proteinquellen über die Zeit --------------------------------

plot_protein_yearly_data <- menus_prepared |>
  group_by(year, code_main_protein) |>
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
  aes(x = year, y = share_items, fill = code_main_protein)
) +
  geom_area(position = "fill", alpha = 0.85) +
  scale_y_continuous(labels = percent) +
  labs(
    title = "Entwicklung der Hauptproteinquellen",
    x = "Jahr",
    y = "Anteil der angebotenen Speisen",
    fill = "Proteinquelle"
  ) +
  theme_minimal()

ggsave(
  "communications/visualizations/02_protein_yearly.svg",
  plot_protein_yearly,
  width = 9,
  height = 6
)


# 6. Grafik 3: Hülsenfrüchte-Anteil nach Jahr ------------------------------

legume_yearly_data <- components |>
  # Es werden nur die Komponenten behalten, die als Hülsenfrüchte klassifiziert wurden.
  # So kann gezielt die Linse-Forschungsfrage zum Anteil von Hülsenfrüchten beantwortet werden.
  filter(food_class == "Hülsenfrüchte") |>

  # Über die ID werden die Komponenten wieder mit Datum, Mensa und Ausgabemenge verbunden.
  # Diese Informationen liegen in der Haupttabelle, nicht in der Komponententabelle.
  left_join(menus_prepared, by = c("menu_id" = "id")) |>

  group_by(year) |>
  summarise(
    # Zählt, wie viele unterschiedliche Speisen pro Jahr Hülsenfrüchte enthalten.
    n_legume_items = n_distinct(menu_id),

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

plot_legume_yearly <- ggplot(
  legume_yearly_data,
  aes(x = year, y = share_legume_items)
) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_y_continuous(labels = percent) +
  labs(
    title = "Anteil von Speisen mit Hülsenfrüchten",
    x = "Jahr",
    y = "Anteil"
  ) +
  theme_minimal()

ggsave(
  "communications/visualizations/03_legume_yearly.svg",
  plot_legume_yearly,
  width = 9,
  height = 6
)


# 7. Grafik 4: Vergleich zwischen Mensen -----------------------------------

cafeteria_protein_data <- menus_prepared |>
  group_by(student_service, cafeteria, code_main_protein) |>
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

plot_cafeteria_protein <- cafeteria_protein_data |>
  # Hier wird beispielhaft nur eine Proteinquelle ausgewählt.
  # Damit kann verglichen werden, welche Mensen besonders viele Hülsenfruchtgerichte ausgeben.
  filter(code_main_protein == "legumes") |>
  ggplot(aes(x = reorder(cafeteria, share_output), y = share_output)) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = percent) +
  labs(
    title = "Anteil von Hülsenfrüchten nach Mensa",
    x = "Mensa",
    y = "Anteil an ausgegebenen Portionen"
  ) +
  theme_minimal()

ggsave(
  "communications/visualizations/04_cafeteria_legumes.svg",
  plot_cafeteria_protein,
  width = 9,
  height = 7
)


# 8. Grafik 5: Beliebtheit nach Proteinquelle ------------------------------

protein_popularity_data <- menus_prepared |>
  # Speisen ohne Ausgabemenge werden entfernt,
  # weil sie für eine Beliebtheitsanalyse nicht ausgewertet werden können.
  filter(!is.na(actual_output)) |>

  group_by(code_main_protein) |>
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
  filter(n_items >= 50)

plot_protein_popularity <- ggplot(
  protein_popularity_data,
  aes(x = reorder(code_main_protein, median_output), y = median_output)
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Beliebtheit nach Hauptproteinquelle",
    subtitle = "Gemessen über mediane Ausgabemenge",
    x = "Proteinquelle",
    y = "Median der ausgegebenen Portionen"
  ) +
  theme_minimal()

ggsave(
  "communications/visualizations/05_protein_popularity.svg",
  plot_protein_popularity,
  width = 9,
  height = 6
)