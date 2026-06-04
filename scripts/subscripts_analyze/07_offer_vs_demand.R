# 7. Angebot vs. Nachfrage nach pflanzlichen Gerichten (Dumbell Chart)
# Eine entscheidende Frage ist: Wird das pflanzliche Angebot auch angenommen?
# Oder bieten Mensen viele vegane/vegetarische Gerichte an, die aber kaum gekauft werden?
# Ein Dumbbell Chart eignet sich hier perfekt: Jedes Studierendenwerk hat einen Punkt
# für den Angebots-Anteil und einen für den Nachfrage-Anteil, verbunden durch eine Linie.
# Der Abstand und die Richtung der Linie zeigt, ob Angebot und Nachfrage auseinanderklaffen.

library(dplyr)
library(readr)
library(ggplot2)
library(tidyr)

menus_classified <- read_csv("data/menus_classified.csv", show_col_types = FALSE)

# Wir fokussieren uns auf pflanzliche Gerichte (vegan + vegetarisch)
offer_demand_data <- menus_classified |>
  filter(!is.na(group_level_1), !is.na(actual_output), actual_output > 0) |>
  mutate(is_plant_based = group_level_1 %in% c("vegan", "vegetarisch")) |>
  group_by(student_service) |>
  summarise(
    # Angebots-Anteil: wie viele der angebotenen Gerichte sind pflanzlich?
    n_total = n(),
    n_plant = sum(is_plant_based),
    share_offer = n_plant / n_total,
    
    # Nachfrage-Anteil: wie viele der ausgegebenen Portionen entfallen auf pflanzliche Gerichte?
    output_total = sum(actual_output, na.rm = TRUE),
    output_plant = sum(actual_output[is_plant_based], na.rm = TRUE),
    share_demand = output_plant / output_total,
    .groups = "drop"
  ) |>
  # Wir behalten nur Studierendenwerke mit ausreichend vielen Daten für einen validen Vergleich.
  # Zu wenige Einträge würden die Anteile stark verzerren.
  filter(n_total > 1000) |>
  # Sortierung nach Nachfrage-Anteil, damit der Plot eine klare Struktur hat
  arrange(share_demand) |>
  mutate(student_service = factor(student_service, levels = student_service))

# Wir müssen die Daten fürs Plotting ins lange Format bringen,
# damit ggplot Angebot und Nachfrage als separate Punkte darstellen kann.
plot_data_long <- offer_demand_data |>
  pivot_longer(
    cols = c(share_offer, share_demand),
    names_to = "metric",
    values_to = "share"
  ) |>
  mutate(
    metric = factor(metric, levels = c("share_offer", "share_demand"), labels = c("Angebot", "Nachfrage"))
  )

# Visualisierung: Dumbbell Chart ------------------------------------------
# Die Strecke zwischen den zwei Punkten zeigt die Lücke zwischen Angebot und Nachfrage.
# Liegt der orange Punkt (Nachfrage) links vom blauen (Angebot), werden die pflanzlichen
# Gerichte unterdurchschnittlich nachgefragt.
plot_offer_demand <- ggplot(offer_demand_data) +
  geom_segment(
    aes(x = share_offer, xend = share_demand, y = student_service, yend = student_service),
    color = "grey70", linewidth = 1.5
  ) +
  geom_point(
    data = plot_data_long,
    aes(x = share, y = student_service, color = metric),
    size = 4
  ) +
  scale_x_continuous(labels = scales::percent) +
  scale_color_manual(
    values = c(
      "Angebot" = "#56B4E9",
      "Nachfrage" = "#D55E00"
    )
  ) +
  labs(
    title = "Angebot vs. Nachfrage nach pflanzlichen Gerichten",
    subtitle = "Anteil veganer/vegetarischer Gerichte am Angebot im Vergleich zu den tatsächlichen Verkäufen",
    x = "Prozentualer Anteil",
    y = "Studierendenwerk",
    color = "Metrik",
    caption = "Pflanzlich = Vegan + Vegetarisch"
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
  "communications/visualizations/07_offer_vs_demand.svg",
  plot_offer_demand,
  width = 9,
  height = 7
)
