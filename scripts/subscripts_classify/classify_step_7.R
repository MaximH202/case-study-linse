#Join und schreiben der Daten
# Ergebnisse mit dem ursprünglichen unique_dishes-Datensatz zusammenführen
llm_classified_short <- unique_dishes %>%
  distinct(product_name, .keep_all = TRUE) |> 
  select(-klassen, -menu_text) |> 
  right_join(llm_classified_short, by = "id") |>
  right_join(llm_classified_long |> select(id, hauptprotein), by = "id")

#Funktion aus llm_classified





# Ergebnisse als CSV-Dateien für die weitere Analyse speichern
write_csv(llm_classified_short, "data/menus_classified.csv")
write_csv(llm_classified_long, "data/menu_components.csv")

#Join mit der gesamten menus liste um alle Einträge zu bekommen
menus_short <- menus |> 
  inner_join(llm_classified_short, by = "product_name")