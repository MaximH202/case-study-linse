# 3. Hülsenfrüchte-Anteil nach Mensa im Zeitverlauf (Boxplot)
# Während Skript 02 den Gesamttrend über alle Mensen zeigt, gehen wir hier
# eine Ebene tiefer: Wie verteilt sich der Hülsenfrüchte-Anteil über die einzelnen
# Mensen, und hat sich diese Verteilung über die Zeit verändert?
# Dafür gruppieren wir die Jahre in Perioden und stellen jede Mensa als einzelnen
# Punkt im Boxplot dar.

# Schritt 1: IDs aller Gerichte mit Hülsenfrüchten ermitteln ---------------
# Wir holen uns aus der Long-Tabelle alle Gericht-IDs, bei denen irgendeine
# Komponente "huelsenfruechte" ist — egal in welchem Anteil.
legume_ids <- components |> 
  filter(group_level_2 == "huelsenfruechte") |> 
  distinct(id) |> 
  mutate(has_legume = TRUE)

# Schritt 2: Hülsenfrüchte-Anteil pro Mensa und Zeitraum berechnen --------
legume_by_cafeteria <- menus_classified |> 
  left_join(legume_ids, by = "id") |> 
  mutate(
    # Gerichte ohne Hülsenfrüchte erhalten FALSE statt NA
    has_legume = tidyr::replace_na(has_legume, FALSE),
    
    # Die Einzeljahre werden in größere Zeiträume zusammengefasst,
    # um die Verteilung stabiler zu machen und Trends leichter lesbar zu halten.
    period = cut(
      lubridate::year(date),
      breaks = c(2013, 2016, 2019, 2022, 2026),
      labels = c("2014–2016", "2017–2019", "2020–2022", "2023–2026"),
      right  = TRUE
    )
  ) |> 
  group_by(cafeteria, period) |> 
  summarise(
    # Der Anteil ergibt sich als Mittelwert des logischen Vektors (TRUE = Hülsenfrucht-Gericht)
    legume_share = mean(has_legume),
    n = n(),
    .groups = "drop"
  ) |> 
  # Mensen ohne einen einzigen Hülsenfrüchte-Eintrag im Zeitraum werden ausgeblendet,
  # damit der Plot nicht durch Nullwerte verzerrt wird.
  filter(legume_share > 0)

# Visualisierung: Boxplot mit einzelnen Mensen als Punkte
# Der Boxplot zeigt die Verteilung über alle Mensen, die Punkte die Einzelwerte.
# So sieht man sowohl den typischen Wert (Median) als auch Ausreißer nach oben.
p_legume_by_cafeteria <- legume_by_cafeteria |> 
  ggplot(aes(x = period, y = legume_share)) +
  geom_boxplot(fill = "#009E73", alpha = 0.5, outlier.shape = NA, color = "grey30") +
  geom_jitter(width = 0.15, size = 2, alpha = 0.7, color = "grey20", seed = 42) +
  scale_y_continuous(labels = scales::label_percent()) +
  labs(
    title = "Verteilung des Hülsenfrüchte-Anteils über alle Mensen",
    subtitle = "Jeder Punkt repräsentiert eine Mensa, gruppiert nach Zeitraum",
    x = "Zeitraum",
    y = "Anteil der Gerichte mit Hülsenfrüchten",
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
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

p_legume_by_cafeteria

ggsave(
  "communications/visualizations/03_legumes_share_by_cafeteria.svg",
  p_legume_by_cafeteria,
  width = 9,
  height = 7
)