
# Hülsenfrüchte nach Anteilsstufe klassifizieren
legume_levels <- components |> 
  filter(group_level_2 == "huelsenfruechte") |> 
  distinct(id, anteil) |> 
  mutate(
    legume_high  = anteil == "dominant",   # ggf. "dominierend" je nach Schreibweise
    legume_low   = anteil %in% c("mittel", "gering")
  ) |> 
  # Pro Gericht: TRUE wenn mind. eine Zeile die Bedingung erfüllt
  group_by(id) |> 
  summarise(
    legume_high = any(legume_high, na.rm = TRUE),
    legume_low  = any(legume_low,  na.rm = TRUE),
    .groups = "drop"
  )

legume_trend <- menus_classified |> 
  mutate(year = lubridate::year(date)) |> 
  left_join(legume_levels, by = "id") |> 
  mutate(
    legume_high = tidyr::replace_na(legume_high, FALSE),
    legume_low  = tidyr::replace_na(legume_low,  FALSE)
  ) |> 
  group_by(year) |> 
  summarise(
    high_share = mean(legume_high),
    low_share  = mean(legume_low),
    n = n(),
    .groups = "drop"
  ) |> 
  # Ins Long-Format für ggplot
  pivot_longer(
    cols = c(high_share, low_share),
    names_to  = "level",
    values_to = "share"
  ) |> 
  mutate(
    level = factor(level,
      levels = c("high_share", "low_share"),
      labels = c("Hoch (dominant)", "Niedrig/Mittel (gering/mittel)")
    )
  )

p_legume_trend <- legume_trend |> 
  ggplot(aes(x = year, y = share, color = level, group = level)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 3) +
  geom_smooth(
    se = FALSE,
    method = "lm",
    linewidth = 1.2,
    linetype = "dashed"
  ) +
  scale_y_continuous(labels = scales::label_percent()) +
  scale_color_manual(
    values = c(
      "Hoch (dominant)"              = "#2166ac",
      "Niedrig/Mittel (gering/mittel)" = "#d73027"
    )
  ) +
  labs(
    title    = "Entwicklung des Anteils von Gerichten mit Hülsenfrüchten",
    subtitle = "Nach Anteilsstufe: dominant vs. mittel/gering",
    x        = "Jahr",
    y        = "Anteil der Gerichte",
    color    = "Anteilsstufe"
  ) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom")

p_legume_trend

ggsave(
  "communications/visualizations/02_legumes_share_over_time.svg",
  plot   = p_legume_trend,
  width  = 9,
  height = 6
)