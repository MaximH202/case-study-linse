# 7. Angebot vs. Nachfrage (Beliebtheit) nach Studierendenwerk ---------------

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
    # Anteil am Angebot (Anzahl Zeilen)
    n_total = n(),
    n_plant = sum(is_plant_based),
    share_offer = n_plant / n_total,
    
    # Anteil an der Nachfrage (actual_output)
    output_total = sum(actual_output, na.rm = TRUE),
    output_plant = sum(actual_output[is_plant_based], na.rm = TRUE),
    share_demand = output_plant / output_total,
    .groups = "drop"
  ) |>
  # Wir behalten nur Studierendenwerke mit ausreichend vielen Daten für einen validen Vergleich
  filter(n_total > 1000) |>
  arrange(share_demand) |>
  mutate(student_service = factor(student_service, levels = student_service))

# Wir müssen die Daten fürs Plotting leicht ins lange Format bringen
plot_data_long <- offer_demand_data |>
  pivot_longer(
    cols = c(share_offer, share_demand),
    names_to = "metric",
    values_to = "share"
  ) |>
  mutate(
    metric = factor(metric, levels = c("share_offer", "share_demand"), labels = c("Angebot", "Nachfrage"))
  )

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
