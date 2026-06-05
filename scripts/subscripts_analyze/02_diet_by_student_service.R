# 2. Anteil der Ernährungsformen nach Studierendenwerk
# Während Skript 01 die Entwicklung über die Zeit zeigt, vergleichen wir hier
# die Studierendenwerke miteinander: Wo ist der pflanzliche Anteil am höchsten?
# Die Sortierung nach dem kombinierten Vegan- und Vegetarisch-Anteil macht
# Unterschiede zwischen den Standorten sofort sichtbar.

menus_classified <- read_csv("data/menus_classified.csv", show_col_types = FALSE)

menus_prepared <- menus_classified |>
  filter(!is.na(group_level_1)) |>
  mutate(
    # Konsistente Reihenfolge der Ernährungsformen für alle Plots
    group_level_1 = factor(
      group_level_1,
      levels = c("vegan", "vegetarisch", "pescetarisch", "omnivor")
    )
  )

# Angebots-Anteile pro Studierendenwerk und Ernährungsform berechnen
plot_diet_sw_data <- menus_prepared |>
  group_by(student_service, group_level_1) |>
  summarise(n_items = n(), .groups = "drop") |>
  group_by(student_service) |>
  mutate(
    total_items = sum(n_items),
    # Relativer Anteil statt absoluter Anzahl
    share = n_items / total_items
  ) |>
  ungroup()

# Sortierung der Studierendenwerke nach pflanzlichem Anteil
# Wir sortieren aufsteigend nach dem kombinierten Anteil von vegan + vegetarisch
order_sw <- plot_diet_sw_data |>
  filter(group_level_1 %in% c("vegan", "vegetarisch")) |>
  group_by(student_service) |>
  summarise(plant_share = sum(share)) |>
  arrange(plant_share) |>
  pull(student_service)

plot_diet_sw_data <- plot_diet_sw_data |>
  mutate(student_service = factor(student_service, levels = order_sw))

# Visualisierung: Horizontales Balkendiagramm
plot_diet_sw <- ggplot(
  plot_diet_sw_data,
  aes(x = share, y = student_service, fill = group_level_1)
) +
  geom_col(position = "fill", width = 0.8, color = "white", linewidth = 0.2) +
  scale_x_continuous(labels = scales::percent) +
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
    title = "Zusammensetzung des Angebots nach Studierendenwerk",
    subtitle = "Relative Anteile der angebotenen Gerichte (über alle Jahre)",
    x = "Anteil am Angebot",
    y = "Studierendenwerk",
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
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

ggsave(
  "communications/visualizations/02_diet_by_student_service.svg",
  plot_diet_sw,
  width = 9,
  height = 6
)
