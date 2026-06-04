# 2. Entwicklung des Hülsenfrüchte-Anteils über die Zeit
# Hier schauen wir uns speziell an, wie sich Hülsenfrüchte im Angebot entwickelt haben.
# Dabei unterscheiden wir drei Stufen: Gerichte, bei denen Hülsenfrüchte die dominante
# Zutat sind, Gerichte, bei denen sie nur eine Nebenrolle spielen (mittel/gering),
# und Gerichte, bei denen sie das Hauptprotein stellen.
# So können wir beurteilen, ob Hülsenfrüchte wirklich als Fleischalternative ankommen
# oder nur als Beilage mitgeführt werden.

# Schritt 1: Hülsenfrüchte-Rolle pro Gericht klassifizieren ---------------
# Wir schauen in der Long-Tabelle (components) nach, welche Gerichte überhaupt
# Hülsenfrüchte enthalten, und in welchem Anteil (dominant vs. mittel/gering).
legume_levels <- components |> 
  filter(group_level_2 == "huelsenfruechte") |> 
  distinct(id, anteil) |> 
  mutate(
    legume_high  = anteil == "dominant",
    legume_low   = anteil %in% c("mittel", "gering")
  ) |> 
  group_by(id) |> 
  summarise(
    # Falls ein Gericht mehrfach auftaucht (z.B. durch verschiedene Komponenten),
    # reicht es, wenn einer davon dominant bzw. niedrig ist.
    legume_high = any(legume_high, na.rm = TRUE),
    legume_low  = any(legume_low,  na.rm = TRUE),
    .groups = "drop"
  )

# Schritt 2: Mit dem Hauptdatensatz verknüpfen und pro Jahr aggregieren ---
legume_trend <- menus_classified |> 
  mutate(year = lubridate::year(date)) |> 
  left_join(legume_levels, by = "id") |> 
  mutate(
    # Gerichte ohne Hülsenfrüchte bekommen FALSE (statt NA)
    legume_high = tidyr::replace_na(legume_high, FALSE),
    legume_low  = tidyr::replace_na(legume_low,  FALSE),
    # Hülsenfrüchte als Hauptprotein: direkt aus der klassifizierten Short-Tabelle
    legume_main = code_main_protein == "huelsenfruechte" & !is.na(code_main_protein)
  ) |> 
  group_by(year) |> 
  summarise(
    # mean() auf einem logischen Vektor ergibt den Anteil der TRUEs
    high_share = mean(legume_high),
    low_share  = mean(legume_low),
    main_share = mean(legume_main),
    n = n(),
    .groups = "drop"
  ) |> 
  # Ins Long-Format bringen, damit ggplot alle drei Linien gleichzeitig zeichnen kann
  pivot_longer(
    cols = c(high_share, low_share, main_share),
    names_to  = "level",
    values_to = "share"
  ) |> 
  mutate(
    level = factor(level,
      levels = c("high_share", "low_share", "main_share"),
      labels = c(
        "Hoch (dominant)",
        "Niedrig/Mittel (gering/mittel)",
        "Hauptprotein"
      )
    )
  )

# Visualisierung: Liniendiagramm mit Trend-Geraden ------------------------
p_legume_trend <- legume_trend |> 
  ggplot(aes(x = year, y = share, color = level, group = level)) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  # Die gestrichelten Trendlinien helfen dabei, den langfristigen Trend
  # besser vom jährlichen Rauschen zu trennen.
  geom_smooth(
    se = FALSE,
    method = "lm",
    linewidth = 1.2,
    linetype = "dashed",
    alpha = 0.5
  ) +
  scale_y_continuous(labels = scales::label_percent()) +
  scale_color_manual(
    values = c(
      "Hoch (dominant)"                = "#009E73",
      "Niedrig/Mittel (gering/mittel)" = "#E69F00",
      "Hauptprotein"                   = "#56B4E9"
    )
  ) +
  labs(
    title    = "Entwicklung des Anteils von Gerichten mit Hülsenfrüchten",
    subtitle = "Nach Anteilsstufe: dominant vs. mittel/gering vs. Hauptprotein",
    x        = "Jahr",
    y        = "Anteil der Gerichte",
    color    = "Anteilsstufe",
    caption  = "Anzahl Gerichte = 521915"
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
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

p_legume_trend

ggsave(
  "communications/visualizations/02_legumes_share_over_time.svg",
  plot   = p_legume_trend,
  width  = 9,
  height = 6
)