heatmap_data_relative <- menus_classified |>
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