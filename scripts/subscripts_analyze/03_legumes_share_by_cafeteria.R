legume_ids <- components |> 
  filter(group_level_2 == "huelsenfruechte") |> 
  distinct(id) |> 
  mutate(has_legume = TRUE)

legume_by_cafeteria <- menus_classified |> 
  left_join(legume_ids, by = "id") |> 
  mutate(
    has_legume = tidyr::replace_na(has_legume, FALSE),
    period = cut(
      lubridate::year(date),
      breaks = c(2013, 2016, 2019, 2022, 2026),
      labels = c("2014–2016", "2017–2019", "2020–2022", "2023–2026"),
      right  = TRUE
    )
  ) |> 
  group_by(cafeteria, period) |> 
  summarise(
    legume_share = mean(has_legume),
    n = n(),
    .groups = "drop"
  ) |> 
  filter(legume_share > 0)

p_legume_by_cafeteria <- legume_by_cafeteria |> 
  ggplot(aes(x = period, y = legume_share)) +
  geom_boxplot(fill = "steelblue", alpha = 0.4, outlier.shape = NA) +
  geom_jitter(width = 0.15, size = 2, alpha = 0.7, color = "steelblue4", seed = 42) +
  scale_y_continuous(labels = scales::label_percent()) +
  labs(
    title = "Verteilung des Hülsenfrüchte-Anteils über alle Mensen",
    subtitle = "Jeder Punkt repräsentiert eine Mensa, gruppiert nach Zeitraum",
    x = NULL,
    y = "Anteil der Gerichte mit Hülsenfrüchten"
  ) +
  theme_minimal(base_size = 14)

p_legume_by_cafeteria

ggsave(
  "communications/visualizations/03_legumes_share_by_cafeteria.svg",
  p_legume_by_cafeteria,
  width = 9,
  height = 7
)